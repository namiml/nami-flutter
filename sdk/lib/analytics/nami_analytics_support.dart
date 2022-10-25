import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nami_flutter/billing/nami_purchase.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';

/// Main class to contain analytics related APIs
class NamiAnalyticsSupport {
  static const EventChannel _analyticsEvent =
      const EventChannel('analyticsEvent');

  /// Get a stream of [NamiAnalyticsData] event data whenever Nami platform
  /// registers a specific event of any type from [NamiAnalyticsActionType].
  static Stream<NamiAnalyticsData> analyticsEvents() {
    var data = _analyticsEvent
        .receiveBroadcastStream()
        .map((dynamic event) => _handleAnalyticsEvent(event));

    return data;
  }

  static NamiAnalyticsData _handleAnalyticsEvent(Map<dynamic, dynamic> map) {
    var actionType = NamiAnalyticsActionType.unknown;
    switch (map["action_type"]) {
      case "paywall_raise":
        actionType = NamiAnalyticsActionType.paywall_raise;
        break;
      case "purchase_activity":
        actionType = NamiAnalyticsActionType.purchase_activity;
    }
    map.remove("action_type");
    List<dynamic> products = map[NamiAnalyticsKeys.PAYWALL_SKUS];
    List<NamiSKU> namiSkus = List.empty(growable: true);
    products.forEach((element) {
      NamiSKU namiSKU = NamiSKU.fromMap(element);
      namiSkus.add(namiSKU);
    });
    map[NamiAnalyticsKeys.PAYWALL_SKUS] = namiSkus;
    return NamiAnalyticsData(actionType, map);
  }
}

class NamiAnalyticsData {
  final NamiAnalyticsActionType actionType;
  final Map<dynamic, dynamic> eventData;

  NamiAnalyticsData(this.actionType, this.eventData);
}

/// The various types of analytics events that are associated whenever
/// [NamiAnalyticsSupport.analyticsEvents()] is triggered which is set
enum NamiAnalyticsActionType {
  paywall_raise,
  purchase_activity,
  unknown
}

/// A type related to some purchase activity being sent with analytics event.
/// You should expect a [NamiAnalyticsPurchaseActivityType] available when you
/// have a `purchased product` info available via analytics item mapping.
/// You will get this value back using key
/// [NamiAnalyticsKeys.PURCHASE_ACTIVITY_TYPE] on analytic items map.
enum NamiAnalyticsPurchaseActivityType {
  new_purchase,
  resubscribe,
  restore,
  cancelled
}

/// Keys to help obtain values from the analytic items map that gets sent with
/// [eventData] in [NamiAnalyticsData]. You should rely on key provided by us
/// to retrieve data from the map rather than using raw strings on app side.
class NamiAnalyticsKeys {
  static const String CAMPAIGN_RULE = "campaign_rule";
  static const String CAMPAIGN_SEGMENT = "campaign_segment";
  static const String CAMPAIGN_TYPE = "campaign_type";
  static const String CAMPAIGN_VALUE = "campaign_value";

  static const String PAYWALL = "paywall";
  static const String PAYWALL_TYPE = "paywall_type";
  static const String PAYWALL_SKUS = "paywall_skus";
  static const String PAYWALL_RAISE_SOURCE = "paywall_raise_source";


  /// Returned value for this key in map would be of type [NamiPurchase]
  static const String PURCHASED_SKU = "purchased_sku";
  static const String PURCHASED_SKU_IDENTIFIER = "purchased_sku_id";
  static const String PURCHASED_SKU_PURCHASE_TIMESTAMP = "purchased_sku_purchase_timestamp";
  static const String PURCHASED_SKU_PRICE = "purchased_sku_price";
  static const String PURCHASED_SKU_STORE_LOCALE = "purchased_sku_store_locale";
  static const String PURCHASED_SKU_LOCALE = "purchased_sku_locale";

  /// Returned value for this key in map would be of an enum of type [NamiAnalyticsPurchaseActivityType]
  static const String PURCHASE_ACTIVITY_TYPE = "purchaseActivityType";
}
