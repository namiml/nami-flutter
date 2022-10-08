import 'nami_log_level.dart';

class NamiConfiguration {
  /// A UUID for the Apple app. You can find the Nami App Platform ID in the App
  /// Settings screen on the Platforms tab in the Nami Control Center.
  final String appPlatformIdApple;

  /// A UUID for the Android app. You can find the Nami App Platform ID in the
  /// App Settings screen on the Platforms tab in the Nami Control Center.
  final String appPlatformIdGoogle;

  final bool bypassStore;

  /// Optional preferable [NamiLogLevel] to set within SDK to get appropriate
  /// logging information. Make sure to either not set this param in release
  /// build, or set to [NamiLogLevel.error] if you would like Nami error logs
  /// to be shown in your release/production app build. Default is set
  /// to [NamiLogLevel.warn]
  final NamiLogLevel namiLogLevel;
  final List<String>? extraData;
  /// sets the language to be used for paywalls on the device
  final String? namiLanguageCode;

  const NamiConfiguration({required this.appPlatformIdApple,
    required this.appPlatformIdGoogle,
    this.bypassStore = false,
    this.namiLogLevel = NamiLogLevel.warn,
    this.extraData,
    this.namiLanguageCode
  });
}
