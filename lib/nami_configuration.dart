import 'package:nami_flutter/nami.dart';

class NamiConfiguration {
  final String appPlatformIDApple;
  final String appPlatformIDGoogle;
  final bool bypassStore;
  final NamiLogLevel namiLogLevel;
  final List<String> extraData;

  const NamiConfiguration(this.appPlatformIDApple,
      this.appPlatformIDGoogle,
      [this.bypassStore = false,
      this.namiLogLevel = NamiLogLevel.warn,
      this.extraData]);
}
