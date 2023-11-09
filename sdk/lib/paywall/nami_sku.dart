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

  final String? id;

  NamiSKU(this.name, this.skuId, this.type, this.id);

  factory NamiSKU.fromMap(Map<dynamic, dynamic> map) {
    return NamiSKU((map['name'] as String?) ?? "", map['skuId'],
        (map['type'] as String?)._toNamiSKUType(), map['id']);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      "name": name,
      "skuId": skuId,
      'type': type._toNamiSKUTypeName(),
      'id': id
    };
  }

  @override
  String toString() {
    return 'NamiSKU{name: $name, skuId: $skuId, type: $type,id: $id}';
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
}

extension on NamiSKUType? {
  String _toNamiSKUTypeName() {
    if (this == NamiSKUType.one_time_purchase) {
      return "one_time_purchase";
    } else if (this == NamiSKUType.subscription) {
      return "subscription";
    } else {
      return "unknown";
    }
  }
}
