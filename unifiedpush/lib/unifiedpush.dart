import 'dart:async';
import 'dart:io';
import 'package:unifiedpush_platform_interface/data/failed_reason.dart';
import 'package:unifiedpush_platform_interface/data/push_endpoint.dart';
import 'package:unifiedpush_platform_interface/data/push_message.dart';
import 'package:unifiedpush_platform_interface/unifiedpush_platform_interface.dart';
import 'package:unifiedpush_storage_interface/storage.dart';

import 'constants.dart';

export 'package:unifiedpush_platform_interface/data/failed_reason.dart';
export 'package:unifiedpush_platform_interface/data/push_endpoint.dart';
export 'package:unifiedpush_platform_interface/data/push_message.dart';

/// Class to interact with the UnifiedPush service and receive events
///
/// # Initialize the receiver
///
/// When you initialize your application, register the different functions
/// that will handle the incoming events with [UnifiedPush.initialize].
///
/// # Register for push messages
///
/// If a distributor is already saved (if [getDistributor] is not null), you
/// should [register] directly.
///
/// Else, use [getDistributors] to get the list of installed distributors,
/// and ask the users which one they would like to use. You can then save
/// their choice with [saveDistributor], and [register].
///
/// # Unregister
///
/// A registration can be canceled with [unregister]
///
/// # Embed a distributor
///
/// On Android, this is possible to embed a distributor that will register to
/// the Google play services directly. For more information refer to
/// <https://unifiedpush.org/kdoc/embedded_fcm_distributor/>
///
/// # Send push messages
///
/// You can then send web push messages to your applications. The messages need
/// to be encrypted. The required information them are retrieved onNewEndpoint:
/// [PushEndpoint.pubKeySet]
///
class UnifiedPush {
  /// Initialize the different event listener.
  ///
  /// Returns `Future<true>` if a distributor is already registered,
  /// `Future<false>` else;
  ///
  /// - [onNewEndpoint] Invoked when a new endpoint is to be used for sending push messages
  /// - [onRegistrationFailed] Invoked when the registration is not possible, eg. no network,
  ///   depending on the reason, you can try to register again directly.
  /// - [onUnregistered] Invoked when this registration is unregistered by the distributor and
  ///   won't receive push messages anymore
  /// - [onMessage] Invoked when a new message is received
  /// - [onTempUnavailable] Invoked when the distributor backend is temporary unavailable.
  /// - [storage] **Required for Linux**: UnifiedPushStorage
  /// - [linuxDBusName] **Required for Linux**: DBus name for the application, should be linked to your app, like `tld.yourdomain.YourApp.service`
  ///
  /// You can ignore instances if you don't use them.
  static Future<bool> initialize({
    void Function(PushEndpoint endpoint, String instance)? onNewEndpoint,
    void Function(FailedReason reason, String instance)? onRegistrationFailed,
    void Function(String instance)? onUnregistered,
    void Function(PushMessage message, String instance)? onMessage,
    void Function(String instance)? onTempUnavailable,
    UnifiedPushStorage? storage,
    String? linuxDBusName,
  }) async {
    if (Platform.isLinux) {
      // If no DBusName is set, we don't initialize UnifiedPush on Linux,
      // so project supporting Linux won't crash when they upgrade to a version
      // of flutter_connector with support for Linux by default
      if (linuxDBusName == null) return false;
      UnifiedPushPlatform.instance.setDBusName(linuxDBusName);
      UnifiedPushPlatform.instance.setStorage(storage);
    }
    await UnifiedPushPlatform.instance.initializeCallback(
        onNewEndpoint: (PushEndpoint e, String i) async =>
            onNewEndpoint?.call(e, i),
        onRegistrationFailed: (FailedReason r, String i) async =>
            onRegistrationFailed?.call(r, i),
        onUnregistered: (String i) async => onUnregistered?.call(i),
        onMessage: (PushMessage m, String i) async => onMessage?.call(m, i));
    await UnifiedPushPlatform.instance.initializeOnTempUnavailable(
        (String i) async => onTempUnavailable?.call(i));
    return await UnifiedPush.getDistributor() != null;
  }

  /// Register the app to the saved distributor with a specified token
  /// identified with the instance parameter
  /// This method needs to be called at every app startup with the same
  /// distributor and token.
  static Future<void> register({
    String instance = defaultInstance,
    List<String>? features = const [],
    String? messageForDistributor,
    String? vapid,
  }) async {
    await UnifiedPushPlatform.instance.register(
      instance,
      features ?? [],
      messageForDistributor,
      vapid,
    );
  }

  @Deprecated("Renamed [register]")
  static Future<void> registerApp(
      [String instance = defaultInstance,
      List<String>? features = const []]) async {
    await register(instance: instance, features: features);
  }

  /// Try to use the saved distributor else, use the default distributor
  /// of the system
  ///
  /// Returns `Future<true>` if we can register to the current or default
  /// distributor, else you should ask what the users want to use. The list
  /// of installed services can be found with [getDistributors]
  static Future<bool> tryUseCurrentOrDefaultDistributor() async {
    return await UnifiedPushPlatform.instance
        .tryUseCurrentOrDefaultDistributor();
  }

  /// Send an unregistration request for the instance to the saved distributor
  /// and remove the registration. Remove the distributor if this is the last
  /// instance registered.
  static Future<void> unregister([String instance = defaultInstance]) async {
    await UnifiedPushPlatform.instance.unregister(instance);
  }

  /// Returns the qualified identifier of all available distributors on the system.
  static Future<List<String>> getDistributors(
      [List<String>? features = const []]) async {
    return await UnifiedPushPlatform.instance.getDistributors(features ?? []);
  }

  /// Returns the qualified identifier of the distributor used.
  static Future<String?> getDistributor() async {
    return await UnifiedPushPlatform.instance.getDistributor();
  }

  /// Save the distributor to be used.
  static Future<void> saveDistributor(String distributor) async {
    await UnifiedPushPlatform.instance.saveDistributor(distributor);
  }
}
