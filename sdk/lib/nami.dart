import 'dart:async';

import 'package:flutter/foundation.dart';

import 'channel.dart';
import 'nami_configuration.dart';

/// This class is the main entry point of the SDK.
class Nami {
  /// This method configures and initializes the SDK. This method must be
  /// called as the first thing before interacting with the SDK.
  static Future<bool> configure(NamiConfiguration namiConfiguration) {
    var extraDataList = ["extendedClientInfo:flutter:3.1.0"];
    extraDataList.addAll(namiConfiguration.extraData ?? []);
    var variableMap = {
      'appPlatformIdApple': namiConfiguration.appPlatformIdApple,
      "appPlatformIdAndroid": namiConfiguration.appPlatformIdAndroid,
      "namiLogLevel": describeEnum(namiConfiguration.namiLogLevel),
      "extraDataList": extraDataList
    };
    return channel
        .invokeMethod<bool>("configure", variableMap)
        .then<bool>((bool? value) => value ?? false);
  }
}
