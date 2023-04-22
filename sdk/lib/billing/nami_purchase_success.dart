import 'package:nami_flutter/paywall/nami_sku.dart';
import 'package:nami_flutter/billing/nami_purchase.dart';

/// This object represents a successful purchase processed by your own
/// in-app billing code. For use with paywall-only plans
class NamiPurchaseSuccess {
  final NamiSKU product;

  /// A description of the purchase
  final String? description;

  /// The date of the purchase
  final String purchaseDate;

  /// The expiration date of the purchase, for subscriptions, if known
  final String? expiresDate;

  /// The source a purchase comes from - either externally, through Nami,
  /// or from your own paywall.
  final NamiPurchaseSource purchaseSource;

  NamiPurchaseSuccess(this.product, this.description, this.purchaseDate,
      this.expiresDate, this.purchaseSource);
}
