import 'package:flutter/services.dart';
import 'package:nami_flutter/entitlement/nami_entitlement.dart';

import '../channel.dart';

export 'package:nami_flutter/entitlement/nami_entitlement.dart';

/// This class contains all methods and objects to work with entitlements in the SDK.
class NamiEntitlementManager {
  static const EventChannel _activeEntitlementEvent =
      const EventChannel('activeEntitlementEvent');

  /// Returns [true] if a Nami Control Center defined Entitlement has at
  /// least one backing purchase and it's not expired.
  static Future<bool> isEntitlementActive(String referenceId) {
    return channel
        .invokeMethod<bool>("isEntitlementActive", referenceId)
        .then<bool>((bool? value) => value ?? false);
  }

  /// Returns a list of [NamiEntitlement] that are currently active
  static Future<List<NamiEntitlement>> active() async {
    List<dynamic> list = await channel.invokeMethod("active");
    return _mapToNamiEntitlementList(list);
  }

  /// Get a list of [NamiEntitlement] from that have been configured on
  /// Nami Control Center
  static Future<List<NamiEntitlement>> available() async {
    List<dynamic> list = await channel.invokeMethod("available");
    return _mapToNamiEntitlementList(list);
  }

  static Stream<List<NamiEntitlement>> registerActiveEntitlementsHandler() {
    var data = _activeEntitlementEvent
        .receiveBroadcastStream()
        .map((dynamic event) => _mapToNamiEntitlementList(event));

    return data;
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
