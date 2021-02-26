import 'nami_log_level.dart';

class NamiConfiguration {
  /// A UUID for the Apple app. You can find the Nami App Platform ID in the App
  /// Settings screen on the Platforms tab in the Nami Control Center.
  final String appPlatformIDApple;

  /// A UUID for the Android app. You can find the Nami App Platform ID in the
  /// App Settings screen on the Platforms tab in the Nami Control Center.
  final String appPlatformIDGoogle;

  bool bypassStore = false;

  /// A flag to define whether app is in development mode or not. An enabled
  /// Development mode sets the SDK to prioritize SDK tasks and display some
  /// error messages in your app to assist in setting up Nami and in-app
  /// purchases.
  ///
  /// Default is set to [false]. Note that this should be set to [true] only
  /// from [debug] or [non-production] version of the app. Setting this to
  /// [true] in a [production] build can potentially have unwanted consequences.
  bool developmentMode = false;
  bool passiveMode = false;

  /// Optional preferable [NamiLogLevel] to set within SDK to get appropriate
  /// logging information. Make sure to either not set this param in release
  /// build, or set to [NamiLogLevel.error] if you would like Nami error logs
  /// to be shown in your release/production app build. Default is set
  /// to [NamiLogLevel.warn]
  NamiLogLevel namiLogLevel = NamiLogLevel.warn;
  final List<String> extraData = List.empty(growable: true);

  NamiConfiguration(this.appPlatformIDApple, this.appPlatformIDGoogle);
}
