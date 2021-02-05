import 'dart:async';

import 'package:flutter/services.dart';

import '../channel.dart';
import 'nami_paywall.dart';
import 'nami_sku.dart';

/// Class responsible for managing all aspects of a paywall in the Nami SDK
class NamiPaywallManager {
  static const EventChannel _signInEvent = const EventChannel('signInEvent');
  static const EventChannel _paywallRaiseEvent =
      const EventChannel('paywallRaiseEvent');

  /// Checks to see if the Nami system can raise a paywall.  A paywall raise
  /// may not be possible due to missing configuration data or paywall is
  /// blocked from raising
  static Future<bool> canRaisePaywall() {
    return channel.invokeMethod("canRaisePaywall");
  }

  /// Displays the current live paywall in the app
  static Future<bool> raisePaywall() {
    return channel.invokeMethod("raisePaywall");
  }

  /// Displays a particular paywall in the app
  static Future<bool> raisePaywallByDeveloperPaywallId(String developerPaywallId) {
    return channel.invokeMethod("raisePaywall", developerPaywallId);
  }

  static Future<void> blockPaywallAutoRaise(bool blockRaise) {
    return channel.invokeMethod("blockPaywallAutoRaise", blockRaise);
  }

  /// iOS Only
  ///
  /// When Nami does not control the paywall, manually create an impression
  /// when the paywall is seen.
  ///
  /// NOTE: This call will only work when the SDK is set to Passive Mode.
  static Future<void> paywallImpression(String developerPaywallId) {
    return channel.invokeMethod("paywallImpression", developerPaywallId);
  }

  /// Stream for when user presses sign in button on a paywall raised by
  /// Nami system
  static Stream<NamiPaywall> signInEvents() {
    var data = _signInEvent
        .receiveBroadcastStream()
        .map((dynamic event) => _handleSignInClicked(event));

    return data;
  }

  static NamiPaywall _handleSignInClicked(Map<dynamic, dynamic> map) {
    return NamiPaywall.fromMap(map);
  }

  static Stream<PaywallRaiseRequestData> paywallRaiseEvents() {
    var data = _paywallRaiseEvent
        .receiveBroadcastStream()
        .map((dynamic event) => _handlePaywallRaiseRequested(event));

    return data;
  }

  static PaywallRaiseRequestData _handlePaywallRaiseRequested(
      Map<dynamic, dynamic> map) {
    List<dynamic> dynamicSkus = map['skus'];
    List<NamiSKU> skus = List();
    dynamicSkus.forEach((element) {
      NamiSKU namiSKU = NamiSKU.fromMap(element);
      skus.add(namiSKU);
    });
    return PaywallRaiseRequestData(NamiPaywall.fromMap(map['namiPaywall']),
        skus, map['developerPaywallId']);
  }
}

class PaywallRaiseRequestData {
  final NamiPaywall namiPaywall;
  final List<NamiSKU> skus;
  final String developerPaywallId;

  PaywallRaiseRequestData(this.namiPaywall, this.skus, this.developerPaywallId);

  @override
  String toString() {
    return 'PaywallRaiseRequestData{namiPaywall: $namiPaywall, skus: $skus, developerPaywallId: $developerPaywallId}';
  }
}
