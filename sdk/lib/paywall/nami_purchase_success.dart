import 'package:nami_flutter/billing/nami_purchase.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';

sealed class NamiPurchaseSuccess {
  NamiSKU product;

  NamiPurchaseSuccess(this.product);

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

  NamiPurchaseSuccessGoogle(NamiSKU product, this.orderId, this.purchaseToken)
      : super(product);

  factory NamiPurchaseSuccessGoogle.fromMap(Map<dynamic, dynamic> map) {
    return NamiPurchaseSuccessGoogle(
      NamiSKU.fromMap(map['product'] as Map<dynamic, dynamic>),
      map['orderId'],
      map['purchaseToken'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> product = this.product.toMap();
    return <String, dynamic>{
      "product": product,
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
  final String? expiresDate;
  final String purchaseDate;
  final String price;
  final String currencyCode;
  final NamiPurchaseSource namiPurchaseSource;

  NamiPurchaseSuccessApple(
      NamiSKU product,
      this.transactionID,
      this.originalTransactionID,
      this.originalPurchaseDate,
      this.expiresDate,
      this.purchaseDate,
      this.price,
      this.currencyCode,
      this.namiPurchaseSource)
      : super(product);

  factory NamiPurchaseSuccessApple.fromMap(Map<dynamic, dynamic> map) {
    return NamiPurchaseSuccessApple(
      NamiSKU.fromMap(map['product'] as Map<dynamic, dynamic>),
      map['transactionID'],
      map['originalTransactionID'],
      map['originalPurchaseDate'],
      map['expiresDate'],
      map['purchaseDate'],
      map['price'],
      map['currencyCode'],
      map['namiPurchaseSource'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> product = this.product.toMap();
    return <String, dynamic>{
      "product": product,
      'transactionID': transactionID,
      'originalTransactionID': originalTransactionID,
      'originalPurchaseDate': originalPurchaseDate,
      'expiresDate': expiresDate,
      'purchaseDate': purchaseDate,
      'price': price,
      'currencyCode': currencyCode,
      'namiPurchaseSource': namiPurchaseSource.name,
    };
  }

  @override
  String toString() {
    return 'NamiPurchaseSuccessApple{product: $product,transactionID: $transactionID, originalTransactionID: $originalTransactionID, '
        'originalPurchaseDate : $originalPurchaseDate, expiresDate: $expiresDate, purchaseDate: $purchaseDate'
        'price: $price, currencyCode: $currencyCode, namiPurchaseSource: $namiPurchaseSource'
        '}';
  }
}
