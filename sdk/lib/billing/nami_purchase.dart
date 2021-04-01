/// This object represents a completed purchase in the SDK. A device purchases
/// a NamiSKU and that purchase makes available a set of NamiEntitlements
class NamiPurchase {
  /// The date and time when the purchase was initiated
  final int purchaseInitiatedTimestamp;

  /// For bypass store purchases only, indicates when this purchase will cease
  /// to back an entitlement rendering it as inactive.
  final DateTime? expires;

  /// The source a purchase comes from - either externally, through Nami,
  /// or from your own paywall.
  final NamiPurchaseSource purchaseSource;

  /// True if paywall used to make this purchase was launched by Nami
  final bool fromNami;

  /// The unique identifier for this NamiPurchase
  final String skuId;

  /// The purchase order ID record associated to this purchase
  final String? transactionIdentifier;

  /// A human-readable description of the contents of this purchase
  final String? localizedDescription;

  NamiPurchase(
      this.purchaseInitiatedTimestamp,
      this.expires,
      this.purchaseSource,
      this.fromNami,
      this.skuId,
      this.transactionIdentifier,
      this.localizedDescription);

  factory NamiPurchase.fromMap(Map<dynamic, dynamic> map) {
    int? expiryInt = map['expires'];
    DateTime? expiry;
    if (expiryInt != null && expiryInt > 0) {
      expiry = DateTime.fromMillisecondsSinceEpoch(expiryInt, isUtc: false);
    }
    return NamiPurchase(
        map['purchaseInitiatedTimestamp'],
        expiry,
        (map['purchaseSource'] as String)._toNamiPurchaseSource(),
        map['fromNami'],
        map['skuId'],
        map['transactionIdentifier'],
        map['localizedDescription']);
  }

  @override
  String toString() {
    return 'NamiPurchase{purchaseInitiatedTimestamp: '
        '$purchaseInitiatedTimestamp, expires: $expires, purchaseSource: '
        '$purchaseSource, fromNami: $fromNami, skuId: $skuId, '
        'transactionIdentifier: $transactionIdentifier, localizedDescription: '
        '$localizedDescription}';
  }
}

/// The source a purchase comes from - either externally, through nami,
/// or from your own paywall.
enum NamiPurchaseSource { external, nami_paywall, application, unknown }

extension on String {
  NamiPurchaseSource _toNamiPurchaseSource() {
    if (this == "external") {
      return NamiPurchaseSource.external;
    } else if (this == "nami_paywall") {
      return NamiPurchaseSource.nami_paywall;
    } else if (this == "application") {
      return NamiPurchaseSource.application;
    } else {
      return NamiPurchaseSource.unknown;
    }
  }
}
