import 'package:unifiedpush_linux/org.unifiedpush.Connector2.dart';

import 'package:dbus/dbus.dart';
import 'package:unifiedpush_linux/org.unifiedpush.Distributor2.dart';
import 'package:unifiedpush_platform_interface/data/failed_reason.dart';
import 'package:unifiedpush_platform_interface/data/push_endpoint.dart';
import 'package:unifiedpush_platform_interface/data/push_message.dart';
import 'package:unifiedpush_platform_interface/unifiedpush_platform_interface.dart';
import 'package:unifiedpush_storage_interface/registrations_storage.dart';
import 'package:unifiedpush_storage_interface/storage.dart';
import 'package:uuid/v4.dart';

enum RegistrationFailure {
  internalError("INTERNAL_ERROR"),
  network("NETWORK"),
  actionRequired("ACTION_REQUIRED"),
  vapidRequired("VAPID_REQUIRED"),
  unauthorized("UNAUTHORIZED");

  final String value;
  const RegistrationFailure(this.value);

  FailedReason toFailedReason() {
    switch (this) {
      case network:
        return FailedReason.network;
      case actionRequired:
      case unauthorized:
        return FailedReason.actionRequired;
      case vapidRequired:
        return FailedReason.vapidRequired;
      default:
        return FailedReason.internalError;
    }
  }
}

class UnifiedPushRegistrationFailed implements Exception {
  final RegistrationFailure reason;

  const UnifiedPushRegistrationFailed({required this.reason});
}

class UnifiedPushLinux extends UnifiedPushPlatform {
  final DBusClient _dbusClient = DBusClient.session();

  OrgUnifiedpushDistributor2? _distributor;
  OrgUnifiedpushConnector2? _connector;
  String? _dbusName;
  UnifiedPushStorage? _storage;
  void Function(FailedReason reason, String instance)? onRegistrationFailed;

  static void registerWith() {
    UnifiedPushPlatform.instance = UnifiedPushLinux();
  }

  @override
  Future<List<String>> getDistributors(List<String> features) async {
    return (await _dbusClient.listNames())
        .where((element) => element.startsWith("org.unifiedpush.Distributor"))
        .toList();
  }

  @override
  Future<String?> getDistributor() async {
    return await _getStorage("getDistributor").distrib.get();
  }

  @override
  Future<void> saveDistributor(String distributor) async {
    _setDistributor(distributor);
    await _getStorage("saveDistributor").distrib.set(distributor);
  }

  @override
  Future<void> register(
    String instance,
    List<String> features,
    String? messageForDistributor,
    String? vapid,
  ) async {
    var storage = _getStorage("register");

    var token = (await storage.registrations.getFromInstance(instance))?.token;
    if (token == null) {
      token = const UuidV4().generate();
      await storage.registrations.save(TokenInstance(token, instance));
    }
    var result = await _distributor?.callRegister(
      {
        "service": DBusString(_getDBusName()),
        "token": DBusString(token),
        if (messageForDistributor != null) ...{
          "description": DBusString(messageForDistributor),
        },
        if (vapid != null) ...{
          "vapid": DBusString(vapid),
        }
      },
    );

    var succeeded = result?["success"]?.asString() == "REGISTRATION_SUCCEEDED";

    if (!succeeded) {
      final reason = RegistrationFailure.values.firstWhere(
              (possibleReason) =>
          possibleReason.value == result?["reason"]?.asString(),
          orElse: () => RegistrationFailure.internalError
      ).toFailedReason();
      onRegistrationFailed?.call(reason, instance);
    }
  }

  @override
  Future<bool> tryUseCurrentOrDefaultDistributor() async {
    final current = await getDistributor();
    if (current != null) return true;
    final available = await getDistributors([]);
    if (available.length == 1) {
      saveDistributor(available.first);
      return true;
    }
    return false;
  }

  @override
  Future<void> unregister(String instance) async {
    if (_distributor == null || _connector == null) return;

    var storage = _getStorage("unregister");
    var token = (await storage.registrations.getFromInstance(instance))?.token;
    if (token == null) return;
    final regLeft = await storage.registrations.remove(instance);
    await _distributor!.callUnregister({
      "token": DBusString(token),
    });

    if (!regLeft) {
      await storage.distrib.remove();
      await _delDistributor();
    }
  }

  @override
  Future<void> initializeCallback({
    void Function(PushEndpoint endpoint, String instance)? onNewEndpoint,
    void Function(FailedReason reason, String instance)? onRegistrationFailed,
    void Function(String instance)? onUnregistered,
    void Function(PushMessage message, String instance)? onMessage,
  }) async {
    final storage = _getStorage("initializeCallback");
    final connector = _connector ??= OrgUnifiedpushConnector2(storage);
    final distrib = await storage.distrib.get();
    if (distrib != null) {
      _setDistributor(distrib);
    }
    return connector.initializeCallback(
      onNewEndpoint: onNewEndpoint,
      onUnregistered: onUnregistered,
      onMessage: onMessage
    );
  }

  @override
  void setDBusName(String? name) {
    assert(name != null, "The DBus name should be set");
    assert(name!.split(".").length >= 3,
        "The DBus name should be a fully-qualified name (e.g. com.example.App)");
    _dbusName = name;
  }

  String _getDBusName() {
    var dbusName = _dbusName;
    assert(dbusName != null,
    "setDBusName must be called before initialization");
    return dbusName!;
  }

  @override
  void setStorage(UnifiedPushStorage? storage) {
    assert(storage != null, "Storage must be set");
    _storage = storage!;
  }

  _setDistributor(String distrib) async {
    var connector = _connector;
    assert(connector != null, "Initialization hasn't been called");
    _distributor = OrgUnifiedpushDistributor2(_dbusClient, distrib);
    if (connector!.client == null) {
      await _dbusClient.registerObject(connector);
      await _dbusClient.requestName(_getDBusName());
    }
  }

  _delDistributor() async {
    var connector = _connector;
    assert(connector != null, "Initialization hasn't been called");
    await _dbusClient.unregisterObject(connector!);
    await _dbusClient.releaseName(_getDBusName());
    connector.client = null;
    _distributor = null;

  }

  UnifiedPushStorage _getStorage(String function) {
    var storage = _storage;
    assert(storage != null, "Storage must be set before calling $function");
    return storage!;
  }
}
