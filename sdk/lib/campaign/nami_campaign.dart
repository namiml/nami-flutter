import 'dart:core';

/// This object represents the campaign in Nami.
class NamiCampaign {
  final String paywall;
  final String segment;
  final NamiCampaignRuleType type;
  final String? value;

  NamiCampaign(this.paywall, this.segment, this.type, this.value);

  factory NamiCampaign.fromMap(Map<dynamic, dynamic> map) {
    return NamiCampaign(map['paywall'], map['segment'],
        (map['type'] as String?).toNamiCampaignRuleType(), map['value']);
  }

  @override
  String toString() {
    return "$type - $value";
  }
}

enum NamiCampaignRuleType { DEFAULT, LABEL, URL }

extension on String? {
  NamiCampaignRuleType toNamiCampaignRuleType() {
    if (this == "DEFAULT") {
      return NamiCampaignRuleType.DEFAULT;
    } else if (this == "LABEL") {
      return NamiCampaignRuleType.LABEL;
    } else if (this == "URL") {
      return NamiCampaignRuleType.URL;
    } else {
      return NamiCampaignRuleType.LABEL;
    }
  }
}
