/// This object represents a completed purchase in the SDK.
class NamiPurchase {
  /// The date and time when the purchase was initiated
  final int purchaseInitiatedTimestamp;


  /// The unique identifier for this NamiPurchase
  final String skuId;

  /// The purchase order ID record associated to this purchase
  final String? transactionIdentifier;

  /// A human-readable description of the contents of this purchase
  final String? localizedDescription;

  NamiPurchase(this.purchaseInitiatedTimestamp, this.skuId,
      this.transactionIdentifier, this.localizedDescription);

  factory NamiPurchase.fromMap(Map<dynamic, dynamic> map) {
    return NamiPurchase(
        map['purchaseInitiatedTimestamp'],
        map['skuId'],
        map['transactionIdentifier'],
        map['localizedDescription']);
  }

  @override
  String toString() {
    return 'NamiPurchase{purchaseInitiatedTimestamp: '
        '$purchaseInitiatedTimestamp, skuId: $skuId, '
        'transactionIdentifier: $transactionIdentifier, localizedDescription: '
        '$localizedDescription}';
  }
}


