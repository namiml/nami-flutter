import 'package:flutter/services.dart';
import 'package:nami_flutter/campaign/nami_campaign.dart';

import '../channel.dart';

/// Manager class which providing functionality related to displaying a paywall
/// by launching a campaign
class NamiCampaignManager {
  /// Launch a campaign to raise a paywall
  ///
  /// Optionally you can provide,
  /// - A [label] to identify a specific campaign
  static Future<LaunchCampaignResult> launch({String? label}) async {
    var variableMap = {
      "label": label,
    };
    Map<dynamic, dynamic> result = await channel.invokeMethod("launch", variableMap);

    var error = (result['error'] as String?)._toLaunchCampaignError();
    return LaunchCampaignResult(result['success'], error);
  }

  static Future<List<NamiCampaign>> allCampaigns() async {
    List<dynamic> list = await channel.invokeMethod("allCampaigns");
    return list.map((e) => NamiCampaign.fromMap(e)).toList();
  }

  static const EventChannel _campaignsEvent = const EventChannel('campaignsEvent');

  static Stream<List<NamiCampaign>> registerAvailableCampaignsHandler() {
    var data =
        _campaignsEvent.receiveBroadcastStream().map((event) => _mapToNamiCampaignList(event));

    return data;
  }

  static List<NamiCampaign> _mapToNamiCampaignList(List<dynamic> list) {
    return list.map((element) {
      return NamiCampaign.fromMap(element);
    }).toList();
  }
}

enum LaunchCampaignError {
  /// SDK must be initialized via [Nami.configure] before launching a campaign
  SDK_NOT_INITIALIZED,

  /// No live default campaign could be launched.
  DEFAULT_CAMPAIGN_NOT_FOUND,

  /// No live campaign could be launched for the requested label.
  LABELED_CAMPAIGN_NOT_FOUND,

  /// Cannot launch a campaign, because a paywall is currently on screen
  PAYWALL_ALREADY_DISPLAYED,

  /// No campaign found
  CAMPAIGN_DATA_NOT_FOUND
}

class LaunchCampaignResult {
  final bool success;
  final LaunchCampaignError? error;

  LaunchCampaignResult(this.success, this.error);
}

extension on String? {
  LaunchCampaignError? _toLaunchCampaignError() {
    if (this == "sdk_not_initialized") {
      return LaunchCampaignError.SDK_NOT_INITIALIZED;
    } else if (this == "default_campaign_not_found") {
      return LaunchCampaignError.DEFAULT_CAMPAIGN_NOT_FOUND;
    } else if (this == "labeled_campaign_not_found") {
      return LaunchCampaignError.LABELED_CAMPAIGN_NOT_FOUND;
    } else if (this == "campaign_data_not_found") {
      return LaunchCampaignError.CAMPAIGN_DATA_NOT_FOUND;
    } else if (this == "paywall_already_displayed") {
      return LaunchCampaignError.PAYWALL_ALREADY_DISPLAYED;
    } else if (this == "sdk_not_initialized") {
      return LaunchCampaignError.CAMPAIGN_DATA_NOT_FOUND;
    } else {
      return null;
    }
  }
}
