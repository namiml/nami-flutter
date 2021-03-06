import 'package:flutter/services.dart';
import 'package:nami_flutter/billing/nami_purchase.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';

import '../channel.dart';

/// Encapsulates all functionality relating to purchases made on the device
/// whether it's done via the remote Google Play Billing service or Apple
/// StoreKit or local Nami Bypass Store service
class NamiPurchaseManager {
  static const EventChannel _purchaseChangeEvent =
      const EventChannel('purchaseChangeEvent');

  /// Clears out any purchases made while bypassStore was enabled. This clears
  /// out bypassStore purchases only, it cannot clear out production purchases
  /// made on device.
  static Future<void> clearBypassStorePurchases() {
    return channel.invokeMethod("clearBypassStorePurchases");
  }

  /// Returns a list of all purchases
  static Future<List<NamiPurchase>> allPurchases() async {
    List<dynamic> dynamicPurchases = await channel.invokeMethod("allPurchases");
    List<NamiPurchase> allPurchases = List.empty(growable: true);
    dynamicPurchases.forEach((element) {
      NamiPurchase namiPurchase = NamiPurchase.fromMap(element);
      allPurchases.add(namiPurchase);
    });
    return allPurchases;
  }

  /// Check if a specific product SKU has been purchased
  static Future<bool> isSKUIDPurchased(String skuID) {
    return channel
        .invokeMethod<bool>("isSKUIDPurchased", skuID)
        .then<bool>((bool? value) => value ?? false);
  }

  /// Ask Nami if it knows if a set of product SKU IDs has been purchased
  static Future<bool> anySKUIDPurchased(List<String> skuIDs) {
    return channel
        .invokeMethod<bool>("anySKUIDPurchased", skuIDs)
        .then<bool>((bool? value) => value ?? false);
  }

  /// Mark a consumable IAP as processed so it can be purchased again
  static Future<void> consumePurchasedSKU(String skuID) {
    return channel.invokeMethod("consumePurchasedSKU", skuID);
  }

  /// Initiate a Google Play Billing or Apple StoreKit purchase using
  /// [skuId] from a [NamiSKU]
  static Future<NamiPurchaseCompleteResult> buySKU(String skuId) async {
    Map<dynamic, dynamic?> map = await channel.invokeMethod("buySKU", skuId);
    print("buySKU returned $map");
    return NamiPurchaseCompleteResult(
        (map['purchaseState'] as String)._toNamiPurchaseState(), map['error']);
  }

  static Stream<PurchaseChangeEventData> purchaseChangeEvents() {
    var data = _purchaseChangeEvent
        .receiveBroadcastStream()
        .map((dynamic event) => _mapToPurchaseChangeEventData(event));

    return data;
  }

  static PurchaseChangeEventData _mapToPurchaseChangeEventData(
      Map<dynamic, dynamic> map) {
    List<dynamic> dynamicPurchases = map['activePurchases'];
    List<NamiPurchase> activePurchases = List.empty(growable: true);
    dynamicPurchases.forEach((element) {
      NamiPurchase namiPurchase = NamiPurchase.fromMap(element);
      activePurchases.add(namiPurchase);
    });
    var purchaseState = (map['purchaseState'] as String)._toNamiPurchaseState();
    return PurchaseChangeEventData(
        activePurchases, purchaseState, map['error']);
  }
}

extension on String {
  NamiPurchaseState _toNamiPurchaseState() {
    if (this == "purchased") {
      return NamiPurchaseState.purchased;
    } else if (this == "failed") {
      return NamiPurchaseState.failed;
    } else if (this == "cancelled") {
      return NamiPurchaseState.cancelled;
    } else {
      return NamiPurchaseState.unknown;
    }
  }
}

class PurchaseChangeEventData {
  final List<NamiPurchase> activePurchases;
  final NamiPurchaseState purchaseState;
  final String? error;

  PurchaseChangeEventData(this.activePurchases, this.purchaseState, this.error);
}

class NamiPurchaseCompleteResult {
  final NamiPurchaseState purchaseState;
  final String? error;

  NamiPurchaseCompleteResult(this.purchaseState, this.error);
}

enum NamiPurchaseState { purchased, failed, cancelled, unknown }
