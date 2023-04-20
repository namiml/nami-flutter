import 'package:flutter/services.dart';
import 'package:nami_flutter/billing/nami_purchase.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';

import '../channel.dart';

/// Encapsulates all functionality relating to purchases made on the device
/// whether it's done via the remote Google Play Billing service or Apple
/// StoreKit or local Nami Bypass Store service
class NamiPurchaseManager {
  static const EventChannel _purchasesResponseHandlerData =
      const EventChannel('purchasesResponseHandlerData');

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
  static Future<bool> skuPurchased(String skuID) {
    return channel
        .invokeMethod<bool>("skuPurchased", skuID)
        .then<bool>((bool? value) => value ?? false);
  }

  /// Ask Nami if it knows if a set of product SKU IDs has been purchased
  static Future<bool> anySkuPurchased(List<String> skuIDs) {
    return channel
        .invokeMethod<bool>("anySkuPurchased", skuIDs)
        .then<bool>((bool? value) => value ?? false);
  }

  /// Mark a consumable IAP as processed so it can be purchased again
  static Future<void> consumePurchasedSku(String skuID) {
    return channel.invokeMethod("consumePurchasedSku", skuID);
  }

  /// Call the offer code redemption sheet (Apple-only)
  static Future<void> presentCodeRedemptionSheet() {
    return channel.invokeMethod("presentCodeRedemptionSheet");
  }

  /// Initiate a Google Play Billing or Apple StoreKit purchase using
  /// [skuId] from a [NamiSKU]. Used by the linked paywall use case only.
  static Future<NamiPurchaseCompleteResult> buySku(String skuId) async {
    Map<dynamic, dynamic> map = await channel.invokeMethod("buySku", skuId);
    return NamiPurchaseCompleteResult(
        (map['purchaseState'] as String)._toNamiPurchaseState(), map['error']);
  }

  static Stream<NamiPurchaseResponseHandlerData>
      registerPurchasesChangedHandler() {
    var data = _purchasesResponseHandlerData
        .receiveBroadcastStream()
        .map((dynamic event) => _mapToPurchaseResponseHandlerData(event));

    return data;
  }

  static NamiPurchaseResponseHandlerData _mapToPurchaseResponseHandlerData(
      Map<dynamic, dynamic> map) {
    List<dynamic> dynamicPurchases = map['activePurchases'];
    List<NamiPurchase> activePurchases = List.empty(growable: true);
    dynamicPurchases.forEach((element) {
      NamiPurchase namiPurchase = NamiPurchase.fromMap(element);
      activePurchases.add(namiPurchase);
    });
    var purchaseState = (map['purchaseState'] as String)._toNamiPurchaseState();
    return NamiPurchaseResponseHandlerData(
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
    } else if (this == "pending") {
      return NamiPurchaseState.pending;
    } else if (this == "deferred") {
      return NamiPurchaseState.deferred;
    } else if (this == "resubscribed") {
      return NamiPurchaseState.resubscribed;
    } else if (this == "consumed") {
      return NamiPurchaseState.consumed;
    } else if (this == "pending") {
      return NamiPurchaseState.pending;
    } else {
      return NamiPurchaseState.unknown;
    }
  }
}

class NamiPurchaseResponseHandlerData {
  final List<NamiPurchase> purchases;
  final NamiPurchaseState purchaseState;
  final String? error;

  NamiPurchaseResponseHandlerData(
      this.purchases, this.purchaseState, this.error);
}

class NamiPurchaseCompleteResult {
  final NamiPurchaseState purchaseState;
  final String? error;

  NamiPurchaseCompleteResult(this.purchaseState, this.error);
}

enum NamiPurchaseState {
  purchased,
  failed,
  cancelled,
  pending,
  unknown,
  deferred,
  resubscribed,
  unsubscribed,
  consumed
}
