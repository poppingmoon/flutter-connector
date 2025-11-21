import 'dart:typed_data';

import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:unifiedpush_platform_interface/data/public_key_set.dart';
import 'package:unifiedpush_platform_interface/data/push_endpoint.dart';
import 'package:unifiedpush_platform_interface/data/push_message.dart';
import 'package:unifiedpush_storage_interface/storage.dart';
import 'package:webpush_encryption/webpush_encryption.dart';

class OrgUnifiedpushConnector2 extends DBusObject {
  void Function(PushEndpoint endpoint, String instance)? _onNewEndpoint;
  void Function(String instance)? _onUnregistered;
  void Function(PushMessage message, String instance)? _onMessage;
  UnifiedPushStorage storage;

  DBusMethodResponse get _dbusSuccess {
    return DBusMethodSuccessResponse([DBusDict.stringVariant({})]);
  }

  /// Creates a new object to expose on [path].
  OrgUnifiedpushConnector2(this.storage) : super(const DBusObjectPath.unchecked('/org/unifiedpush/Connector'));

  Future<void> initializeCallback({
    void Function(PushEndpoint endpoint, String instance)? onNewEndpoint,
    void Function(String instance,)? onUnregistered,
    void Function(PushMessage message, String instance)? onMessage,
  }) async {
    _onNewEndpoint = onNewEndpoint;
    _onUnregistered = onUnregistered;
    _onMessage = onMessage;
  }

  /// Implementation of org.unifiedpush.Connector2.Message()
  Future<DBusMethodResponse> doOnMessage(
      String instance,
      Map<String, DBusValue> args
      ) async {
    final onMessage = _onMessage;
    if (onMessage == null) return _dbusSuccess;
    var serializedKey = await storage.keys.get(instance);
    var bytesMessage = args["message"]?.asByteArray().toList();
    if (bytesMessage == null) return DBusMethodErrorResponse.invalidArgs();
    var message = PushMessage(
        Uint8List.fromList(bytesMessage),
      false,
    );
    try {
      if (serializedKey != null) {
        var key = await WebPushKeySet.deserialize(serializedKey);
        message = PushMessage(
            await WebPush().decrypt(key, message.content),
            true
        );
      } else {
        throw Exception("No webpush key found for $instance");
      }
    } catch(e) {
      if (e is ArgumentError || e is KeyError || e is DecryptionError) {
        debugPrint("Could not decrypt message: ${e.runtimeType}");
      } else {
        debugPrint("Could not decrypt message: $e");
      }
    } finally {
      onMessage.call(message, instance);
    }
    return _dbusSuccess;
  }

  PublicKeySet _publicKeySet(PublicWebPushKey pubkey) {
    return PublicKeySet(
        pubkey.p256dh.replaceAll("=", ""),
        pubkey.auth.replaceAll("=", "")
    );
  }

  /// Implementation of org.unifiedpush.Connector2.NewEndpoint()
  Future<DBusMethodResponse> doOnNewEndpoint(
      String instance,
      Map<String, DBusValue> args
      ) async {
    final onNewEndpoint = _onNewEndpoint;
    if (onNewEndpoint == null) return _dbusSuccess;
    var serializedKey = await storage.keys.get(instance);
    WebPushKeySet key;
    if (serializedKey == null) {
      key = await WebPushKeySet.newKeyPair();
      storage.keys.set(instance, key.serialize);
    } else {
      key = await WebPushKeySet.deserialize(serializedKey);
    }
    onNewEndpoint.call(
      PushEndpoint(
        args["endpoint"]!.asString(),
        _publicKeySet(key.publicKey),
      ),
      instance
    );
    return  _dbusSuccess;
  }

  /// Implementation of org.unifiedpush.Connector2.Unregistered()
  Future<DBusMethodResponse> doOnUnregistered(String instance) async {
    final onUnregistered = _onUnregistered;
    if (onUnregistered == null) return _dbusSuccess;
    storage.keys.remove(instance);
    final regLeft = await storage.registrations.remove(instance);
    if (!regLeft) {
      storage.distrib.remove();
    }
    _onUnregistered?.call(instance);

    return DBusMethodSuccessResponse();
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface('org.unifiedpush.Connector2', methods: [
        DBusIntrospectMethod(
          'Message',
          args: [
            DBusIntrospectArgument(
              DBusSignature('a{sv}'),
              DBusArgumentDirection.in_,
            ),
            DBusIntrospectArgument(
              DBusSignature('a{sv}'),
              DBusArgumentDirection.out,
            )
          ],
        ),
        DBusIntrospectMethod(
          'NewEndpoint',
          args: [
            DBusIntrospectArgument(
              DBusSignature('a{sv}'),
              DBusArgumentDirection.in_,
            ),
            DBusIntrospectArgument(
              DBusSignature('a{sv}'),
              DBusArgumentDirection.out,
            )
          ],
        ),
        DBusIntrospectMethod(
          'Unregistered',
          args: [
            DBusIntrospectArgument(
              DBusSignature('a{sv}'),
              DBusArgumentDirection.in_,
            ),
            DBusIntrospectArgument(
              DBusSignature('a{sv}'),
              DBusArgumentDirection.out,
            )
          ],
        )
      ])
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.unifiedpush.Connector2') {
      return DBusMethodErrorResponse.unknownInterface();
    }
    if (methodCall.signature != DBusSignature('a{sv}')) {
      return DBusMethodErrorResponse.invalidArgs();
    }

    var args = methodCall.values[0].asStringVariantDict();
    var token = args["token"]?.asString();
    if (token == null) {
      return DBusMethodErrorResponse.invalidArgs();
    }
    var instance = (await storage.registrations.getFromToken(token))?.instance;
    if (instance == null) {
      return DBusMethodErrorResponse.invalidArgs();
    }
    switch (methodCall.name) {
      case "Message":
        return doOnMessage(instance, args);
      case "NewEndpoint":
        return doOnNewEndpoint(instance, args);
      case "Unregistered":
        return doOnUnregistered(instance);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'org.unifiedpush.Connector2') {
      return DBusMethodErrorResponse.unknownProperty();
    } else {
      return DBusMethodErrorResponse.unknownInterface();
    }
  }

  @override
  Future<DBusMethodResponse> setProperty(
      String interface, String name, DBusValue value) async {
    if (interface == 'org.unifiedpush.Connector2') {
      return DBusMethodErrorResponse.unknownProperty();
    } else {
      return DBusMethodErrorResponse.unknownInterface();
    }
  }
}
