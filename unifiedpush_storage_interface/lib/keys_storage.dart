import 'dart:async';

/// Storage for encryption keys
///
/// There must be a different key per registration. The registrations
/// are identified with the instance.
abstract class KeysStorage {
  /// Return the Serialized key for the instance
  FutureOr<String?> get(String instance);
  /// Store the serializedKey for the instance
  ///
  /// **The serializedKey is sensitive, and may be stored encrypted.**
  FutureOr<void> set(String instance, String serializedKey);
  /// Remove the keys for the instance
  FutureOr<void> remove(String instance);
}
