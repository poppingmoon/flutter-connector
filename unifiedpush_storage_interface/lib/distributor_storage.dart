import 'dart:async';

/// Storage for distributor related data
abstract class DistributorStorage {
  /// Get the current distributor
  FutureOr<String?> get();
  /// Store a new distributor
  FutureOr<void> set(String distributor);
  /// Update the stored distributor, called when we received an endpoint for the first time
  FutureOr<void> ack();
  /// Remove the distributor
  FutureOr<void> remove();
}
