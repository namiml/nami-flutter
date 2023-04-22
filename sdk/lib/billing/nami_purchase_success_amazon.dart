import 'package:nami_flutter/paywall/nami_sku.dart';
import 'package:nami_flutter/billing/nami_purchase.dart';
import 'package:nami_flutter/billing/nami_purchase_success.dart';

class NamiPurchaseSuccessAmazon extends NamiPurchaseSuccess {
  final String receiptId;

  final String localizedPrice;

  final String userId;

  final String marketplace;

  NamiPurchaseSuccessAmazon(
      NamiSKU product,
      String description,
      String purchaseDate,
      String? expiresDate,
      NamiPurchaseSource purchaseSource,
      this.receiptId,
      this.localizedPrice,
      this.userId,
      this.marketplace)
      : super(product, description, purchaseDate, expiresDate, purchaseSource);

  @override
  String toString() {
    return 'NamiPurchaseSuccessAmazon{product: '
        '$product, description: '
        '$description, purchaseDate: $purchaseDate, '
        'expiresDate: $expiresDate, purchaseSource: '
        '$purchaseSource, receiptId: $receiptId, '
        'localizedPrice: $localizedPrice, '
        'userId: $userId, '
        'marketplace: $marketplace ';
  }
}
