import 'dart:async';
import 'package:flutter/material.dart';

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

Future<Widget> initializeApp(AppConfig appConfig) async {
  WidgetsFlutterBinding.ensureInitialized();
  return MaterialApp(home: TestNamiFlutterApp(appConfig));
}

class TestNamiFlutterApp extends StatefulWidget {
  final AppConfig appConfig;
  const TestNamiFlutterApp(this.appConfig);

  @override
  TestNamiFlutterAppState createState() => TestNamiFlutterAppState();
}

class TestNamiFlutterAppState extends State<TestNamiFlutterApp>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: this.widget.appConfig.environment == Environment.staging
            ? namiPrimaryBlue
            : namiYellow,
      ),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              indicatorColor: namiWhite,
              indicatorWeight: 6,
              tabs: [
                Tab(icon: Icon(Icons.rocket_launch)),
                Tab(icon: Icon(Icons.person)),
                Tab(icon: Icon(Icons.diamond)),
              ],
            ),
            centerTitle: true,
            backgroundColor:
                this.widget.appConfig.environment == Environment.staging
                    ? namiPrimaryBlue
                    : namiYellow,
            title: SizedBox(
                height: 24, child: Image.asset("images/nami_logo_white.png")),
          ),
          body: TabBarView(
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    var iosAppPlatformId = productionIosAppPlatformId;
    var androidAppPlatformId = productionAndroidAppPlatformId;
    var extraData = null;

    if (this.widget.appConfig.environment == Environment.staging) {
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
}
