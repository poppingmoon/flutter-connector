import 'dart:async';
import 'dart:core';

import 'distributor_storage.dart';
import 'registrations_storage.dart';
import 'keys_storage.dart';

/// Storage interface that must be passed for Linux
abstract class UnifiedPushStorage {
  FutureOr<void> init();
  /// Storage for registrations related data
  RegistrationsStorage get registrations;
  /// Storage for distributor related data
  DistributorStorage get distrib;
  /// Storage for encryption keys
  KeysStorage get keys;
}
