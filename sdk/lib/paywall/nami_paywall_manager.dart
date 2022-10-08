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
  static Stream<NamiPaywall> signInEvents() {
    var data = _signInEvent
        .receiveBroadcastStream()
        .map((dynamic event) => _handleSignInClicked(event));

    return data;
  }

  static NamiPaywall _handleSignInClicked(Map<dynamic, dynamic> map) {
    return NamiPaywall.fromMap(map);
  }


class PreparePaywallResult {
  final bool success;
  final PreparePaywallError? error;

  PreparePaywallResult(this.success, this.error);
}

enum PreparePaywallError {
  /// SDK must be initialized via [Nami.configure] before preparing paywall
  /// for display
  SDK_NOT_INITIALIZED,

  /// Developer paywall id provided via
  /// [NamiPaywallManager.preparePaywallForDisplay] must be valid and
  /// associated with a paywall
  DEVELOPER_PAYWALL_ID_NOT_FOUND,

  /// In case of Nami type paywall, if paywall is already being displayed on
  /// screen then prepare results in error
  PAYWALL_ALREADY_DISPLAYED,

  /// Image loading failed. You may try calling `prepare` again depending on
  /// your application requirements
  IMAGE_LOAD_FAILED,

  /// Crucial data is not available, or not yet available which is required to
  /// display and populate paywall on screen. Paywall cannot be shown without
  /// required data. You may try calling `prepare` again
  DATA_NOT_AVAILABLE,

  /// A paywall must be attached to a live campaign when requested via
  /// [NamiPaywallManager.preparePaywallForDisplay] without `developerPaywallId`
  NO_LIVE_CAMPAIGN
}

class PaywallRaiseRequestData {
  final NamiPaywall namiPaywall;
  final List<NamiSKU> skus;
  final String developerPaywallId;

  PaywallRaiseRequestData(this.namiPaywall, this.skus, this.developerPaywallId);

  @override
  String toString() {
    return 'PaywallRaiseRequestData{namiPaywall: $namiPaywall, skus: $skus, '
        'developerPaywallId: $developerPaywallId}';
  }
}

extension on String? {
  PreparePaywallError? _toPreparePaywallError() {
    if (this == "data_not_available") {
      return PreparePaywallError.DATA_NOT_AVAILABLE;
    } else if (this == "developer_paywall_id_not_found") {
      return PreparePaywallError.DEVELOPER_PAYWALL_ID_NOT_FOUND;
    } else if (this == "image_load_failed") {
      return PreparePaywallError.IMAGE_LOAD_FAILED;
    } else if (this == "no_live_campaign") {
      return PreparePaywallError.NO_LIVE_CAMPAIGN;
    } else if (this == "paywall_already_displayed") {
      return PreparePaywallError.PAYWALL_ALREADY_DISPLAYED;
    } else if (this == "sdk_not_initialized") {
      return PreparePaywallError.SDK_NOT_INITIALIZED;
    } else {
      return null;
    }
  }
}
