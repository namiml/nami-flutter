import 'dart:async';

import 'package:flutter/services.dart';

import '../channel.dart';

/// Class responsible for managing all aspects of a paywall in the Nami SDK
class NamiPaywallManager {
  static const EventChannel _signInEvent = const EventChannel('signInEvent');
  /// Checks to see if the Nami system can raise a paywall.  A paywall raise
  /// may not be possible due to missing configuration data or paywall is
  /// blocked from raising
  static Future<bool> canRaisePaywall() {
    return channel.invokeMethod("canRaisePaywall");
  }

  /// Displays the current live paywall in the app
  static Future<bool> raisePaywall() {
    return channel.invokeMethod("raisePaywall");
  }

  /// Stream for when user presses sign in button on a paywall raised by
  /// Nami system
  static Stream<Map<dynamic, dynamic>> signInEvents() {
    var data = _signInEvent
        .receiveBroadcastStream()
        .map((dynamic event) => _handleSignInClicked(event));

    return data;
  }

  static Map<dynamic, dynamic> _handleSignInClicked(Map<dynamic, dynamic> map) {
    return map;
  }
}
