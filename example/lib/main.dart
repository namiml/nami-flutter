import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nami_flutter/analytics/nami_analytics_support.dart';
import 'package:nami_flutter/customer/nami_customer_manager.dart';
import 'package:nami_flutter/entitlement/nami_entitlement_manager.dart';
import 'package:nami_flutter/entitlement/nami_entitlement_setter.dart';
import 'package:nami_flutter/nami.dart';
import 'package:nami_flutter/paywall/nami_paywall_manager.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const testExternalIdentifier = "9a9999a9-99aa-99a9-aa99-999a999999a8";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();
    NamiPaywallManager.signInEvents().listen((map) {
      Nami.clearExternalIdentifier();
      Nami.setExternalIdentifier(
          testExternalIdentifier, NamiExternalIdentifierType.uuid);
      print('Sign In Clicked');
    });
    _printCustomerJourneyState();
    _handleActiveEntitlements();
    NamiAnalyticsSupport.analyticsEvents().listen((analyticsData) {
      printAnalyticsEventData(analyticsData);
    });
    // Uncomment this to test NamiEntitlementManager.setEntitlements()
    //_setEntitlementSetters();
  }

  void _setEntitlementSetters() {
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
        "db5e6672-ae5b-4a0e-b545-2b60d5fa9066",
        "b1a6572f-b0fc-45cd-8561-110c039c7744",
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Builder(
          builder: (BuildContext context) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        print('Subscribe clicked!');
                        if (await NamiPaywallManager.canRaisePaywall()) {
                          NamiPaywallManager.raisePaywall();
                        }
                      },
                      child: Text('Subscribe'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        var exId = await Nami.getExternalIdentifier();
                        print("Nami.getExternalIdentifier() ==> $exId");
                      },
                      child: Text('Get External Identifier'),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
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
}
