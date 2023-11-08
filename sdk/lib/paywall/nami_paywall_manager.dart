import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nami_flutter/paywall/nami_purchase_success.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';

import '../channel.dart';

/// Class responsible for managing all aspects of a paywall in the Nami SDK
class NamiPaywallManager {
  static const EventChannel _signInEvent = const EventChannel('signInEvent');
  static const EventChannel _closePaywallEvent =
      const EventChannel('closePaywallEvent');
  static const EventChannel _buySkuEvent = const EventChannel('buySkuEvent');
  static const EventChannel _restorePaywallEvent =
      const EventChannel('restorePaywallEvent');

  /// Will animate the closing of the paywall if [animated] is true. Returns
  /// [true] when paywall is dismissed, may be immediate if not presented
  static Future<bool> dismiss(bool animated) {
    return channel
        .invokeMethod<bool>("dismiss", animated)
        .then<bool>((bool? value) => value ?? false);
  }

  /// Stream for when user presses sign in button on a paywall
  static Stream<void> signInEvents() {
    var data = _signInEvent.receiveBroadcastStream();
    return data;
  }

  // Stream for when user presses close on a paywall
  static Stream<void> registerCloseHandler() {
    var data = _closePaywallEvent.receiveBroadcastStream();
    return data;
  }

  // Stream for when user presses restore on a paywall
  static Stream<void> registerRestoreHandler() {
    var data = _restorePaywallEvent.receiveBroadcastStream();
    return data;
  }

  // Stream of skuId for when user presses sku on a paywall
  static Stream<NamiSKU> registerBuySkuHandler() {
    var data = _buySkuEvent
        .receiveBroadcastStream()
        .map((dynamic event) => NamiSKU.fromMap(event));
    return data;
  }

  static Future<bool> buySkuComplete(NamiPurchaseSuccess namiPurchaseSuccess) {
    return channel
        .invokeMethod<bool>("buySkuComplete", namiPurchaseSuccess.toMap())
        .then<bool>((bool? value) => value ?? false);
  }

  static Future<void> buySkuCancel() {
    var data = channel.invokeMethod<bool>("buySkuCancel");
    return data;
  }
}

enum PreparePaywallError {
  /// Paywall id provided by campaign is not valid
  PAYWALL_DATA_NOT_FOUND,

  /// Image loading failed. Make sure you are uploading compressed
  /// files to the Nami Control Center.
  PAYWALL_IMAGE_LOAD_FAILED,

  /// Crucial data is not available, or not yet available which is required to
  /// display and populate paywall on screen. Paywall cannot be shown without
  /// required data.
  PAYWALL_DATA_NOT_AVAILABLE,

  /// A paywall must be attached to a live campaign when requested via
  /// [NamiCampaignManager.launch]
  NO_LIVE_CAMPAIGN,

  /// Connection to Google Play Billing is not available (Android only)
  PLAY_BILLING_NOT_AVAILABLE
}
