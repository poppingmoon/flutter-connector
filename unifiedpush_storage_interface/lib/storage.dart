import 'dart:async';
import 'dart:core';

abstract class UnifiedPushStorage {
  FutureOr<void> init() {
    throw UnimplementedError("init has not been implemented");
  }

  FutureOr<void> setString(String key, String value) {
    throw UnimplementedError("saveString has not been implemented.");
  }

  FutureOr<String?> getString(String key) {
    throw UnimplementedError("getString has not been implemented.");
  }

  /// Set sensitive string, maybe stored encrypted
  FutureOr<void> setSecret(String key, String value) {
    throw UnimplementedError("saveString has not been implemented.");
  }

  /// Get sensitive string
  FutureOr<String?> getSecret(String key) {
    throw UnimplementedError("getString has not been implemented.");
  }

  FutureOr<void> setBool(String key, bool value) {
    throw UnimplementedError("saveBool has not been implemented.");
  }

  FutureOr<bool?> getBool(String key) {
    throw UnimplementedError("getBool has not been implemented.");
  }

  FutureOr<void> remove(String key) {
    throw UnimplementedError("remove has not been implemented.");
  }
}
