import 'dart:async';

import 'package:flutter/services.dart';

class NamiPaywallManager {
  static const MethodChannel _methodChannel = const MethodChannel('nami');
  static Future<bool> canRaisePaywall() {
    return _methodChannel.invokeMethod("canRaisePaywall");
  }
  static Future<bool> raisePaywall() {
    return _methodChannel.invokeMethod("raisePaywall");
  }
}