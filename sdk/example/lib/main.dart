import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nami_flutter/analytics/nami_analytics_support.dart';
import 'package:nami_flutter/billing/nami_purchase_manager.dart';
import 'package:nami_flutter/customer/nami_customer_manager.dart';
import 'package:nami_flutter/entitlement/nami_entitlement_manager.dart';
import 'package:nami_flutter/ml/nami_ml_manager.dart';
import 'package:nami_flutter/nami.dart';
import 'package:nami_flutter/nami_configuration.dart';
import 'package:nami_flutter/nami_log_level.dart';
import 'package:nami_flutter/paywall/nami_paywall_manager.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';

import 'about.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const _testExternalIdentifier = "9a9999a9-99aa-99a9-aa99-999a999999a8";
  static const _androidAppPlatformId = "3d062066-9d3c-430e-935d-855e2c56dd8e";
  static const _iosAppPlatformId = "002e2c49-7f66-4d22-a05c-1dc9f2b7f2af";

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
    WidgetsBinding.instance?.addObserver(this);
    initPlatformState();
    NamiCustomerManager.customerJourneyChangeEvents().listen((journeyState) {
      print("customerJourneyChange triggered");
      _handleCustomerJourneyChanged(journeyState);
    });
    NamiPaywallManager.signInEvents().listen((namiPaywall) {
      Nami.clearExternalIdentifier();
      Nami.setExternalIdentifier(
          _testExternalIdentifier, NamiExternalIdentifierType.uuid);
      print('--------- Sign In Clicked ---------');
    });
    _handleActiveEntitlementsFuture(
        NamiEntitlementManager.activeEntitlements());
    NamiEntitlementManager.entitlementChangeEvents()
        .listen((activeEntitlements) {
      print("EntitlementChangeListener triggered");
      _handleActiveEntitlements(activeEntitlements);
    });
    NamiPurchaseManager.purchaseChangeEvents()
        .listen((purchaseChangeEventData) {
      print("PurchasesChangedHandler triggered");
      _evaluateLastPurchaseEvent(purchaseChangeEventData);
    });
    NamiAnalyticsSupport.analyticsEvents().listen((analyticsData) {
      _printAnalyticsEventData(analyticsData);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      print('--------- ON RESUME ---------');
      _handleActiveEntitlementsFuture(
          NamiEntitlementManager.activeEntitlements());
    }
  }

  void _evaluateLastPurchaseEvent(
      PurchaseChangeEventData purchaseChangeEventData) {
    print('--------- Start ---------');
    print("Purchase State ${purchaseChangeEventData.purchaseState}");
    if (purchaseChangeEventData.purchaseState == NamiPurchaseState.purchased) {
      print("\nActive Purchases: ");
      purchaseChangeEventData.activePurchases.forEach((element) {
        print("\tSkuId: ${element.skuId}");
      });
    } else {
      print("Reason : ${purchaseChangeEventData.error}");
    }
    print('--------- End ---------');
  }

  void _handleActiveEntitlements(List<NamiEntitlement> activeEntitlements) {
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

  void _handleActiveEntitlementsFuture(
      Future<List<NamiEntitlement>> activeEntitlementsFuture) async {
    _handleActiveEntitlements(await activeEntitlementsFuture);
  }

  void _handleCustomerJourneyChanged(CustomerJourneyState state) async {
    print('--------- Start ---------');
    print("currentCustomerJourneyState");
    print("formerSubscriber ==> ${state.formerSubscriber}");
    print("inGracePeriod ==> ${state.inGracePeriod}");
    print("inIntroOfferPeriod ==> ${state.inIntroOfferPeriod}");
    print("inTrialPeriod ==> ${state.inTrialPeriod}");
    print("isCancelled ==> ${state.isCancelled}");
    print("inPause ==> ${state.inPause}");
    print("inAccountHold ==> ${state.inAccountHold}");
    print('--------- End ---------');
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    var namiConfiguration = NamiConfiguration(
        appPlatformIDApple: _iosAppPlatformId,
        appPlatformIDGoogle: _androidAppPlatformId,
        namiLogLevel: NamiLogLevel.debug);
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
                        var preparePaywallResult =
                            await NamiPaywallManager.preparePaywallForDisplay();
                        if (preparePaywallResult.success) {
                          NamiPaywallManager.raisePaywall();
                        } else {
                          print('preparePaywallForDisplay Error -> '
                              '${preparePaywallResult.error}');
                        }
                      },
                      child: Text('Subscribe'),
                    ),
                  )
                ])));
  }

  void _printAnalyticsEventData(NamiAnalyticsData analyticsData) {
    print('--------- Start ---------');
    print('analyticsEvents');
    print("TYPE " + analyticsData.type.toString());
    print("CAMPAIGN_ID " +
        analyticsData.eventData[NamiAnalyticsKeys.CAMPAIGN_ID]);
    print("CAMPAIGN_NAME " +
        analyticsData.eventData[NamiAnalyticsKeys.CAMPAIGN_NAME]);
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
    print("PURCHASE_ACTIVITY_TYPE ${purchaseActivityType.toString()}");
    dynamic purchasedProduct =
        analyticsData.eventData[NamiAnalyticsKeys.PURCHASE_PRODUCT];
    print("PURCHASE_PRODUCT ${purchasedProduct.toString()}");
    dynamic purchaseTimestamp =
        analyticsData.eventData[NamiAnalyticsKeys.PURCHASE_TIMESTAMP];
    print("PURCHASE_TIMESTAMP ${purchaseTimestamp.toString()}");
    print('--------- End ---------');
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
