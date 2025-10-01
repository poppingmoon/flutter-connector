import 'package:unifiedpush_platform_interface/data/public_key_set.dart';

///  Contains the push endpoint and the associated [PublicKeySet].
class PushEndpoint {
  /// URL to push notifications to.
  final String url;
  /// Web Push public key set.
  final PublicKeySet? pubKeySet;
  /// This endpoint is comes from a fallback distributor and should change soon
  final bool temporary;
  PushEndpoint(this.url, this.pubKeySet, {this.temporary = false});
}