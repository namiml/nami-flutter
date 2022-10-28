/// This object represents a completed purchase in the SDK.
class NamiPurchase {
  /// The date and time when the purchase was initiated
  final int purchaseInitiatedTimestamp;

  /// The source a purchase comes from - either externally, through Nami,
  /// or from your own paywall.
  final NamiPurchaseSource purchaseSource;

  /// The unique identifier for this NamiPurchase
  final String skuId;

  /// The purchase order ID record associated to this purchase
  final String? transactionIdentifier;

  /// A human-readable description of the contents of this purchase
  final String? localizedDescription;

  NamiPurchase(this.purchaseInitiatedTimestamp, this.purchaseSource, this.skuId,
      this.transactionIdentifier, this.localizedDescription);

  factory NamiPurchase.fromMap(Map<dynamic, dynamic> map) {
    return NamiPurchase(
        map['purchaseInitiatedTimestamp'],
        (map['purchaseSource'] as String)._toNamiPurchaseSource(),
        map['skuId'],
        map['transactionIdentifier'],
        map['localizedDescription']);
  }

  @override
  String toString() {
    return 'NamiPurchase{purchaseInitiatedTimestamp: '
        '$purchaseInitiatedTimestamp, purchaseSource: '
        '$purchaseSource, skuId: $skuId, '
        'transactionIdentifier: $transactionIdentifier, localizedDescription: '
        '$localizedDescription}';
  }
}

/// The source a purchase comes from - either a campaign, through nami,
/// or externally via the app marketplace..
enum NamiPurchaseSource { campaign, marketplace, unknown }

extension on String {
  NamiPurchaseSource _toNamiPurchaseSource() {
    if (this == "campaign") {
      return NamiPurchaseSource.campaign;
    } else if (this == "marketplace") {
      return NamiPurchaseSource.marketplace;
    } else {
      return NamiPurchaseSource.unknown;
    }
  }
}
