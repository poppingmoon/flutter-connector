import 'dart:async';
import 'dart:core';

import 'distributor_storage.dart';
import 'registrations_storage.dart';
import 'keys_storage.dart';

abstract class UnifiedPushStorage {
  FutureOr<void> init();
  RegistrationsStorage get registrations;
  DistributorStorage get distrib;
  KeysStorage get keys;
}
