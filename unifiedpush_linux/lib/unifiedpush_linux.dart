import 'package:unifiedpush_linux/org.unifiedpush.Connector1.dart';
import 'package:unifiedpush_linux/org.unifiedpush.Distributor1.dart';

import 'package:dbus/dbus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unifiedpush_platform_interface/data/failed_reason.dart';
import 'package:unifiedpush_platform_interface/data/push_endpoint.dart';
import 'package:unifiedpush_platform_interface/data/push_message.dart';
import 'package:unifiedpush_platform_interface/unifiedpush_platform_interface.dart';
import 'package:uuid/v4.dart';

class UnifiedPushRegistrationFailed implements Exception {}

class UnifiedpushLinux extends UnifiedPushPlatform {
  final DBusClient _dbusClient;
  OrgUnifiedpushDistributor1? _distributor;
  OrgUnifiedpushConnector1? _connector;
  String? _instance;
  String? _dbusName;

  UnifiedpushLinux() : _dbusClient = DBusClient.session();

  static void registerWith() {
    UnifiedPushPlatform.instance = UnifiedpushLinux();
  }

  @override
  Future<List<String>> getDistributors(List<String> features) async {
    return (await _dbusClient.listNames())
        .where((element) => element.startsWith("org.unifiedpush.Distributor"))
        .toList();
  }

  @override
  Future<String?> getDistributor() async {
    var sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString("selected_distributor");
  }

  @override
  Future<void> saveDistributor(String distributor) async {
    var sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("selected_distributor", distributor);
  }

  @override
  Future<void> register(
    String instance,
    List<String> features,
    String? messageForDistributor,
    String? vapid,
  ) async {
    assert(_dbusName != null, "The DBus name should be set");

    var distributor = await getDistributor();
    if (distributor == null || _connector == null) return;

    var sharedPreferences = await SharedPreferences.getInstance();
    var token = sharedPreferences.getString("instance_${instance}_token");
    if (token == null) {
      token = const UuidV4().generate();
      sharedPreferences.setString("instance_${instance}_token", token);
    }

    _instance = instance;

    _distributor = OrgUnifiedpushDistributor1(
      _dbusClient,
      distributor,
      DBusObjectPath('/org/unifiedpush/Distributor'),
    );

    // We need a fully-qualified name (e.g. com.example.App)
    await _dbusClient.requestName(_dbusName!);
    if (_connector!.client == null) {
      await _dbusClient.registerObject(_connector!);
    }

    var result = await _distributor!.callRegister(
      instance,
      token,
      _dbusName!,
    );

    var succeeded = result[0].asString() == "REGISTRATION_SUCCEEDED";

    if (!succeeded) {
      throw UnifiedPushRegistrationFailed();
    }
  }

  @override
  Future<bool> tryUseCurrentOrDefaultDistributor() async {
    return (await getDistributor()) != null;
  }

  @override
  Future<void> unregister(String instance) async {
    if (_distributor == null || _connector == null) return;

    var sharedPreferences = await SharedPreferences.getInstance();
    var token = sharedPreferences.getString("instance_${instance}_token");
    assert(token != null, "You need to call register before unregistering");

    await _distributor!.callUnregister(token!);
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
    _connector ??= OrgUnifiedpushConnector1();

    return _connector!.initializeCallback(
      onNewEndpoint: (endpoint) => onNewEndpoint?.call(endpoint, _instance!),
      onRegistrationFailed: (reason) =>
          onRegistrationFailed?.call(reason, _instance!),
      onUnregistered: (token) => onUnregistered?.call(_instance!),
      onMessage: (message) => onMessage?.call(message, _instance!),
    );
  }

  @override
  void setDBusName(String name) {
    _dbusName = name;
  }
}
