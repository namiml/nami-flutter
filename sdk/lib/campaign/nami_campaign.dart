import 'dart:core';

/**
 * This object represents the campaign in Nami.
 */
class NamiCampaign {
  final String paywall;
  final String segment;
  final NamiCampaignRuleType type;
  final String? value;

  NamiCampaign(this.paywall, this.segment, this.type, this.value);

  factory NamiCampaign.fromMap(Map<dynamic, dynamic> map) {
    return NamiCampaign(
        map['paywall'], map['segment'], (map['type'] as String?).toNamiCampaignRuleType(), map['value']);
  }
}

enum NamiCampaignRuleType { DEFAULT, LABEL }

extension on String? {
  NamiCampaignRuleType toNamiCampaignRuleType() {
    if (this == "DEFAULT") {
      return NamiCampaignRuleType.DEFAULT;
    } else if (this == "default_campaign_not_found") {
      return NamiCampaignRuleType.LABEL;
    } else {
      return NamiCampaignRuleType.DEFAULT;
    }
  }
}
