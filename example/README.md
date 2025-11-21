# flutter-example

Demonstrates how to use the unifiedpush flutter-connector plugin for Flutter.

## Getting Started

1. You first need to install a [distributor](https://unifiedpush.org/users/distributors/)
2. Then click on _Register_
3. Then click on _Notify_

## Sending message with DBus

In order to simulate incoming message from a distributor, it is possible to send a dbus call directly:

```console
$ gdbus call --session --dest=org.unifiedpush.Example \
   --object-path=/org/unifiedpush/Connector \
   --method=org.unifiedpush.Connector2.Message \
   "{'token':<'$(jq -r '."unifiedpush.token_for.myInstance"' < ~/share/org.unifiedpush.flutter.unifiedpush_example/shared_preferences.json)'>,'message':<@ay [0x41,0x41,0x41,0x41]>}"
```
