import 'dart:core';

import 'package:nami_flutter/paywall/nami_sku.dart';

/// This object represents a successful purchase passed to
/// NamiPaywallManager.buySkuComplete when using Nami paywalls
/// atop your own  code or a third-party subscription management vendor
/// such as RevenueCat
class NamiPurchaseSuccessApple {
  final NamiSKU product;
  final String transactionID;
  final String originalTransactionID;
  final String purchaseDate;
  final String originalPurchaseDate;
  final String? expiresDate;
  final String price;
  final String currencyCode;
  final String locale;

  NamiPurchaseSuccessApple(this.product,
      this.transactionID,
      this.originalTransactionID,
      this.purchaseDate,
      this.originalPurchaseDate,
      this.expiresDate,
      this.price,
      this.currencyCode,
      this.locale);

  factory NamiPurchaseSuccessApple.fromMap(Map<dynamic, dynamic> map) {
    return NamiPurchaseSuccessApple(NamiSKU.fromMap(map['product'] as Map<dynamic, dynamic>),
        map['transactionID'],
        map['originalTransactionID'],
        map['purchaseDate'],
        map['originalPurchaseDate'],
        map['expiresDate'],
        map['price'],
        map['currencyCode'],
        map['locale']);
  }

  @override
  String toString() {
    return 'NamiPurchaseSuccessApple{product: $product, originalTransactionID: $originalTransactionID}';
  }
}
