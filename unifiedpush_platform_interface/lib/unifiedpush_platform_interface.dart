import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:unifiedpush_platform_interface/data/failed_reason.dart';
import 'package:unifiedpush_platform_interface/data/push_endpoint.dart';
import 'package:unifiedpush_platform_interface/data/push_message.dart';
import 'package:unifiedpush_storage_interface/storage.dart';

class LinuxOptions {
  final String dbusName;
  final UnifiedPushStorage storage;
  final bool background;
  LinuxOptions(
      {required this.dbusName,
      required this.storage,
      required this.background});
}

/// The interface that implementations of unifiedpush must implement.
abstract class UnifiedPushPlatform extends PlatformInterface {
  UnifiedPushPlatform() : super(token: _token);

  static final Object _token = Object();
  static UnifiedPushPlatform _instance = DefaultUnifiedPush();
  static UnifiedPushPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [UnifiedPushPlatform] when they register themselves.
  static set instance(UnifiedPushPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the qualified identifier of all available distributors on the system.
  Future<List<String>> getDistributors(List<String> features);

  /// Returns the qualified identifier of the distributor used.
  Future<String?> getDistributor();

  /// Save the distributor to be used.
  Future<void> saveDistributor(String distributor);

  /// Register the app to the saved distributor with a specified token
  /// identified with the instance parameter
  /// This method needs to be called at every app startup with the same
  /// distributor and token.
  Future<void> register(String instance, List<String> features,
      String? messageForDistributor, String? vapid);

  /// Try to use the saved distributor else, use the default distributor
  /// of the system
  Future<bool> tryUseCurrentOrDefaultDistributor();

  /// Send an unregistration request for the instance to the saved distributor
  /// and remove the registration. Remove the distributor if this is the last
  /// instance registered.
  Future<void> unregister(String instance);

  /// Register callbacks to receive the push messages and other infos.
  /// Please see the spec for more infos on those callbacks and their
  /// parameters.
  /// This needs to be called BEFORE registerApp so onNewEndpoint get called
  /// and you get the info in your app, or this will be lost.
  Future<void> initializeCallback({
    void Function(PushEndpoint endpoint, String instance)? onNewEndpoint,
    void Function(FailedReason reason, String instance)? onRegistrationFailed,
    void Function(String instance)? onUnregistered,
    void Function(PushMessage message, String instance)? onMessage,
  });

  /// Register optional callback for onTempUnavailable
  /// This event is sent by the distributor if the push server is down
  Future<void> initializeOnTempUnavailable(
    void Function(String instance)? onTempUnavailable,
  );

  /// Set different options as the DBusName, the storage, or if it is in the
  /// background.
  /// Required on Linux
  void setLinuxOptions(LinuxOptions options);
}

class DefaultUnifiedPush extends UnifiedPushPlatform {
  @override
  Future<String?> getDistributor() {
    throw UnimplementedError("getDistributor has not been implemented");
  }

  @override
  Future<List<String>> getDistributors(List<String> features) {
    throw UnimplementedError("getDistributors has not been implemented");
  }

  @override
  Future<void> initializeCallback(
      {void Function(PushEndpoint endpoint, String instance)? onNewEndpoint,
      void Function(FailedReason reason, String instance)? onRegistrationFailed,
      void Function(String instance)? onUnregistered,
      void Function(PushMessage message, String instance)? onMessage}) {
    throw UnimplementedError("initializeCallback has not been implemented");
  }

  @override
  Future<void> initializeOnTempUnavailable(
      void Function(String instance)? onTempUnavailable) {
    throw UnimplementedError(
        "initializeOnTempUnavailable has not been implemented");
  }

  @override
  Future<void> register(String instance, List<String> features,
      String? messageForDistributor, String? vapid) {
    throw UnimplementedError("register has not been implemented");
  }

  @override
  Future<void> saveDistributor(String distributor) {
    throw UnimplementedError("saveDistributor has not been implemented");
  }

  @override
  void setLinuxOptions(LinuxOptions options) {}

  @override
  Future<bool> tryUseCurrentOrDefaultDistributor() {
    throw UnimplementedError("setLinuxOptions has not been implemented");
  }

  @override
  Future<void> unregister(String instance) {
    throw UnimplementedError(
        "tryUseCurrentOrDefaultDistributor has not been implemented");
  }
}
