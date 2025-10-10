import 'dart:async';

class TokenInstance {
  final String token;
  final String instance;
  TokenInstance(this.token, this.instance);
}

abstract class RegistrationsStorage {
  /// Get [TokenInstance] from instance ("default" -> {"default","token1"})
  FutureOr<TokenInstance?> getFromInstance(String instance);
  /// Get [TokenInstance] from token ("token1" -> {"default","token1"})
  FutureOr<TokenInstance?> getFromToken(String token);
  FutureOr<void> save(TokenInstance token);
  /// Remove registration for [instance] and return `true` if there are other
  /// registrations left
  FutureOr<bool> remove(String instance);
  FutureOr<void> removeAll();
}