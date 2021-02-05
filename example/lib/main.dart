import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nami_flutter/analytics/nami_analytics_support.dart';
import 'package:nami_flutter/billing/nami_purchase_manager.dart';
import 'package:nami_flutter/customer/nami_customer_manager.dart';
import 'package:nami_flutter/entitlement/nami_entitlement_manager.dart';
import 'package:nami_flutter/entitlement/nami_entitlement_setter.dart';
import 'package:nami_flutter/ml/nami_ml_manager.dart';
import 'package:nami_flutter/nami.dart';
import 'package:nami_flutter/nami_configuration.dart';
import 'package:nami_flutter/nami_log_level.dart';
import 'package:nami_flutter/paywall/nami_paywall_manager.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';
import 'package:nami_flutter_example/about.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const _testExternalIdentifier = "9a9999a9-99aa-99a9-aa99-999a999999a8";

  // Linked = "e340101d-c581-4c32-acd1-af0f66184d92
  // Basic = "b1a6572f-b0fc-45cd-8561-110c039c7744"
  static const _androidAppPlatformId = "b1a6572f-b0fc-45cd-8561-110c039c7744";

  // Linked = 6a13d56b-540b-497f-9721-478b8b59fc0f
  // Basic = db5e6672-ae5b-4a0e-b545-2b60d5fa9066
  static const _iosAppPlatformId = "db5e6672-ae5b-4a0e-b545-2b60d5fa9066";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          buttonTheme: ButtonThemeData(
            buttonColor: Color.fromARGB(255, 65, 109, 124),
          ),
          primaryColor: Color.fromARGB(255, 65, 109, 124),
          accentColor: Color.fromARGB(255, 65, 109, 124),
        ),
        home: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: SizedBox(
                  height: 24,
                  child: Image.asset("assets/images/nami_logo_white.png")),
            ),
            body: _buildMainPageBody()));
  }

  @override
  void initState() {
    super.initState();
    print('--------- initState ---------');
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();
    NamiPaywallManager.signInEvents().listen((namiPaywall) {
      Nami.clearExternalIdentifier();
      Nami.setExternalIdentifier(
          _testExternalIdentifier, NamiExternalIdentifierType.uuid);
      print('--------- Sign In Clicked ---------');
    });
    _printCustomerJourneyState();
    _handleActiveEntitlements();
    NamiAnalyticsSupport.analyticsEvents().listen((analyticsData) {
      printAnalyticsEventData(analyticsData);
    });
    NamiPaywallManager.paywallRaiseEvents().listen((paywallRaiseRequestData) {
      print('--------- RAISE PAYWALL REQUESTED ---------');
    });
    // Uncomment this to test NamiEntitlementManager.setEntitlements()
    //_setEntitlementSetters();
  }

  void _setEntitlementSetters() { // ignore: unused_element
    List<NamiEntitlementSetter> entitlements = List();
    entitlements.add(NamiEntitlementSetter("123"));
    entitlements.add(NamiEntitlementSetter(
        "1234", NamiPlatformType.apple, null, DateTime.now()));
    entitlements.add(NamiEntitlementSetter(null, NamiPlatformType.android,
        "purchasedSKUid", DateTime.fromMillisecondsSinceEpoch(0)));
    entitlements.add(NamiEntitlementSetter(null, null, null, null));
    NamiEntitlementManager.setEntitlements(entitlements);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('--------- ON RESUME ---------');
      _printCustomerJourneyState();
      _handleActiveEntitlements();
    }
  }

  void _handleActiveEntitlements() async {
    var activeEntitlements = await NamiEntitlementManager.activeEntitlements();
    print('--------- Start ---------');
    if (activeEntitlements.isNotEmpty) {
      print("Active entitlements found!");
      activeEntitlements.forEach((element) {
        print(element.toString());
      });
    } else {
      print("No active entitlements");
    }
    print('--------- End ---------');
  }

  void _printCustomerJourneyState() async {
    var state = await NamiCustomerManager.currentCustomerJourneyState();
    print('--------- Start ---------');
    print("currentCustomerJourneyState");
    if (state != null) {
      print("formerSubscriber ==> ${state.formerSubscriber}");
      print("inGracePeriod ==> ${state.inGracePeriod}");
      print("inIntroOfferPeriod ==> ${state.inIntroOfferPeriod}");
      print("inTrialPeriod ==> ${state.inTrialPeriod}");
    } else {
      print("NULL");
    }
    print('--------- End ---------');
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    var namiConfiguration = NamiConfiguration(
        _iosAppPlatformId,
        _androidAppPlatformId,
        false,
        NamiLogLevel.debug,
        false,
        false,
        ["useStagingAPI"]);
    Nami.configure(namiConfiguration);
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  SingleChildScrollView _buildMainPageBody() {
    return SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Basic Flutter",
                    style: TextStyle(fontSize: 24, fontStyle: FontStyle.italic),
                  ),
                  Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AboutPage()),
                            );
                          },
                          child: Text("About"))),
                  buildHeaderBodyContainer("Introduction",
                      "This application demonstrates common calls used in a Nami enabled application."),
                  buildHeaderBodyContainer("Instructions",
                      "If you suspend and resume this app three times in the simulator, an example paywall will be raised - or you can use the [Subscribe] button below to raise the same paywall."),
                  buildHeaderBodyContainer("Important info",
                      "Any Purchase will be remembered while the application is [Active, Suspended, Resume] but cleared when the application is launched.\nExamine the application source code for more details on calls used to respond and monitor purchases."),
                  Container(
                    margin: const EdgeInsets.only(top: 48),
                    child: ElevatedButton(
                      onPressed: () async {
                        NamiMLManager.coreAction("subscribe");
                        print('Subscribe clicked!');
                        if (await NamiPaywallManager.canRaisePaywall()) {
                          NamiPaywallManager.raisePaywall();
                          //NamiPaywallManager.raisePaywallByDeveloperPaywallId("TestDevID");
                        }
                        // To test buySKU, uncomment below line and comment out
                        // above two lines about raising paywall
                        // _testBuySKU("test_product_monthly_subscription");
                      },
                      child: Text('Subscribe'),
                    ),
                  )
                ])));
  }

  void printAnalyticsEventData(NamiAnalyticsData analyticsData) {
    print('--------- Start ---------');
    print('analyticsEvents');
    print("TYPE " + analyticsData.type.toString());
    print("CAMPAIGN_ID " +
        analyticsData.eventData[NamiAnalyticsKeys.CAMPAIGN_ID]);
    print("CAMPAIGN_NAME " +
        analyticsData.eventData[NamiAnalyticsKeys.CAMPAIGN_NAME]);
    dynamic campaignType =
        analyticsData.eventData[NamiAnalyticsKeys.CAMPAIGN_TYPE];
    if (campaignType != null) {
      print("CAMPAIGN_TYPE " + campaignType.toString());
    }
    bool namiTriggered =
        analyticsData.eventData[NamiAnalyticsKeys.NAMI_TRIGGERED];
    print("NAMI_TRIGGERED " + namiTriggered.toString());
    print(
        "PAYWALL_ID " + analyticsData.eventData[NamiAnalyticsKeys.PAYWALL_ID]);
    print("PAYWALL_NAME " +
        analyticsData.eventData[NamiAnalyticsKeys.PAYWALL_NAME]);
    List<NamiSKU> products =
        analyticsData.eventData[NamiAnalyticsKeys.PAYWALL_PRODUCTS];
    print("PAYWALL_PRODUCTS " + products.toString());
    print("PAYWALL_TYPE " +
        analyticsData.eventData[NamiAnalyticsKeys.PAYWALL_TYPE]);
    dynamic purchaseActivityType =
        analyticsData.eventData[NamiAnalyticsKeys.PURCHASE_ACTIVITY_TYPE];
    if (purchaseActivityType != null) {
      print("PURCHASE_ACTIVITY_TYPE " + purchaseActivityType.toString());
    }
    dynamic purchasedProduct =
        analyticsData.eventData[NamiAnalyticsKeys.PURCHASE_PRODUCT];
    if (purchasedProduct != null) {
      print("PURCHASE_PRODUCT " + purchasedProduct.toString());
    } else {
      print("PURCHASE_PRODUCT NULL");
    }
    dynamic purchaseTimestamp =
        analyticsData.eventData[NamiAnalyticsKeys.PURCHASE_TIMESTAMP];
    if (purchaseTimestamp != null) {
      print("PURCHASE_TIMESTAMP " + purchaseTimestamp.toString());
    } else {
      print("PURCHASE_TIMESTAMP NULL");
    }
    print('--------- End ---------');
  }

  void _testBuySKU(String skuRefId) async { // ignore: unused_element
    NamiPurchaseCompleteResult result =
        await NamiPurchaseManager.buySKU(skuRefId);
    if (result != null) {
      print('Purchase Complete with state ${result.purchaseState}--');
    } else {
      print('Purchase Complete with NULL result');
    }
  }
}

Container buildHeaderBodyContainer(String header, String body) {
  return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
              margin: const EdgeInsets.only(top: 8),
              child: Text(
                header,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              )),
          Text(
            body,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ));
}
