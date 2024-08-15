import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nami_flutter/campaign/nami_campaign.dart';
import '../channel.dart';
import 'nami_paywall_event.dart';

/// Manager class which providing functionality related to displaying a paywall
/// by launching a campaign
class NamiCampaignManager {
  // EventChannel(s) to listen for the event from native
  static const EventChannel _campaignsEvent =
      const EventChannel('campaignsEvent');
  static const EventChannel _paywallActionEvent =
      const EventChannel('paywallActionEvent');

  /// Launch a campaign to raise a paywall
  ///
  /// Optionally you can provide,
  /// - A [label] to identify a campaign placement by label
  /// - A [url] to identify a deeplink campaign placement by url
  /// - A [onPaywallAction] callback to listen for the actions triggered on paywall
  static Future<LaunchCampaignResult> launch(
      {String? label,
      String? url,
      Function(NamiPaywallEvent?)? onPaywallAction}) async {
    // Listen for the paywall action event
    _paywallActionEvent.receiveBroadcastStream().listen((event) {
      if (event != null) {
        NamiPaywallEvent paywallEvent = _toNamiPaywallEvent(event);
        onPaywallAction!(paywallEvent);
      }
    });

    var variableMap = {"label": label, "url": url};

    final result = await channel.invokeMethod("launch", variableMap);
    var error = (result['error'] as String?)._toLaunchCampaignError();

    return LaunchCampaignResult(result['success'] ?? false, error);
  }

  static NamiPaywallEvent _toNamiPaywallEvent(Map<dynamic, dynamic> map) {
    return NamiPaywallEvent.fromMap(map);
  }

  static Future<List<NamiCampaign>> allCampaigns() async {
    List<dynamic> list = await channel.invokeMethod("allCampaigns");
    return list.map((e) => NamiCampaign.fromMap(e)).toList();
  }

  static Stream<List<NamiCampaign>> registerAvailableCampaignsHandler() {
    var data = _campaignsEvent
        .receiveBroadcastStream()
        .map((event) => _mapToNamiCampaignList(event));

    return data;
  }

  /// Asks Nami to fetch the latest active campaigns for this device
  /// @return list of active campaigns after updating.
  static Future<List<NamiCampaign>> refresh() async {
    List<dynamic> list = await channel.invokeMethod("campaigns.refresh");
    return list.map((e) => NamiCampaign.fromMap(e)).toList();
  }

  /// Returns true if a campaign is available matching the provided label or default
  /// @param provided label or null if default campaign
  static Future<bool> isCampaignAvailable({String? label, String? url}) async {
    var variableMap = {"label": label, "url": url};
    bool available =
        await channel.invokeMethod("isCampaignAvailable", variableMap);
    return available;
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

enum NamiPaywallAction {
  NAMI_SHOW_PAYWALL,
  NAMI_CLOSE_PAYWALL,
  NAMI_RESTORE_PURCHASES,
  NAMI_SIGN_IN,
  NAMI_BUY_SKU,
  NAMI_SELECT_SKU,
  NAMI_PURCHASE_SELECTED_SKU,
  NAMI_PURCHASE_SUCCESS,
  NAMI_PURCHASE_DEFERRED,
  NAMI_PURCHASE_FAILED,
  NAMI_PURCHASE_CANCELLED,
  NAMI_PURCHASE_PENDING,
  NAMI_PURCHASE_UNKNOWN,
  NAMI_DEEP_LINK,
  NAMI_PAGE_CHANGE,
  NAMI_TOGGLE_CHANGE,
  NAMI_SLIDE_CHANGE,
  NAMI_RELOAD_PRODUCTS,
  NAMI_COLLAPSIBLE_DRAWER_OPEN,
  NAMI_COLLAPSIBLE_DRAWER_CLOSE,
  NAMI_PLAY_VIDEO,
  NAMI_PAUSE_VIDEO,
  NAMI_MUTE_VIDEO,
  NAMI_UNMUTE_VIDEO,
  NAMI_VIDEO_STARTED,
  NAMI_VIDEO_PAUSED,
  NAMI_VIDEO_RESUMED,
  NAMI_VIDEO_ENDED,
  NAMI_VIDEO_CHANGED,
  NAMI_VIDEO_MUTED,
  NAMI_VIDEO_UNMUTED,
  NAMI_UNKNOWN
}
