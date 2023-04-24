import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nami_flutter/campaign/nami_campaign.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';
import 'package:nami_flutter/billing/nami_purchase.dart';

import '../channel.dart';

/// Manager class which providing functionality related to displaying a paywall
/// by launching a campaign
class NamiCampaignManager {
  // EventChannel(s) to listen for the event from native
  static const EventChannel _campaignsEvent = EventChannel('campaignsEvent');
  static const EventChannel _paywallActionEvent =
      EventChannel('paywallActionEvent');

  /// Launch a campaign to raise a paywall
  ///
  /// Optionally you can provide,
  /// - A [label] to identify a specific campaign
  /// - A [onPaywallAction] callback to listen for the actions triggered on paywall
  static Future<LaunchCampaignResult> launch(
      {String? label,
      Function(NamiPaywallAction, NamiSKU?, String?, List<NamiPurchase>?)? onPaywallAction}) async {
    // Listen for the paywall action event
    _paywallActionEvent.receiveBroadcastStream().listen((event) {
      NamiPaywallAction? action =
          (event["action"] as String?)._toNamiPaywallAction();
      Map<dynamic, dynamic>? skuMap = event["sku"] as Map<dynamic, dynamic>?;
      NamiSKU? sku;
      if (skuMap != null) {
        sku = NamiSKU.fromMap(skuMap);
      }

      String? purchaseError = event["purchaseError"] as String?;

      List<dynamic>? dynamicPurchases = event["purchases"];
      List<NamiPurchase> purchases = [];
      dynamicPurchases?.forEach((element) {
        NamiPurchase namiPurchase = NamiPurchase.fromMap(element);
        purchases.add(namiPurchase);
      });

      if (action != null) {
        onPaywallAction!(action, sku, purchaseError, purchases);
      }
    });

    var variableMap = {
      "label": label,
    };

    final result = await channel.invokeMethod("launch", variableMap);
    var error = (result['error'] as String?)._toLaunchCampaignError();

    return LaunchCampaignResult(result['success'] ?? false, error);
  }

  static Future<List<NamiCampaign>> allCampaigns() async {
    List<dynamic> list = await channel.invokeMethod("allCampaigns");
    return list.map((e) => NamiCampaign.fromMap(e)).toList();
  }

  static Stream<List<NamiCampaign>> registerAvailableCampaignsHandler() {
    var data = _campaignsEvent
        .receiveBroadcastStream()
        .map((event) => _mapToNamiCampaignList(event));

    return data;
  }

  /// Asks Nami to fetch the latest active campaigns for this device
  /// @return list of active campaigns after updating.
  static Future<List<NamiCampaign>> refresh() async {
    List<dynamic> list = await channel.invokeMethod("campaigns.refresh");
    return list.map((e) => NamiCampaign.fromMap(e)).toList();
  }

  /// Returns true if a campaign is available matching the provided label or default
  /// @param provided label or null if default campaign
  static Future<bool> isCampaignAvailable({String? label}) async {
    var variableMap = {
      "label": label,
    };
    bool available =
        await channel.invokeMethod("isCampaignAvailable", variableMap);
    return available;
  }

  static List<NamiCampaign> _mapToNamiCampaignList(List<dynamic> list) {
    return list.map((element) {
      return NamiCampaign.fromMap(element);
    }).toList();
  }
}

enum LaunchCampaignError {
  /// SDK must be initialized via [Nami.configure] before launching a campaign
  SDK_NOT_INITIALIZED,

  /// No live default campaign could be launched.
  DEFAULT_CAMPAIGN_NOT_FOUND,

  /// No live campaign could be launched for the requested label.
  LABELED_CAMPAIGN_NOT_FOUND,

  /// Cannot launch a campaign, because a paywall is currently on screen
  PAYWALL_ALREADY_DISPLAYED,

  /// No campaign found
  CAMPAIGN_DATA_NOT_FOUND
}

class LaunchCampaignResult {
  final bool success;
  final LaunchCampaignError? error;

  LaunchCampaignResult(this.success, this.error);
}

extension on String? {
  LaunchCampaignError? _toLaunchCampaignError() {
    if (this == "sdk_not_initialized") {
      return LaunchCampaignError.SDK_NOT_INITIALIZED;
    } else if (this == "default_campaign_not_found") {
      return LaunchCampaignError.DEFAULT_CAMPAIGN_NOT_FOUND;
    } else if (this == "labeled_campaign_not_found") {
      return LaunchCampaignError.LABELED_CAMPAIGN_NOT_FOUND;
    } else if (this == "campaign_data_not_found") {
      return LaunchCampaignError.CAMPAIGN_DATA_NOT_FOUND;
    } else if (this == "paywall_already_displayed") {
      return LaunchCampaignError.PAYWALL_ALREADY_DISPLAYED;
    } else if (this == "sdk_not_initialized") {
      return LaunchCampaignError.CAMPAIGN_DATA_NOT_FOUND;
    } else {
      return null;
    }
  }
}

enum NamiPaywallAction {
  NAMI_CLOSE_PAYWALL,
  NAMI_RESTORE_PURCHASES,
  NAMI_SIGN_IN,
  NAMI_BUY_SKU,
  NAMI_SELECT_SKU,
  NAMI_PURCHASE_SELECTED_SKU,
  NAMI_PURCHASE_SUCCESS,
  NAMI_PURCHASE_CANCELLED,
  NAMI_PURCHASE_FAILED,
  NAMI_PURCHASE_DEFERRED,
  NAMI_PURCHASE_PENDING,
  NAMI_PURCHASE_UNKNOWN
}

extension on String? {
  NamiPaywallAction? _toNamiPaywallAction() {
    if (this == "NAMI_CLOSE_PAYWALL") {
      return NamiPaywallAction.NAMI_CLOSE_PAYWALL;
    } else if (this == "NAMI_RESTORE_PURCHASES") {
      return NamiPaywallAction.NAMI_RESTORE_PURCHASES;
    } else if (this == "NAMI_SIGN_IN") {
      return NamiPaywallAction.NAMI_SIGN_IN;
    } else if (this == "NAMI_BUY_SKU") {
      return NamiPaywallAction.NAMI_BUY_SKU;
    } else if (this == "NAMI_SELECT_SKU") {
      return NamiPaywallAction.NAMI_SELECT_SKU;
    } else if (this == "NAMI_PURCHASE_SELECTED_SKU") {
      return NamiPaywallAction.NAMI_PURCHASE_SELECTED_SKU;
    } else if (this == "NAMI_PURCHASE_SUCCESS") {
      return NamiPaywallAction.NAMI_PURCHASE_SUCCESS;
    } else if (this == "NAMI_PURCHASE_SUCCESS") {
      return NamiPaywallAction.NAMI_PURCHASE_SUCCESS;
    } else {
      return null;
    }
  }
}
