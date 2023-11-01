import 'package:nami_flutter/billing/nami_purchase.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';

sealed class NamiPurchaseSuccess {
  NamiSKU product;
  String? expiresDate;
  String purchaseDate;
  NamiPurchaseSource namiPurchaseSource;

  NamiPurchaseSuccess(this.product, this.expiresDate, this.purchaseDate,
      this.namiPurchaseSource);

  Map<String, dynamic> toMap();
}

/// This object represents a successful purchase passed to
/// NamiPaywallManager.buySkuComplete when using Nami paywalls
/// atop your own  code or a third-party subscription management vendor
/// such as RevenueCat When the Platform is Android
class NamiPurchaseSuccessGoogle extends NamiPurchaseSuccess {
  String orderId;
  String purchaseToken;
  String? description;

  NamiPurchaseSuccessGoogle(
      NamiSKU product,
      String? expiresDate,
      String purchaseDate,
      NamiPurchaseSource namiPurchaseSource,
      this.description,
      this.orderId,
      this.purchaseToken)
      : super(product, expiresDate, purchaseDate, namiPurchaseSource);

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
  Map<String, dynamic> toMap() {
    Map<String, dynamic> product = this.product.toMap();
    return <String, dynamic>{
      "product": product,
      'expiresDate': expiresDate,
      'purchaseDate': purchaseDate,
      'namiPurchaseSource': namiPurchaseSource.name,
      'description': description,
      'orderId': orderId,
      'purchaseToken': purchaseToken
    };
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
      NamiPurchaseSource namiPurchaseSource,
      this.transactionID,
      this.originalTransactionID,
      this.originalPurchaseDate,
      this.price,
      this.currencyCode,
      this.locale)
      : super(product, expiresDate, purchaseDate, namiPurchaseSource);

  factory NamiPurchaseSuccessApple.fromMap(Map<dynamic, dynamic> map) {
    return NamiPurchaseSuccessApple(
        NamiSKU.fromMap(map['product'] as Map<dynamic, dynamic>),
        map['expiresDate'],
        map['purchaseDate'],
        map['namiPurchaseSource'],
        map['transactionID'],
        map['originalTransactionID'],
        map['originalPurchaseDate'],
        map['price'],
        map['currencyCode'],
        map['locale']);
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> product = this.product.toMap();
    return <String, dynamic>{
      "product": product,
      'expiresDate': expiresDate,
      'transactionID': purchaseDate,
      'namiPurchaseSource': namiPurchaseSource.name,
      'originalTransactionID': originalTransactionID,
      'originalPurchaseDate': originalPurchaseDate,
      'price': price,
      'currencyCode': currencyCode,
      'locale': locale
    };
  }

  @override
  String toString() {
    return 'NamiPurchaseSuccessApple{product: $product, originalTransactionID: $originalTransactionID}';
  }
}
