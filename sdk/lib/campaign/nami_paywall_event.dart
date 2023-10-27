import 'package:nami_flutter/campaign/nami_campaign.dart';

import '../billing/nami_purchase.dart';
import '../paywall/nami_sku.dart';
import 'nami_campaign_manager.dart';

class NamiPaywallEvent {
  String campaignId;
  String? campaignName;
  String? campaignLabel;
  NamiCampaignRuleType? campaignType;
  String paywallId;
  String? paywallName;
  String? segmentId;
  NamiPaywallAction action;
  NamiSKU? sku;
  String? purchaseError;
  List<NamiPurchase>? purchases;

  NamiPaywallEvent(
      this.campaignId,
      this.campaignName,
      this.campaignLabel,
      this.campaignType,
      this.paywallId,
      this.paywallName,
      this.segmentId,
      this.action,
      this.sku,
      this.purchaseError,
      this.purchases);

  factory NamiPaywallEvent.fromMap(Map<dynamic?, dynamic?> map) {
    List<dynamic> dynamicPurchases = map['purchases'];
    List<NamiPurchase> namiPurchases = List.empty(growable: true);
    dynamicPurchases.forEach((element) {
      namiPurchases.add(NamiPurchase.fromMap(element));
    });

    return NamiPaywallEvent(
        map['campaignId'],
        map['campaignName'],
        map['campaignLabel'],
        (map['campaignType'] as String?).toNamiCampaignRuleType(),
        map['paywallId'],
        map['paywallName'],
        map['segmentId'],
        (map['action'] as String?)._toNamiPaywallAction(),
        map['sku']!=null?NamiSKU.fromMap(map['sku']):null,
        map['purchaseError'],
        namiPurchases);
  }
}

extension on String? {
  NamiCampaignRuleType toNamiCampaignRuleType() {
    if (this == "DEFAULT") {
      return NamiCampaignRuleType.DEFAULT;
    } else if (this == "LABEL") {
      return NamiCampaignRuleType.LABEL;
    } else if (this == "URL") {
      return NamiCampaignRuleType.URL;
    } else {
      return NamiCampaignRuleType.LABEL;
    }
  }
}

extension on String? {
  NamiPaywallAction _toNamiPaywallAction() {
    if (this == "NAMI_SHOW_PAYWALL") {
      return NamiPaywallAction.NAMI_PURCHASE_SELECTED_SKU;
    } else if (this == "NAMI_CLOSE_PAYWALL") {
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
    } else if (this == "NAMI_PURCHASE_CANCELLED") {
      return NamiPaywallAction.NAMI_PURCHASE_CANCELLED;
    } else if (this == "NAMI_PURCHASE_FAILED") {
      return NamiPaywallAction.NAMI_PURCHASE_FAILED;
    } else if (this == "NAMI_PURCHASE_PENDING") {
      return NamiPaywallAction.NAMI_PURCHASE_PENDING;
    } else if (this == "NAMI_PURCHASE_UNKNOWN") {
      return NamiPaywallAction.NAMI_PURCHASE_UNKNOWN;
    } else if (this == "NAMI_PAGE_CHANGE") {
      return NamiPaywallAction.NAMI_PAGE_CHANGE;
    } else if (this == "NAMI_TOGGLE_CHANGE") {
      return NamiPaywallAction.NAMI_TOGGLE_CHANGE;
    } else if (this == "NAMI_SLIDE_CHANGE") {
      return NamiPaywallAction.NAMI_SLIDE_CHANGE;
    } else {
      return NamiPaywallAction.NAMI_PURCHASE_UNKNOWN;
    }
  }
}
