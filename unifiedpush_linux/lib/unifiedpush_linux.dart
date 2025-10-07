import 'package:unifiedpush_linux/org.unifiedpush.Connector2.dart';

import 'package:dbus/dbus.dart';
import 'package:unifiedpush_linux/org.unifiedpush.Distributor2.dart';
import 'package:unifiedpush_platform_interface/data/failed_reason.dart';
import 'package:unifiedpush_platform_interface/data/push_endpoint.dart';
import 'package:unifiedpush_platform_interface/data/push_message.dart';
import 'package:unifiedpush_platform_interface/unifiedpush_platform_interface.dart';
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
}

class UnifiedPushRegistrationFailed implements Exception {
  final RegistrationFailure reason;

  const UnifiedPushRegistrationFailed({required this.reason});
}

class UnifiedPushLinux extends UnifiedPushPlatform {
  final DBusClient _dbusClient;
  OrgUnifiedpushDistributor2? _distributor;
  OrgUnifiedpushConnector2? _connector;
  String? _instance;
  String? _dbusName;
  UnifiedPushStorage? _storage;

  UnifiedPushLinux() : _dbusClient = DBusClient.session();

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
    return await _getStorage("getDistributor")
        .getString("selected_distributor");
  }

  @override
  Future<void> saveDistributor(String distributor) async {
    await _getStorage("saveDistributor")
        .setString("selected_distributor", distributor);
  }

  @override
  Future<void> register(
    String instance,
    List<String> features,
    String? messageForDistributor,
    String? vapid,
  ) async {
    var dbusName = _dbusName;
    assert(dbusName != null,
        "DBus name not set, setDBusName must be called before register");

    var storage = _getStorage("register");
    var distributor = await getDistributor();
    if (distributor == null || _connector == null) return;

    var token = await storage.getString("instance_${instance}_token");
    if (token == null) {
      token = const UuidV4().generate();
      await storage.setString("instance_${instance}_token", token);
    }

    _instance = instance;

    _distributor = OrgUnifiedpushDistributor2(
      _dbusClient,
      distributor,
      DBusObjectPath('/org/unifiedpush/Distributor'),
    );

    await _dbusClient.requestName(dbusName!);
    if (_connector!.client == null) {
      await _dbusClient.registerObject(_connector!);
    }

    var result = await _distributor!.callRegister(
      {
        "service": DBusString(dbusName!),
        "token": DBusString(token),
        if (messageForDistributor != null) ...{
          "description": DBusString(messageForDistributor),
        },
        if (vapid != null) ...{
          "vapid": DBusString(vapid),
        }
      },
    );

    var succeeded = result["success"]!.asString() == "REGISTRATION_SUCCEEDED";

    if (!succeeded) {
      throw UnifiedPushRegistrationFailed(
          reason: RegistrationFailure.values.firstWhere(
        (possibleReason) =>
            possibleReason.value == result["reason"]!.asString(),
      ));
    }
  }

  @override
  Future<bool> tryUseCurrentOrDefaultDistributor() async {
    return (await getDistributor()) != null;
  }

  @override
  Future<void> unregister(String instance) async {
    if (_distributor == null || _connector == null) return;

    var storage = _getStorage("unregister");
    var token = await storage.getString("instance_${instance}_token");
    assert(token != null, "You need to call register before unregistering");

    await _distributor!.callUnregister({
      "token": DBusString(token!),
    });
    await _dbusClient.unregisterObject(_connector!);
    _connector!.client = null;
    _instance = null;
  }

  @override
  Future<void> initializeCallback({
    void Function(PushEndpoint endpoint, String instance)? onNewEndpoint,
    void Function(FailedReason reason, String instance)? onRegistrationFailed,
    void Function(String instance)? onUnregistered,
    void Function(PushMessage message, String instance)? onMessage,
  }) async {
    _connector ??= OrgUnifiedpushConnector2();

    return _connector!.initializeCallback(
      onNewEndpoint: (endpoint) => onNewEndpoint?.call(endpoint, _instance!),
      onRegistrationFailed: (reason) =>
          onRegistrationFailed?.call(reason, _instance!),
      onUnregistered: (token) => onUnregistered?.call(_instance!),
      onMessage: (message) => onMessage?.call(message, _instance!),
    );
  }

  @override
  void setDBusName(String? name) {
    assert(name != null, "The DBus name should be set");
    assert(name!.split(".").length >= 3,
        "The DBus name should be a fully-qualified name (e.g. com.example.App)");
    _dbusName = name;
  }

  @override
  void setStorage(UnifiedPushStorage? storage) {
    assert(storage != null, "Storage must be set");
    _storage = storage!;
  }

  UnifiedPushStorage _getStorage(String function) {
    var storage = _storage;
    assert(storage != null, "Storage must be set before calling $function");
    return storage!;
  }
}
