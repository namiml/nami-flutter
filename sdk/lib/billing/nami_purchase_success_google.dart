import 'package:nami_flutter/paywall/nami_sku.dart';
import 'package:nami_flutter/billing/nami_purchase.dart';
import 'package:nami_flutter/billing/nami_purchase_success.dart';

class NamiPurchaseSuccessGoogle extends NamiPurchaseSuccess {
  final String orderId;

  final String purchaseToken;

  NamiPurchaseSuccessGoogle(
      NamiSKU product,
      String description,
      String purchaseDate,
      String? expiresDate,
      NamiPurchaseSource purchaseSource,
      this.orderId,
      this.purchaseToken)
      : super(product, description, purchaseDate, expiresDate, purchaseSource);

  @override
  String toString() {
    return 'NamiPurchaseSuccessGoogle{product: '
        '$product, description: '
        '$description, purchaseDate: $purchaseDate, '
        'expiresDate: $expiresDate, purchaseSource: '
        '$purchaseSource, orderId: $orderId, '
        'purchaseToken: $purchaseToken ';
  }
}
