import 'package:nami_flutter/billing/nami_purchase.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';

sealed class NamiPurchaseSuccess {
  NamiSKU product;
  String? expiresDate;
  String purchaseDate;

  NamiPurchaseSuccess(
    this.product,
    this.expiresDate,
    this.purchaseDate,
  );
}

/// This object represents a successful purchase passed to
/// NamiPaywallManager.buySkuComplete when using Nami paywalls
/// atop your own  code or a third-party subscription management vendor
/// such as RevenueCat When the Platform is Android
class NamiPurchaseSuccessGoogle extends NamiPurchaseSuccess {
  String orderId;
  String purchaseToken;
  NamiPurchaseSource namiPurchaseSource;
  String? description;

  NamiPurchaseSuccessGoogle(
      NamiSKU product,
      String? expiresDate,
      String purchaseDate,
      this.namiPurchaseSource,
      this.description,
      this.orderId,
      this.purchaseToken)
      : super(product, expiresDate, purchaseDate);

  factory NamiPurchaseSuccessGoogle.fromMap(Map<dynamic, dynamic> map) {
    return NamiPurchaseSuccessGoogle(
      NamiSKU.fromMap(map['product'] as Map<dynamic, dynamic>),
      map['expiresDate'],
      map['purchaseDate'],
      map['namiPurchaseSource'],
      map['description'],
      map['orderId'],
      map['purchaseToken'],
    );
  }

  @override
  String toString() {
    return 'NamiPurchaseSuccessGoogle{product: $product, orderId $orderId}';
  }
}

/// This object represents a successful purchase passed to
/// NamiPaywallManager.buySkuComplete when using Nami paywalls
/// atop your own  code or a third-party subscription management vendor
/// such as RevenueCat When the Platform is iOS
class NamiPurchaseSuccessApple extends NamiPurchaseSuccess {
  final String transactionID;
  final String originalTransactionID;
  final String originalPurchaseDate;
  final String price;
  final String currencyCode;
  final String locale;

  NamiPurchaseSuccessApple(
      NamiSKU product,
      String? expiresDate,
      String purchaseDate,
      this.transactionID,
      this.originalTransactionID,
      this.originalPurchaseDate,
      this.price,
      this.currencyCode,
      this.locale)
      : super(product, expiresDate, purchaseDate);

  factory NamiPurchaseSuccessApple.fromMap(Map<dynamic, dynamic> map) {
    return NamiPurchaseSuccessApple(
        NamiSKU.fromMap(map['product'] as Map<dynamic, dynamic>),
        map['expiresDate'],
        map['purchaseDate'],
        map['transactionID'],
        map['originalTransactionID'],
        map['originalPurchaseDate'],
        map['price'],
        map['currencyCode'],
        map['locale']);
  }

  @override
  String toString() {
    return 'NamiPurchaseSuccessApple{product: $product, originalTransactionID: $originalTransactionID}';
  }
}
