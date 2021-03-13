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

  /// Will animate the closing of the paywall if [animated] is true. Returns
  /// [true] when paywall is dismissed, may be immediate if not presented
  static Future<bool> dismissNamiPaywallIfOpen(bool animated) {
    return channel
        .invokeMethod<bool>("dismissNamiPaywallIfOpen", animated)
        .then<bool>((bool? value) => value ?? false);
  }

  /// Prepare paywall for display before calling [raisePaywall]. This method
  /// ensure that all data is available for the paywall before displaying it
  ///
  /// Optionally you can provide,
  /// - A [developerPaywallId] if you want to prepare a specific paywall before
  /// raising it.
  /// - An optional bool for [backgroundImageRequired] to force whether
  /// background image is required to display paywall or not. By default it is
  /// `false`. If passed as `true` then sdk would try to re-fetch the
  /// background image and invoke callback based on image availability
  /// - An optional timeout value for above image fetching operation
  static Future<PreparePaywallResult> preparePaywallForDisplay(
      {String? developerPaywallId,
      bool backgroundImageRequired = false,
      int? imageFetchTimeout}) async {
    var variableMap = {
      "developerPaywallId": developerPaywallId,
      "backgroundImageRequired": backgroundImageRequired,
      "imageFetchTimeout": imageFetchTimeout,
    };
    Map<dynamic, dynamic> result =
        await channel.invokeMethod("preparePaywallForDisplay", variableMap);
    var error = (result['error'] as String?)._toPreparePaywallError();
    return PreparePaywallResult(result['success'], error);
  }

  /// Displays the current live paywall in the app. Optionally pass
  /// [developerPaywallId] to display a particular paywall instead of live one
  static Future<bool> raisePaywall({String? developerPaywallId}) {
    return channel
        .invokeMethod<bool>("raisePaywall", developerPaywallId)
        .then<bool>((bool? value) => value ?? false);
  }

  /// Displays a particular paywall in the app

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

  static NamiPaywall _handleSignInClicked(Map<dynamic, dynamic?> map) {
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
    List<NamiSKU> skus = List.empty(growable: true);
    dynamicSkus.forEach((element) {
      NamiSKU namiSKU = NamiSKU.fromMap(element);
      skus.add(namiSKU);
    });
    return PaywallRaiseRequestData(NamiPaywall.fromMap(map['namiPaywall']),
        skus, map['developerPaywallId']);
  }
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
