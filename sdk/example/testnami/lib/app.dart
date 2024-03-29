import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nami_flutter/campaign/nami_campaign_manager.dart';

// Test Nami Flutter app code
import 'package:testnami/app_config.dart';
import 'package:testnami/constants.dart';
import 'package:testnami/campaign.dart';
import 'package:testnami/profile.dart';
import 'package:testnami/entitlements.dart';

// Nami Flutter SDK
import 'package:nami_flutter/nami.dart';
import 'package:nami_flutter/nami_configuration.dart';
import 'package:nami_flutter/nami_log_level.dart';
import 'package:uni_links/uni_links.dart';

Future<Widget> initializeApp(AppConfig appConfig) async {
  WidgetsFlutterBinding.ensureInitialized();
  return MaterialApp(home: TestNamiFlutterApp(appConfig));
}

class TestNamiFlutterApp extends StatefulWidget {
  final AppConfig appConfig;

  const TestNamiFlutterApp(this.appConfig, {super.key});

  @override
  TestNamiFlutterAppState createState() => TestNamiFlutterAppState();
}

class TestNamiFlutterAppState extends State<TestNamiFlutterApp>
    with WidgetsBindingObserver {
  StreamSubscription? _subscription;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: widget.appConfig.environment == Environment.staging
            ? namiPrimaryBlue
            : namiYellow,
      ),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              indicatorColor: namiWhite,
              indicatorWeight: 6,
              tabs: [
                Tab(icon: Icon(Icons.rocket_launch)),
                Tab(icon: Icon(Icons.person)),
                Tab(icon: Icon(Icons.diamond)),
              ],
            ),
            centerTitle: true,
            backgroundColor: widget.appConfig.environment == Environment.staging
                ? namiPrimaryBlue
                : namiYellow,
            title: SizedBox(
                height: 24, child: Image.asset("images/nami_logo_white.png")),
          ),
          body: const TabBarView(
            children: [
              CampaignWidget(),
              ProfileWidget(),
              EntitlementsWidget(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();
    _getInitialUrl();
    _handleUrlStream();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    var iosAppPlatformId = productionIosAppPlatformId;
    var androidAppPlatformId = productionAndroidAppPlatformId;
    List<String> extraData = [];

    if (widget.appConfig.environment == Environment.staging) {
      iosAppPlatformId = stagingIosAppPlatformId;
      androidAppPlatformId = stagingAndroidAppPlatformId;
      extraData = ["useStagingAPI"];
    }

    var namiConfiguration = NamiConfiguration(
        appPlatformIdApple: iosAppPlatformId,
        appPlatformIdAndroid: androidAppPlatformId,
        namiLogLevel: NamiLogLevel.debug,
        extraData: extraData);
    Nami.configure(namiConfiguration);
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  Future<void> _getInitialUrl() async {
    try {
      final initialLink = await getInitialLink();
      await _launchUrl(initialLink);
    } on PlatformException {
      // Handle the exception flow
    }
  }

  Future<void> _handleUrlStream() async {
    _subscription =
        linkStream.listen((String? url) => _launchUrl, onError: (error) {
      // Handle exception by warning the user their action did not succeed
    });
  }

  Future<void> _launchUrl(String? url) async {
    if (!mounted) return;
    if (url != null) {
      if (await NamiCampaignManager.isCampaignAvailable(url: url)) {
        LaunchCampaignResult result = await NamiCampaignManager.launch(
            url: url,
            onPaywallAction: (payWallEvent) {
              print(payWallEvent.toString());
            });
        if (result.success) {
          print("Campaign launched successfully");
        } else {
          print("Campaign launched failed");
        }
      } else {
        print("Campaign is not available on this device.");
      }
    }
  }
}
