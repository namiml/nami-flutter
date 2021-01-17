import 'dart:async';
import 'dart:ffi';

import 'package:flutter/services.dart';
import 'package:nami_flutter/nami_configuration.dart';

/**
 * This class is the main entry point of the SDK.
 */
class Nami {
  static const MethodChannel _methodChannel = const MethodChannel('nami');
  static const EventChannel _signInEvent = const EventChannel('signInEvent');

  static Future<bool> configure(NamiConfiguration namiConfiguration) {
    var extraDataList = ["extendedClientInfo:flutter:0.0.1"];
    extraDataList.addAll(namiConfiguration.extraData);
    var variableMap = {
      'appPlatformIDApple': namiConfiguration.appPlatformIDApple,
      "appPlatformIDGoogle": namiConfiguration.appPlatformIDGoogle,
      "bypassStore": namiConfiguration.bypassStore,
      "namiLogLevel": namiConfiguration.namiLogLevel.index,
      "extraDataList": extraDataList
    };
    return _methodChannel.invokeMethod("configure", variableMap);
  }

  static Future<Void> setExternalIdentifier(
      String externalIdentifier, NamiExternalIdentifierType type) async {
    var variableMap = {'externalIdentifier': externalIdentifier, "type": type.index};
    return await _methodChannel.invokeMethod(
        "setExternalIdentifier", variableMap);
  }

  static Future<String> getExternalIdentifier() {
    return _methodChannel.invokeMethod("getExternalIdentifier");
  }

  static Future<Void> clearExternalIdentifier() {
    return _methodChannel.invokeMethod("clearExternalIdentifier");
  }

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

enum NamiExternalIdentifierType { sha256, uuid }

enum NamiLogLevel { error, warn, info, debug }
