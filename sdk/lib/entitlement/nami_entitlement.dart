import 'package:nami_flutter/billing/nami_purchase.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';

/// This object represents what features a device has access to in an app.
class NamiEntitlement {
  /// Friendly name of entitlement
  final String? name;

  /// Description of entitlement
  final String? description;

  /// The unique ID of the entitlement defined in the Nami Control Center, use
  /// this to refer to the system when referencing an entitlement.
  final String referenceId;

  /// The list of possible [NamiSKU] that would unlock this entitlement
  final List<NamiSKU> relatedSKUs;

  /// The list of [NamiSKU] purchased by the user that actually unlock this entitlement
  final List<NamiSKU> purchasedSKUs;

  /// The last known Purchases that unlocked this entitlement. There must be a
  /// corresponding [NamiSKU] associated to this [NamiPurchase].
  /// That [NamiSKU] must reside in [purchasedSKUs].
  final List<NamiPurchase> activePurchases;

  NamiEntitlement(this.name, this.description, this.referenceId,
      this.relatedSKUs, this.purchasedSKUs, this.activePurchases);

  /// Return [true] if there is at least one purchase that unlocked this
  /// entitlement. It's possible the user didn't purchase a SKU on user's
  /// current device platform but they did make a transaction on a different
  /// device platform. To enable the entitlement under this context,
  /// [activePurchases] will have at least one item to activate the entitlement.
  bool isActive() {
    return purchasedSKUs.isNotEmpty || activePurchases.isNotEmpty;
  }

  factory NamiEntitlement.fromMap(Map<dynamic, dynamic> map) {
    List<dynamic> dynamicRelatedSkus = map['relatedSKUs'];
    List<NamiSKU> relatedSkus = List.empty(growable: true);
    dynamicRelatedSkus.forEach((element) {
      NamiSKU namiSKU = NamiSKU.fromMap(element);
      relatedSkus.add(namiSKU);
    });
    List<dynamic> dynamicPurchasedSkus = map['purchasedSKUs'];
    List<NamiSKU> purchasedSkus = List.empty(growable: true);
    dynamicPurchasedSkus.forEach((element) {
      NamiSKU namiSKU = NamiSKU.fromMap(element);
      purchasedSkus.add(namiSKU);
    });
    List<dynamic> dynamicActivePurchases = map['activePurchases'];
    List<NamiPurchase> activePurchases = List.empty(growable: true);
    dynamicActivePurchases.forEach((element) {
      NamiPurchase namiPurchase = NamiPurchase.fromMap(element);
      activePurchases.add(namiPurchase);
    });
    return NamiEntitlement(map['name'], map['description'], map['namiId'],
        map['referenceId'], relatedSkus, purchasedSkus, activePurchases);
  }

  @override
  String toString() {
    return 'NamiEntitlement{name: $name, description: $description, '
        'referenceId: $referenceId, relatedSKUs: $relatedSKUs,'
        'purchasedSKUs: $purchasedSKUs, activePurchases: $activePurchases}';
  }
}
