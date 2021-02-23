import 'package:nami_flutter/paywall/formatted_sku.dart';

import 'paywall_style_data.dart';

class NamiPaywall {
  final String id;
  final String developerPaywallId;
  final bool allowClosing;
  final String backgroundImageUrlPhone;
  final String backgroundImageUrlTablet;
  final String name;
  final String title;
  final String body;
  final String purchaseTerms;
  final String privacyPolicy;
  final String tosLink;
  final bool restoreControl;
  final bool signInControl;
  final String type;
  final Map<dynamic, dynamic> extraData;
  final PaywallStyleData styleData;

  // formattedSku list associated with this paywall if any
  final List<FormattedSku> formattedSkus;
  final bool useBottomOverlay;

  NamiPaywall(
      this.id,
      this.developerPaywallId,
      this.allowClosing,
      this.backgroundImageUrlPhone,
      this.backgroundImageUrlTablet,
      this.name,
      this.title,
      this.body,
      this.purchaseTerms,
      this.privacyPolicy,
      this.tosLink,
      this.restoreControl,
      this.signInControl,
      this.type,
      this.extraData,
      this.styleData,
      this.formattedSkus,
      this.useBottomOverlay);

  factory NamiPaywall.fromMap(Map<dynamic, dynamic> map) {
    List<dynamic> dynamicFormattedSkus = map['formattedSkus'];
    List<FormattedSku> formattedSkus = List();
    dynamicFormattedSkus.forEach((element) {
      FormattedSku formattedSku = FormattedSku.fromMap(element);
      formattedSkus.add(formattedSku);
    });
    return NamiPaywall(
        map['id'],
        map['developerPaywallId'],
        map['allowClosing'],
        map['backgroundImageUrlPhone'],
        map['backgroundImageUrlTablet'],
        map['name'],
        map['title'],
        map['body'],
        map['purchaseTerms'],
        map['privacyPolicy'],
        map['tosLink'],
        map['restoreControl'],
        map['signInControl'],
        map['type'],
        map['extraData'],
        PaywallStyleData.fromMap(map['styleData']),
        formattedSkus,
        map['useBottomOverlay']);
  }

  @override
  String toString() {
    return 'NamiPaywall{id: $id, developerPaywallId: $developerPaywallId, allowClosing: $allowClosing, backgroundImageUrlPhone: $backgroundImageUrlPhone, backgroundImageUrlTablet: $backgroundImageUrlTablet, name: $name, title: $title, body: $body, purchaseTerms: $purchaseTerms, privacyPolicy: $privacyPolicy, tosLink: $tosLink, restoreControl: $restoreControl, signInControl: $signInControl, type: $type, extraData: $extraData, styleData: $styleData, formattedSkus: $formattedSkus, useBottomOverlay: $useBottomOverlay}';
  }
}
