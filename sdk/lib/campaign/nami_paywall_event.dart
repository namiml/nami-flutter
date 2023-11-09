import 'package:nami_flutter/campaign/model/paywall_lauch_context.dart';
import 'package:nami_flutter/campaign/nami_campaign.dart';

import '../billing/nami_purchase.dart';
import '../paywall/nami_sku.dart';
import 'model/nami_paywall_component_change.dart';
import 'nami_campaign_manager.dart';

class NamiPaywallEvent {
  NamiPaywallAction action;
  String? campaignId;
  String? campaignName;
  NamiCampaignRuleType? campaignType;
  String? campaignLabel;
  String? campaignUrl;
  String? paywallId;
  String? paywallName;
  NamiPaywallComponentChange? componentChange;
  String? segmentId;
  String? externalSegmentId;
  PaywallLaunchContext? paywallLaunchContext;
  String? deepLinkUrl;
  NamiSKU? sku;
  String? purchaseError;
  List<NamiPurchase>? purchases;
  List<NamiSKU>? skus;

  NamiPaywallEvent(
      this.action,
      this.campaignId,
      this.campaignName,
      this.campaignType,
      this.campaignLabel,
      this.campaignUrl,
      this.paywallId,
      this.paywallName,
      this.componentChange,
      this.segmentId,
      this.externalSegmentId,
      this.paywallLaunchContext,
      this.deepLinkUrl,
      this.sku,
      this.purchaseError,
      this.purchases,
      this.skus);

  factory NamiPaywallEvent.fromMap(Map<dynamic, dynamic> map) {
    List<dynamic> dynamicPurchases = map['purchases'];
    List<NamiPurchase> namiPurchases = List.empty(growable: true);
    dynamicPurchases.forEach((element) {
      namiPurchases.add(NamiPurchase.fromMap(element));
    });

    List<NamiSKU> namiSkus = List.empty(growable: true);
    if (map['skus'] != null) {
      List<dynamic> dynamicSkus = map['skus'];
      dynamicSkus.forEach((element) {
        namiSkus.add(NamiSKU.fromMap(element));
      });
    }

    return NamiPaywallEvent(
        (map['action'] as String)._toNamiPaywallAction(),
        map['campaignId'],
        map['campaignName'],
        (map['campaignType'] as String?).toNamiCampaignRuleType(),
        map['campaignUrl'],
        map['campaignLabel'],
        map['paywallId'],
        map['paywallName'],
        map['componentChange'] != null
            ? NamiPaywallComponentChange.fromMap(map['componentChange'])
            : null,
        map['segmentId'],
        map['externalSegmentId'],
        map['paywallLaunchContext'] != null
            ? PaywallLaunchContext.fromJson(map['paywallLaunchContext'])
            : null,
        map['deepLinkUrl'],
        map['sku'] != null ? NamiSKU.fromMap(map['sku']) : null,
        map['purchaseError'],
        namiPurchases,
        namiSkus);
  }

  @override
  String toString() {
    return 'NamiPaywallEvent {action: $action, orderId $campaignId'
        ' campaignName: $campaignName, campaignType: $campaignType, '
        ' campaignLabel: $campaignLabel, paywallId: $paywallId,paywallName: $paywallName,'
        ' componentChange: $componentChange, segmentId: $segmentId,'
        ' externalSegmentId: $externalSegmentId, paywallLaunchContext : $paywallLaunchContext,'
        ' deepLinkUrl: $deepLinkUrl, sku: $sku, purchaseError: $purchaseError, '
        ' purchases: $purchases, skus: $skus}';
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

extension on String {
  NamiPaywallAction _toNamiPaywallAction() {
    if (this == "NAMI_SHOW_PAYWALL") {
      return NamiPaywallAction.NAMI_SHOW_PAYWALL;
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
