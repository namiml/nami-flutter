import 'package:nami_flutter/paywall/nami_sku.dart';
import 'package:nami_flutter/billing/nami_purchase.dart';
import 'package:nami_flutter/billing/nami_purchase_success.dart';

class NamiPurchaseSuccessApple extends NamiPurchaseSuccess {
  /// SKPaymentTransaction.transactionIdentifier
  final String transactionID;

  /// SKPaymentTransaction.original?.transactionIdentifier
  final String originalTransactionID;

  /// SKPaymentTransaction.original?.transactionDate (ISO8601 string)
  final String originalPurchaseDate;

  /// The SKProduct.price from Apple StoreKit
  final String price;

  /// The SKProduct.priceLocale.currencyCode from Apple StoreKit
  final String currencyCode;

  /// The SKProduct.priceLocale.identifier from StoreKit
  final String locale;

  NamiPurchaseSuccessApple(
      NamiSKU product,
      String description,
      String purchaseDate,
      String? expiresDate,
      NamiPurchaseSource purchaseSource,
      this.transactionID,
      this.originalTransactionID,
      this.originalPurchaseDate,
      this.price,
      this.currencyCode,
      this.locale)
      : super(product, description, purchaseDate, expiresDate, purchaseSource);

  @override
  String toString() {
    return 'NamiPurchaseSuccessApple{product: '
        '$product, description: '
        '$description, purchaseDate: $purchaseDate, '
        'expiresDate: $expiresDate, purchaseSource: '
        '$purchaseSource, transactionID: $transactionID, '
        'originalTransactionID: $originalTransactionID, '
        'originalPurchaseDate: $originalPurchaseDate, '
        'price: $price, currencyCode: $currencyCode, '
        'locale: $locale';
  }
}
