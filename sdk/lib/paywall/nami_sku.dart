/// This object represents a specific in-app purchase SKU available on a
/// specific platform.
class NamiSKU {
  /// name of the product as set in the Nami Control Center
  final String? name;

  /// The type of SKU.  Will tell you if it is a subscription or one-time
  /// purchase
  final NamiSKUType type;

  /// The store platform reference ID of the SKU
  final String skuId;

  NamiSKU(this.name, this.skuId, this.type);

  factory NamiSKU.fromMap(Map<dynamic, dynamic> map) {
    return NamiSKU((map['name'] as String?) ?? "", map['skuId'],
        (map['type'] as String?)._toNamiSKUType());
  }

  @override
  String toString() {
    return 'NamiSKU{name: $name, skuId: $skuId, type: $type}';
  }
}

/// The time period for the unit of purchase
enum PeriodUnit { not_used, day, weekly, monthly, quarterly, half_year, annual }

enum NamiSKUType { one_time_purchase, subscription, unknown }

extension on String? {
  NamiSKUType _toNamiSKUType() {
    if (this == "one_time_purchase") {
      return NamiSKUType.one_time_purchase;
    } else if (this == "subscription") {
      return NamiSKUType.subscription;
    } else {
      return NamiSKUType.unknown;
    }
  }

  PeriodUnit _toPeriodUnit() {
    if (this == "day") {
      return PeriodUnit.day;
    } else if (this == "week") {
      return PeriodUnit.weekly;
    } else if (this == "month") {
      return PeriodUnit.monthly;
    } else if (this == "year") {
      return PeriodUnit.annual;
    } else if (this == "quarter") {
      return PeriodUnit.quarterly;
    } else if (this == "half_year") {
      return PeriodUnit.half_year;
    } else {
      return PeriodUnit.not_used;
    }
  }
}
