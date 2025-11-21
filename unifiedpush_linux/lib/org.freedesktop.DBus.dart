import 'package:dbus/dbus.dart';

class OrgFreedesktopDBus extends DBusRemoteObject {
  OrgFreedesktopDBus(super.client) : super(
    name: "org.freedesktop.DBus",
    path: DBusObjectPath('/org/freedesktop/DBus'),
  );

  /// Invokes org.freedesktop.DBus.ReloadConfig()
  Future<void> reloadConfig() async {
    await callMethod(
      'org.freedesktop.DBus',
      'ReloadConfig',
      []
    );
  }
}
