import 'dart:async';

import 'package:flutter/services.dart';

import '../channel.dart';
import 'nami_paywall.dart';
import 'nami_sku.dart';

/// Class responsible for managing all aspects of a paywall in the Nami SDK
class NamiPaywallManager {
  static const EventChannel _signInEvent = const EventChannel('signInEvent');

  /// Will animate the closing of the paywall if [animated] is true. Returns
  /// [true] when paywall is dismissed, may be immediate if not presented
  static Future<bool> dismiss(bool animated) {
    return channel
        .invokeMethod<bool>("dismiss", animated)
        .then<bool>((bool? value) => value ?? false);
  }


  /// Stream for when user presses sign in button on a paywall
  /// TODO: Re-implemented for 3.0.0 SDKs
  // static Stream<NamiPaywall> signInEvents() {
  //   var data = _signInEvent
  //       .receiveBroadcastStream()
  //       .map((dynamic event) => _handleSignInClicked(event));
  //
  //   return data;
  // }
  //
  // static NamiPaywall _handleSignInClicked(Map<dynamic, dynamic> map) {
  //   return NamiPaywall.fromMap(map);
  // }
}

class PreparePaywallResult {
  final bool success;
  final PreparePaywallError? error;

  PreparePaywallResult(this.success, this.error);
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

extension on String? {
  PreparePaywallError? _toPreparePaywallError() {
    if (this == "paywall_data_not_found") {
      return PreparePaywallError.PAYWALL_DATA_NOT_FOUND;
    } else if (this == "image_load_failed") {
      return PreparePaywallError.PAYWALL_IMAGE_LOAD_FAILED;
    } else if (this == "paywall_data_not_available") {
      return PreparePaywallError.PAYWALL_DATA_NOT_AVAILABLE;
    } else if (this == "no_live_campaign") {
      return PreparePaywallError.NO_LIVE_CAMPAIGN;
    } else if (this == "play_billing_not_available") {
      return PreparePaywallError.PLAY_BILLING_NOT_AVAILABLE;
    } else {
      return null;
    }
  }
}