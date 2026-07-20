import 'dart:async';

/// Object that link a registration instance and its token
class TokenInstance {
  /// Secret shared with the distributor to identify the registration
  final String token;
  /// Identify the registration. This is often an account name
  final String instance;
  TokenInstance(this.token, this.instance);
}

/// Storage for registrations related data
///
/// Most applications use a single registration, multi-accounts apps
/// use one registration per account.
///
/// The *instances* identify the different registrations
abstract class RegistrationsStorage {
  /// Get [TokenInstance] from instance ("default" -> {"default","token1"})
  FutureOr<TokenInstance?> getFromInstance(String instance);
  /// Get [TokenInstance] from token ("token1" -> {"default","token1"})
  FutureOr<TokenInstance?> getFromToken(String token);
  /// Store a new token for instance
  FutureOr<void> save(TokenInstance token);
  /// Remove registration for [instance] and return `true` if there are other
  /// registrations left
  FutureOr<bool> remove(String instance);
  /// Remove all registrations
  FutureOr<void> removeAll();
}
