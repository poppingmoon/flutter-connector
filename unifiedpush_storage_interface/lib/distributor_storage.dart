import 'dart:async';

abstract class DistributorStorage {
  FutureOr<String?> get();
  FutureOr<void> set(String distributor);
  FutureOr<void> ack();
  FutureOr<void> remove();
}