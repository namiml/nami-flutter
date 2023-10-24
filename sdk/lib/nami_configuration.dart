import 'nami_log_level.dart';

class NamiConfiguration {
  /// A UUID for the Apple app. You can find the Nami App Platform ID in the App
  /// Settings screen on the Platforms tab in the Nami Control Center.
  final String appPlatformIdApple;

  /// A UUID for the Android app. You can find the Nami App Platform ID in the
  /// App Settings screen on the Platforms tab in the Nami Control Center.
  final String appPlatformIdAndroid;

  /// Optional preferable [NamiLogLevel] to set within SDK to get appropriate
  /// logging information. Make sure to either not set this param in release
  /// build, or set to [NamiLogLevel.error] if you would like Nami error logs
  /// to be shown in your release/production app build. Default is set
  /// to [NamiLogLevel.warn]
  final NamiLogLevel namiLogLevel;
  final List<String>? extraData;

  const NamiConfiguration(
      {required this.appPlatformIdApple,
      required this.appPlatformIdAndroid,
      this.namiLogLevel = NamiLogLevel.warn,
      this.extraData});
}
