import 'dart:async';

import 'package:flutter/services.dart';

import 'package:nami_flutter/paywall/nami_sku.dart';
import 'package:nami_flutter/billing/nami_purchase_success.dart';
import 'package:nami_flutter/billing/nami_purchase_success_apple.dart';
import 'package:nami_flutter/billing/nami_purchase_success_amazon.dart';
import 'package:nami_flutter/billing/nami_purchase_success_google.dart';

import '../channel.dart';

/// Class responsible for managing all aspects of a paywall in the Nami SDK
class NamiPaywallManager {
  static const EventChannel _signInEvent = EventChannel('signInEvent');
  static const EventChannel _closePaywallEvent =
      EventChannel('closePaywallEvent');
  static const EventChannel _buySkuEvent = EventChannel('buySkuEvent');

  /// Will animate the closing of the paywall if [animated] is true. Returns
  /// [true] when paywall is dismissed, may be immediate if not presented
  static Future<bool> dismiss(bool animated) {
    return channel
        .invokeMethod<bool>("dismiss", animated)
        .then<bool>((bool? value) => value ?? false);
  }

  /// Stream for when user presses sign in button on a paywall
  static Stream<NamiSignInClicked> signInEvents() {
    var data = _signInEvent
        .receiveBroadcastStream()
        .map((dynamic event) => NamiSignInClicked(event));

    return data;
  }

  // Stream for when user presses close on a paywall
  static Stream<void> registerCloseHandler() {
    var data = _closePaywallEvent.receiveBroadcastStream();
    return data;
  }

  // Stream of sku for when user presses sku on a paywall
  static Stream<NamiSKU> registerBuySkuHandler() {
    var data = _buySkuEvent
        .receiveBroadcastStream()
        .map((dynamic event) => event as NamiSKU);
    return data;
  }

  static Future<void> buySkuComplete(
      NamiPurchaseSuccess purchaseSuccess) async {
    if (purchaseSuccess.runtimeType == NamiPurchaseSuccessApple) {
      await channel.invokeMethod<void>(
          "buySkuCompleteApple", purchaseSuccess.toString());
    } else if (purchaseSuccess.runtimeType == NamiPurchaseSuccessAmazon) {
      await channel.invokeMethod<void>(
          "buySkuCompleteAmazon", purchaseSuccess.toString());
    } else if (purchaseSuccess.runtimeType == NamiPurchaseSuccessGoogle) {
      await channel.invokeMethod<void>(
          "buySkuCompleteGoogle", purchaseSuccess.toString());
    }
    return;
  }
}

class PreparePaywallResult {
  final bool success;
  final PreparePaywallError? error;

  PreparePaywallResult(this.success, this.error);
}

class NamiSignInClicked {
  final bool clicked;

  NamiSignInClicked(this.clicked);
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
