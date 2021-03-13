/// The NamiEntitlementSetter object is created by the client app developer to
/// inform the Nami SDK of a known off-platform entitlement / purchase
class NamiEntitlementSetter {
  /// The reference ID of the entitlement.
  final String referenceId;

  /// Indicator as to which platform the backing purchase was made on.
  final NamiPlatformType platform;

  /// The skuID of the backing purchase
  final String? purchasedSKUid;

  /// Indicates when will this entitlement expire. Null if expiration date is not known or navailable.
  final DateTime? expires;

  NamiEntitlementSetter(
      {required this.referenceId,
      this.platform = NamiPlatformType.other,
      this.purchasedSKUid,
      this.expires});
}

/// Platforms that may own a purchased SKU that grants an entitlement
enum NamiPlatformType { other, android, apple, roku, web }
