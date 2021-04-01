import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nami_flutter/entitlement/nami_entitlement.dart';
import 'package:nami_flutter/entitlement/nami_entitlement_setter.dart';

import '../channel.dart';

export 'package:nami_flutter/entitlement/nami_entitlement.dart';

/// This class contains all methods and objects to work with entitlements in the SDK.
class NamiEntitlementManager {
  static const EventChannel _entitlementChangeEvent =
      const EventChannel('entitlementChangeEvent');

  /// Call to remove any entitlements previously set in the SDK
  static Future<void> clearAllEntitlements() {
    return channel.invokeMethod("clearAllEntitlements");
  }

  /// Returns [true] if a Nami Control Center defined Entitlement has at
  /// least one backing purchase and it's not expired.
  static Future<bool> isEntitlementActive(String referenceId) {
    return channel
        .invokeMethod<bool>("isEntitlementActive", referenceId)
        .then<bool>((bool? value) => value ?? false);
  }

  /// Returns a list of [NamiEntitlement] that are currently active
  static Future<List<NamiEntitlement>> activeEntitlements() async {
    List<dynamic> list = await channel.invokeMethod("activeEntitlements");
    return _mapToNamiEntitlementList(list);
  }

  /// Get a list of [NamiEntitlement] from that have been configured on
  /// Nami Control Center
  static Future<List<NamiEntitlement>> getEntitlements() async {
    List<dynamic> list = await channel.invokeMethod("getEntitlements");
    return _mapToNamiEntitlementList(list);
  }

  static Stream<List<NamiEntitlement>> entitlementChangeEvents() {
    var data = _entitlementChangeEvent
        .receiveBroadcastStream()
        .map((dynamic event) => _mapToNamiEntitlementList(event));

    return data;
  }

  static Future<void> setEntitlements(
      List<NamiEntitlementSetter> entitlements) async {
    List<Map<String, dynamic>> list = List.empty(growable: true);
    entitlements.forEach((element) {
      var variableMap = {
        'referenceId': element.referenceId,
        "expires": element.expires?.millisecondsSinceEpoch,
        "platform": describeEnum(element.platform),
        "purchasedSKUid": element.purchasedSKUid,
      };
      list.add(variableMap);
    });
    return await channel.invokeMethod("setEntitlements", list);
  }

  static List<NamiEntitlement> _mapToNamiEntitlementList(List<dynamic> list) {
    List<NamiEntitlement> namiEntitlements = List.empty(growable: true);
    list.forEach((element) {
      NamiEntitlement namiEntitlement = NamiEntitlement.fromMap(element);
      namiEntitlements.add(namiEntitlement);
    });
    return namiEntitlements;
  }
}
