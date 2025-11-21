import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:unifiedpush_storage_interface/distributor_storage.dart';
import 'package:unifiedpush_storage_interface/keys_storage.dart';
import 'package:unifiedpush_storage_interface/registrations_storage.dart';
import 'package:unifiedpush_storage_interface/storage.dart';

class UnifiedPushStorageSharedPreferences extends UnifiedPushStorage {
  @override
  FutureOr<void> init() async {
    // Nothing to do
  }

  @override
  DistributorStorage get distrib => DistributorStorageSharedPrefs();

  @override
  KeysStorage get keys => KeysStorageSharedPrefs();

  @override
  RegistrationsStorage get registrations => RegistrationsStorageSharedPrefs();
}

class DistributorStorageSharedPrefs extends DistributorStorage {
  static const String _ACK = "unifiedpush.distributor.ack";
  static const String _NAME = "unifiedpush.distributor.name";

  @override
  FutureOr<void> ack() {
    return SharedPreferencesAsync().setBool(_ACK, true);
  }

  @override
  FutureOr<String?> get() {
    return SharedPreferencesAsync().getString(_NAME);
  }

  @override
  FutureOr<void> remove() async {
    await SharedPreferencesAsync().remove(_ACK);
    return SharedPreferencesAsync().remove(_NAME);
  }

  @override
  FutureOr<void> set(String distributor) async {
    final current = get();
    if (current != distributor) {
      await SharedPreferencesAsync().remove(_ACK);
    }
    return SharedPreferencesAsync().setString(_NAME, distributor);
  }
}

class KeysStorageSharedPrefs extends KeysStorage {
  static const String _KEY = "unifiedpush.key";
  @override
  FutureOr<String?> get(String instance) {
    return SharedPreferencesAsync().getString("$_KEY.$instance");
  }

  @override
  FutureOr<void> remove(String instance) {
    return SharedPreferencesAsync().remove("$_KEY.$instance");
  }

  @override
  FutureOr<void> set(String instance, String serializedKey) {
    return SharedPreferencesAsync().setString("$_KEY.$instance", serializedKey);
  }
}

class RegistrationsStorageSharedPrefs extends RegistrationsStorage {
  /// To get instance from token
  static const String _INSTANCE_FOR = "unifiedpush.instance_for";
  /// To get token from instance
  static const String _TOKEN_FOR = "unifiedpush.token_for";

  @override
  FutureOr<TokenInstance?> getFromInstance(String instance) async {
    final token = await SharedPreferencesAsync().getString("$_TOKEN_FOR.$instance");
    if (token == null) return null;
    return TokenInstance(token, instance);
  }

  @override
  FutureOr<TokenInstance?> getFromToken(String token) async {
    final instance = await SharedPreferencesAsync().getString("$_INSTANCE_FOR.$token");
    if (instance == null) return null;
    return TokenInstance(token, instance);
  }

  @override
  FutureOr<bool> remove(String instance) async {
    final token = await SharedPreferencesAsync().getString("$_TOKEN_FOR.$instance");
    if (token != null) {
      await SharedPreferencesAsync().remove("$_INSTANCE_FOR.$token");
    }
    await SharedPreferencesAsync().remove("$_TOKEN_FOR.$instance");
    return (await SharedPreferencesAsync().getKeys())
        .any((it) => it.startsWith(_INSTANCE_FOR));
  }

  @override
  FutureOr<void> removeAll() async {
    (await SharedPreferencesAsync().getKeys())
        .forEach((key) async {
          if (key.startsWith(_INSTANCE_FOR) || key.startsWith(_TOKEN_FOR)) {
            await SharedPreferencesAsync().remove(key);
          }
        }
    );
  }

  @override
  FutureOr<void> save(TokenInstance token) async {
    await SharedPreferencesAsync().setString("$_INSTANCE_FOR.${token.token}", token.instance);
    return SharedPreferencesAsync().setString("$_TOKEN_FOR.${token.instance}", token.token);
  }
}