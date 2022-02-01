import 'package:nami_flutter/paywall/legal_citations.dart';
import 'package:nami_flutter/paywall/nami_locale_config.dart';
import 'package:nami_flutter/paywall/paywall_display_options.dart';

import 'paywall_style_data.dart';

class NamiPaywall {
  final String id;
  final String? developerPaywallId;

  final String? backgroundImageUrlPhone;
  final String? backgroundImageUrlTablet;
  final String? name;
  final String? title;
  final String? body;
  final LegalCitations? legalCitations;
  final PaywallDisplayOptions displayOptions;
  final String? purchaseTerms;
  final String type;
  final Map<dynamic, dynamic>? extraData;
  final PaywallStyleData? styleData;
  final List<String> namiSkus;
  final NamiLocaleConfig localeConfig;

  NamiPaywall(
      this.id,
      this.developerPaywallId,
      this.backgroundImageUrlPhone,
      this.backgroundImageUrlTablet,
      this.name,
      this.title,
      this.body,
      this.legalCitations,
      this.displayOptions,
      this.purchaseTerms,
      this.type,
      this.extraData,
      this.styleData,
      this.namiSkus,
      this.localeConfig);

  factory NamiPaywall.fromMap(Map<dynamic, dynamic?> map) {
    List<dynamic> dynamicSkus = map['namiSkus'];
    List<String> namiSkus = List.empty(growable: true);
    dynamicSkus.forEach((element) {
      namiSkus.add(element.toString());
    });

    dynamic? styleDataMap = map['styleData'];
    PaywallStyleData? styleData;
    if (styleDataMap != null) {
      styleData = PaywallStyleData.fromMap(styleDataMap);
    }
    dynamic? legalCitationsMap = map['legalCitations'];
    LegalCitations? legalCitation;
    if (legalCitationsMap != null) {
      legalCitation = LegalCitations.fromMap(legalCitationsMap);
    }
    dynamic? displayOptionsMap = map['displayOptions'];
    PaywallDisplayOptions displayOptions =
        PaywallDisplayOptions.fromMap(displayOptionsMap);
    dynamic? localeConfigMap = map['localeConfig'];
    NamiLocaleConfig localeConfig = NamiLocaleConfig.fromMap(localeConfigMap);
    return NamiPaywall(
        map['id'],
        map['developerPaywallId'],
        map['backgroundImageUrlPhone'],
        map['backgroundImageUrlTablet'],
        map['name'],
        map['title'],
        map['body'],
        legalCitation,
        displayOptions,
        map['purchaseTerms'],
        map['type'],
        map['extraData'],
        styleData,
        namiSkus,
        localeConfig);
  }
}
