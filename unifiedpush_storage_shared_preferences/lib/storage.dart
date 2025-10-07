import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:unifiedpush_storage_interface/storage.dart';

class UnifiedPushStorageSharedPreferences extends UnifiedPushStorage {
  FutureOr<SharedPreferences> _prefs() async {
    return await SharedPreferences.getInstance();
  }

  @override
  FutureOr<void> init() async {
    // Nothing to do
  }

  @override
  FutureOr<void> setString(String key, String value) async {
    (await _prefs()).setString(key, value);
  }

  @override
  FutureOr<String?> getString(String key) async {
    return (await _prefs()).getString(key);
  }

  @override
  FutureOr<void> setSecret(String key, String value) {
    return setString(key, value);
  }

  @override
  FutureOr<String?> getSecret(String key) {
    return getString(key);
  }

  @override
  FutureOr<void> setBool(String key, bool value) async {
    (await _prefs()).setBool(key, value);
  }

  @override
  FutureOr<bool?> getBool(String key) async {
    return (await _prefs()).getBool(key);
  }

  @override
  FutureOr<void> remove(String key) async {
    (await _prefs()).remove(key);
  }
}
