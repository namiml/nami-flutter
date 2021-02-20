/// This object represents a specific in-app purchase SKU available on a
/// specific platform.
class NamiSKU {
  final String description;
  final String title;
  final NamiSKUType type;

  // iOS only
  final String localizedMultipliedPrice;
  final String price;

  // iOS only
  final String subscriptionGroupIdentifier;
  final String skuId;
  final String localizedPrice;
  final int numberOfUnits;

  // iOS only
  final String priceLanguage;
  final String priceCurrency;

  // iOS only
  final String priceCountry;
  final PeriodUnit periodUnit;

  NamiSKU(
      this.description,
      this.title,
      this.type,
      this.localizedMultipliedPrice,
      this.price,
      this.subscriptionGroupIdentifier,
      this.skuId,
      this.localizedPrice,
      this.numberOfUnits,
      this.priceLanguage,
      this.priceCurrency,
      this.priceCountry,
      this.periodUnit);

  factory NamiSKU.fromMap(Map<dynamic, dynamic> map) {
    return NamiSKU(
        map['description'],
        map['title'],
        (map['type'] as String)._toNamiSKUType(),
        map['localizedMultipliedPrice'],
        map['price'],
        map['subscriptionGroupIdentifier'],
        map['skuId'],
        map['localizedPrice'],
        map['numberOfUnits'],
        map['priceLanguage'],
        map['priceCurrency'],
        map['priceCountry'],
        (map['periodUnit'] as String)._toPeriodUnit());
  }

  @override
  String toString() {
    return 'NamiSKU{description: $description, title: $title, type: $type, localizedMultipliedPrice: $localizedMultipliedPrice, price: $price, subscriptionGroupIdentifier: $subscriptionGroupIdentifier, skuId: $skuId, localizedPrice: $localizedPrice, numberOfUnits: $numberOfUnits, priceLanguage: $priceLanguage, priceCurrency: $priceCurrency, priceCountry: $priceCountry, periodUnit: $periodUnit}';
  }
}

enum PeriodUnit { not_used, day, weekly, monthly, quarterly, half_year, annual }

enum NamiSKUType { one_time_purchase, subscription, unknown }

extension on String {
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
