import 'dart:async';

abstract class KeysStorage {
  /// Returns Serialized key
  FutureOr<String?> get(String instance);
  /// The serializedKey is sensitive, and may be stored encrypted.
  FutureOr<void> set(String instance, String serializedKey);
  FutureOr<void> remove(String instance);
}