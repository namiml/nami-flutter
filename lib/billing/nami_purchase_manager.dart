import 'package:nami_flutter/billing/nami_purchase.dart';

import '../channel.dart';

/// Encapsulates all functionality relating to purchases made on the device
/// whether it's done via the remote Google Play Billing service or Apple
/// StoreKit or local Nami Bypass Store service
class NamiPurchaseManager {
  /// Clears out any purchases made while bypassStore was enabled. This clears
  /// out bypassStore purchases only, it cannot clear out production purchases
  /// made on device.
  static Future<void> clearBypassStorePurchases() async {
    return await channel.invokeMethod("clearBypassStorePurchases");
  }

  /// Returns a list of all purchases
  static Future<List<NamiPurchase>> allPurchases() async {
    return await channel.invokeMethod("allPurchases");
  }

  /// Check if a specific product SKU has been purchased
  static Future<bool> isSKUIDPurchased(String skuID) async {
    return await channel.invokeMethod("isSKUIDPurchased", skuID);
  }

  /// Ask Nami if it knows if a set of product SKU IDs has been purchased
  static Future<bool> anySKUIDPurchased(List<String> skuIDs) async {
    return await channel.invokeMethod("anySKUIDPurchased", skuIDs);
  }

  /// Mark a consumable IAP as processed so it can be purchased again
  static Future<void> consumePurchasedSKU(String skuID) async {
    return await channel.invokeMethod("consumePurchasedSKU", skuID);
  }
}
