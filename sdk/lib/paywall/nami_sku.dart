/// This object represents a specific in-app purchase SKU available on a
/// specific platform.
class NamiSKU {
  /// description of the product
  final String description;

  /// title of the product
  final String title;

  /// The type of SKU.  Will tell you if it is a subscription or one-time
  /// purchase
  final NamiSKUType type;

  /// iOS only
  ///
  /// If a product has multiple units, this will be the total price the user
  /// pays, calculated by taking the per unit price and multiplying by the
  /// number of periods. Localization adds the correct currency symbol. An
  /// example would be a weekly rate of $6.93 that comes from 7 units of
  /// $0.99 per day.
  final String? localizedMultipliedPrice;

  /// Price for the user's store locale as a decimal value
  final String price;

  /// iOS only
  ///
  /// For subscription products, the identifier for the subscription group
  final String? subscriptionGroupIdentifier;

  /// The ID of the SKU, which will match what you set in the Control Center
  final String skuId;

  /// Formatted price of the item, including its currency sign
  final String localizedPrice;

  /// The number of times this product will occur in a single purchase term
  final int numberOfUnits;

  /// iOS only
  ///
  /// Language and region code for the product from the user's store
  final String? priceLanguage;

  /// currency code for price
  final String priceCurrency;

  /// iOS only
  ///
  /// Country code for the user's store
  final String? priceCountry;

  /// The time period for the unit of purchase
  final PeriodUnit periodUnit;
  final bool featured;

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
      this.periodUnit,
      this.featured);

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
        (map['periodUnit'] as String?)._toPeriodUnit(),
        map['featured']);
  }

  @override
  String toString() {
    return 'NamiSKU{description: $description, title: $title, type: $type, '
        'localizedMultipliedPrice: $localizedMultipliedPrice, price: $price, '
        'subscriptionGroupIdentifier: $subscriptionGroupIdentifier, '
        'skuId: $skuId, localizedPrice: $localizedPrice, '
        'numberOfUnits: $numberOfUnits, priceLanguage: $priceLanguage, '
        'priceCurrency: $priceCurrency, priceCountry: $priceCountry, '
        'periodUnit: $periodUnit, featured: $featured}';
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
