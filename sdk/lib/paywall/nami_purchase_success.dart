import 'package:nami_flutter/paywall/nami_sku.dart';

abstract class NamiPurchaseSuccess {
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
  final String price;
  final String currencyCode;

  NamiPurchaseSuccessApple(
    NamiSKU product,
    this.transactionID,
    this.originalTransactionID,
    this.price,
    this.currencyCode,
  ) : super(product);

  factory NamiPurchaseSuccessApple.fromMap(Map<dynamic, dynamic> map) {
    return NamiPurchaseSuccessApple(
      NamiSKU.fromMap(map['product'] as Map<dynamic, dynamic>),
      map['transactionID'],
      map['originalTransactionID'],
      map['price'],
      map['currencyCode'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> product = this.product.toMap();
    return <String, dynamic>{
      "product": product,
      'transactionID': transactionID,
      'originalTransactionID': originalTransactionID,
      'price': price,
      'currencyCode': currencyCode,
    };
  }

  @override
  String toString() {
    return 'NamiPurchaseSuccessApple{product: $product,transactionID: $transactionID, originalTransactionID: $originalTransactionID, '
        'price: $price, currencyCode: $currencyCode'
        '}';
  }
}
