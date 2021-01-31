import 'dart:async';
import 'channel.dart';
import 'nami_configuration.dart';

/// This class is the main entry point of the SDK.
class Nami {
  /// This method configures and initializes the SDK. This method must be
  /// called as the first thing before interacting with the SDK.
  static Future<bool> configure(NamiConfiguration namiConfiguration) {
    var extraDataList = ["extendedClientInfo:flutter:0.0.1"];
    extraDataList.addAll(namiConfiguration.extraData);
    var variableMap = {
      'appPlatformIDApple': namiConfiguration.appPlatformIDApple,
      "appPlatformIDGoogle": namiConfiguration.appPlatformIDGoogle,
      "bypassStore": namiConfiguration.bypassStore,
      "developmentMode": namiConfiguration.developmentMode,
      "passiveMode": namiConfiguration.passiveMode,
      "namiLogLevel": namiConfiguration.namiLogLevel.index,
      "extraDataList": extraDataList
    };
    return channel.invokeMethod("configure", variableMap);
  }

  /// Provide a unique identifier that can be used to link different devices
  /// to the same customer in the [Nami] platform. This customer id will also
  /// be returned in any data sent from the [Nami] servers to your systems as well.
  ///
  /// The [ID] sent to Nami must be a valid [UUID] or you may hash any other
  /// identifier with [SHA256] and provide it in this call.
  ///
  /// Note that [Nami] platform will reject the [externalIdentifier], and it
  /// will not get saved in case where [externalIdentifier] value doesn't match
  /// the format expected in the provided [type]. For example, if you provide
  /// a regular string instead of a proper `UUID` formatted string and
  /// use [NamiExternalIdentifierType.uuid] to set the value then it will get
  /// rejected
  static Future<void> setExternalIdentifier(
      String externalIdentifier, NamiExternalIdentifierType type) async {
    var variableMap = {
      'externalIdentifier': externalIdentifier,
      "type": type.index
    };
    return await channel.invokeMethod("setExternalIdentifier", variableMap);
  }

  /// A string of the external identifier that Nami has stored. Returns [null]
  /// if no id has been stored, including if a string was passed to
  /// [setExternalIdentifier] that was not valid.
  static Future<String> getExternalIdentifier() {
    return channel.invokeMethod("getExternalIdentifier");
  }

  /// Clears out any external identifiers set
  static Future<void> clearExternalIdentifier() async {
    return await channel.invokeMethod("clearExternalIdentifier");
  }
}

enum NamiExternalIdentifierType { sha256, uuid }
