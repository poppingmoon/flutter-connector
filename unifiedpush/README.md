# UnifiedPush library

Library to subscribe and receive push notifications with UnifiedPush.

To receive notifications with UnifiedPush, users must have a dedicated application, a distributor, installed on their system.

## Entrypoint

You don't necessarily need to run the full application when your application starts from the background.
For this, when the application starts from the background, an argument (`--unifiedpush-bg`) is passed to the dart executor.
When the user starts the application manually afterward, the application starts normally.

```dart
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // YourUnifiedPushFeature refers to an internal class you have implemented
  YourUnifiedPushFeature().init(args);

  if (!args.contains("--unifiedpush-bg")) {
    runApp(const MyApp());
  }
}
```

## Initialize the receiver

When you initialize your application, register the different functions that will handle the incoming events with [UnifiedPush.initialize]:

```dart
void init(List<String>args) {
  // Only if you support Linux:
  final linuxOptions = LinuxOptions(
    dbusName: dbusName,
    storage: storage,
    background: args.contains("--unifiedpush-bg")
  );
  UnifiedPush.initialize(
    onNewEndpoint: onNewEndpoint,
    onRegistrationFailed: onRegistrationFailed,
    onUnregistered: onUnregistered,
    onMessage: onMessage,
    onTempUnavailable: onTempUnavailable,
    linuxOptions: linuxOptions,
  ).then((registered) => { if (registered) UnifiedPush.register(instance) });
}

void onNewEndpoint(PushEndpoint endpoint, String instance) {
  // You should send the endpoint to your application server
}

void onRegistrationFailed(FailedReason reason, String instance) {}

void onUnregistered(String instance) {}

void onTempUnavailable(String instance) {}

void onMessage(PushMessage message, String instance) {}
```

If your app supports Linux, pass a `LinuxOptions` argument. It contains the application DBus name, the storage implementing [UnifiedPushStorage](https://pub.dev/packages/unifiedpush_storage_interface), like [UnifiedPushStorageSharedPreferences](https://pub.dev/packages/unifiedpush_android/unifiedpush_storage_shared_preferences), and wether the application starts in the background (`args.contains("--unifiedpush-db")`).

## Register for push messages

When you try to register for the first time, you will probably want to use the user default distributor:

```dart
UnifiedPush.tryUseCurrentOrDefaultDistributor().then((success) {
  debugPrint("Current or Default found=$success");
  if (success) {
    UnifiedPush.registerApp(
        instance,                        // Optionnal String, to get multiple endpoints (one per instance)
        vapid: vapid                    // Optionnal String with the server public VAPID key
    );
  } else {
    getUserChoice();                     // You UI function to has the distributor to use
  }
});
```

If using the current distrbutor doesn't succeed, or when you want to let the user chose a non-default distrbutor, you can implement your own logic:

```dart
void getUserChoice() async {
  // Get a list of distributors that are available
  final distributors = await UnifiedPush.getDistributors();
  // select one or show a dialog or whatever
  final distributor = myPickerFunc(distributors);
  // save the distributor
  UnifiedPush.saveDistributor(distributor);
  // register your app to the distributor
  UnifiedPush.registerApp(
      instance,                        // Optionnal String, to get multiple endpoints (one per instance)
      vapid: vapid                    // Optionnal String with the server public VAPID key
  );
}
```

If you want, [unifiedpush_ui](https://pub.dev/packages/unifiedpush_ui) provides a dialog to pick the user choice.

## Unregister

A registration can be canceled with `UnifiedPush.unregister`.

## Background reception on Linux

On linux, when the plugin is initialized with `background=true`:
- the plugin connects to the session DBUS and closes itself as soon as a new application register for the DBus name. That way when the user starts the application to get the user interface, and this instance can take over.
- the plugin hide the window as soon as possible, but it is possible that a window pop up shortly with the first push notification.

#### How to avoid short window pop up

To avoid getting that window pop up with the first push notification, it is possible to edit the application code for the linux platform that way:

1. Open `linux/runner/my_application.cc`
2. Add `#include <cstdlib>` at the top of the file
3. Find out `gtk_widget_show(GTK_WIDGET(window));` to add a line right after:

```cpp
  gtk_widget_show(GTK_WIDGET(window));
  if (std::getenv("FLUTTER_HEADLESS")) gtk_widget_hide(GTK_WIDGET(window));
```

## Embed a distributor

On Android, this is possible to embed a distributor that will register to the Google play services directly. You will need to update the Android side of your flutter project. For more information refer to <https://unifiedpush.org/kdoc/embedded_fcm_distributor/>.

## Send push messages

Push messages are usually sent from the server using a Web Push library.

Web Push is defined by 3 RFC: [RFC8030](https://www.rfc-editor.org/rfc/rfc8030) defines the content of the http request used to push a message, [RFC8291](https://www.rfc-editor.org/rfc/rfc8291) defines the (required) encryption of the push messages, and [RFC8292](https://www.rfc-editor.org/rfc/rfc8292) defines the authorization used to control the sender of push messages, this authoization is known as VAPID and is optional with most distributors, required by others.

When the application receives a new endpoint, it comes with information used by the server to encrypt notifications too: [PushEndpoint.pubKeySet].

The application automatically decrypt incoming notifications. When onNewMessage is called, [PushMessage.content] contains the decrypted content of the push notification. If it wasn't possible to correctly decrypt it, [PushMessage.decrypted] is false, and [PushMessage.content] contains the encrypted content of push notifications.

## Example

An example app can be found on the [repository](https://codeberg.org/UnifiedPush/flutter-connector/src/branch/main/example).

## Troubleshooting

### The build fails because of duplicate classes

An error is thrown during build about duplicate classes, _related to tink_:

```
> A failure occurred while executing com.android.build.gradle.internal.tasks.CheckDuplicatesRunnable
   > Duplicate class com.google.crypto.tink.AccessesPartialKey found in modules tink-1.16.0.jar -> jetified-tink-1.16.0 (com.google.crypto.tink:tink:1.16.0) and tink-android-1.9.0.jar -> jetified-tink-android-1.9.0 (com.google.crypto.tink:tink-android:1.9.0)
     Duplicate class com.google.crypto.tink.Aead found in modules tink-1.16.0.jar -> jetified-tink-1.16.0 (com.google.crypto.tink:tink:1.16.0) and tink-android-1.9.0.jar -> jetified-tink-android-1.9.0 (com.google.crypto.tink:tink-android:1.9.0)
     Duplicate class com.google.crypto.tink.BinaryKeysetReader found in modules tink-1.16.0.jar -> jetified-tink-1.16.0 (com.google.crypto.tink:tink:1.16.0) and tink-android-1.9.0.jar -> jetified-tink-android-1.9.0 (com.google.crypto.tink:tink-android:1.9.0)
    [...]
```

This is due to another library using another version of _tink_.

To resolve the issue, edit _android/app/build.gradle.kts_, and add, after the `plugins` section:

```kotlin
configurations.all {
    // Use the latest version published: https://central.sonatype.com/artifact/com.google.crypto.tink/tink-android
    val tink = "com.google.crypto.tink:tink-android:1.17.0"
    // You can also use the library declaration catalog
    // val tink = libs.google.tink
    resolutionStrategy {
        force(tink)
        dependencySubstitution {
            substitute(module("com.google.crypto.tink:tink")).using(module(tink))
        }
    }
}

```
