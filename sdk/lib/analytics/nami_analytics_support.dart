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
    var type = NamiAnalyticsActionType.unknown;
    switch (map["type"]) {
      case "paywall_raise":
        type = NamiAnalyticsActionType.paywall_raise;
        break;
      case "paywall_raise_blocked":
        type = NamiAnalyticsActionType.paywall_raise_blocked;
        break;
      case "purchase_activity":
        type = NamiAnalyticsActionType.purchase_activity;
    }
    map.remove("type");
    List<dynamic> products = map[NamiAnalyticsKeys.PAYWALL_PRODUCTS];
    List<NamiSKU> namiSkus = List.empty(growable: true);
    products.forEach((element) {
      NamiSKU namiSKU = NamiSKU.fromMap(element);
      namiSkus.add(namiSKU);
    });
    map[NamiAnalyticsKeys.PAYWALL_PRODUCTS] = namiSkus;
    return NamiAnalyticsData(type, map);
  }
}

class NamiAnalyticsData {
  final NamiAnalyticsActionType type;
  final Map<dynamic, dynamic> eventData;

  NamiAnalyticsData(this.type, this.eventData);
}

/// The various types of analytics events that are associated whenever
/// [NamiAnalyticsSupport.analyticsEvents()] is triggered which is set
enum NamiAnalyticsActionType {
  paywall_raise,
  paywall_raise_blocked,
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
  static const String CAMPAIGN_ID = "campaign_id";
  static const String CAMPAIGN_NAME = "campaign_name";

  /// Returned value for this key in map would be of type [bool]
  static const String NAMI_TRIGGERED = "nami_triggered";
  static const String PAYWALL_ID = "paywall_id";
  static const String PAYWALL_NAME = "paywall_name";
  static const String PAYWALL_TYPE = "paywall_type";
  static const String PAYWALL_PRODUCTS = "paywall_products";

  /// Returned value for this key in map would be of an enum of type [NamiAnalyticsPurchaseActivityType]
  static const String PURCHASE_ACTIVITY_TYPE = "purchase_activity_type";

  /// Returned value for this key in map would be of type [NamiPurchase]
  static const String PURCHASE_PRODUCT = "purchase_product";
  static const String PURCHASE_TIMESTAMP = "purchase_timestamp";
}
