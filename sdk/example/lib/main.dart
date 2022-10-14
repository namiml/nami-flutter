import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nami_flutter/analytics/nami_analytics_support.dart';
import 'package:nami_flutter/billing/nami_purchase_manager.dart';
import 'package:nami_flutter/campaign/nami_campaign_manager.dart';
import 'package:nami_flutter/customer/nami_customer_manager.dart';
import 'package:nami_flutter/entitlement/nami_entitlement_manager.dart';
import 'package:nami_flutter/paywall/nami_paywall_manager.dart';
import 'package:nami_flutter/ml/nami_ml_manager.dart';
import 'package:nami_flutter/nami.dart';
import 'package:nami_flutter/nami_configuration.dart';
import 'package:nami_flutter/nami_log_level.dart';
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
  // TODO: uncomment release
  // static const _androidAppPlatformId = "3d062066-9d3c-430e-935d-855e2c56dd8e";
  // TODO: delete this before release
  static const _androidAppPlatformId = "aaf69dba-ef67-40f5-82ec-c7623a2848a6";
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
    NamiCustomerManager.registerJourneyStateHandler().listen((journeyState) {
      print("JourneyStateHandler triggered");
      _handleJourneyState(journeyState);
    });
    NamiPaywallManager.signInEvents().listen((signInClicked) {
      NamiCustomerManager.logout();
      NamiCustomerManager.login(withId: _testExternalIdentifier);
      print('--------- Sign In Clicked ---------');
    });
    _handleActiveEntitlementsFuture(
        NamiEntitlementManager.active());
    NamiEntitlementManager.registerActiveEntitlementsHandler()
        .listen((activeEntitlements) {
      print("ActiveEntitlementsHandler triggered");
      _handleActiveEntitlements(activeEntitlements);
    });
    NamiPurchaseManager.registerPurchasesChangedHandler()
        .listen((purchasesResponseHandlerData) {
      print("PurchasesChangedHandler triggered");
    });
    NamiCustomerManager.registerAccountStateHandler()
        .listen((accountState) {
      print("AccountStateHandler triggered");

      if (accountState.success) {
        if (accountState.accountStateAction == AccountStateAction.login) {
          print("Login success");
        } else
        if (accountState.accountStateAction == AccountStateAction.logout) {
          print("Logout success");
        }
      } else {
        if (accountState.accountStateAction == AccountStateAction.login) {
          print("Login error - ${accountState.error}");
        } else
        if (accountState.accountStateAction == AccountStateAction.logout) {
          print("Logout error - ${accountState.error}");
        }
      }
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
          NamiEntitlementManager.active());
    }
  }

  void _evaluateLastPurchaseEvent(
      NamiPurchaseResponseHandlerData purchasesResponseHandlerData) {
    print('--------- Start ---------');
    print("Purchase State ${purchasesResponseHandlerData.purchaseState}");
    if (purchasesResponseHandlerData.purchaseState == NamiPurchaseState.purchased) {
      print("\nActive Purchases: ");
      purchasesResponseHandlerData.purchases.forEach((element) {
        print("\tSkuId: ${element.skuId}");
      });
    } else {
      print("Reason : ${purchasesResponseHandlerData.error}");
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

  void _handleJourneyState(CustomerJourneyState state) async {
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
        appPlatformIdApple: _iosAppPlatformId,
        appPlatformIdGoogle: _androidAppPlatformId,
        namiLogLevel: NamiLogLevel.debug,
        extraData: ["useStagingAPI"]);
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
                      "Use the one of the Campaign buttons below show a paywall"),
                  Container(
                    margin: const EdgeInsets.only(top: 48),
                    child: ElevatedButton(
                      onPressed: () async {
                          NamiMLManager.coreAction("subscribe");
                          print('Launch default campaign tapped!');
                          var launchCampaignResult =
                          await NamiCampaignManager.launch();
                          if (launchCampaignResult.success) {
                            print('Campaign Launch success -> ');
                          } else {
                            print('Campaign Launch error -> '
                                '${launchCampaignResult.error}');
                          }
                        },
                      child: Text('Default Campaign'),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed: () async {
                        NamiMLManager.coreAction("subscribe");
                        print('Launch campaign tapped with label');
                        var launchCampaignResult =
                          await NamiCampaignManager.launch(label: "your_campaign_label");
                        if (launchCampaignResult.success) {
                          print('Campaign Launch success -> ');
                        } else {
                          print('Campaign Launch error -> '
                              '${launchCampaignResult.error}');
                        }
                      },
                      child: Text('Labeled Campaign'),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed: () async {
                        print('Refresh button pressed');
                        var activeEntitlements = await NamiEntitlementManager.refresh();
                        print ('Active Entitlements -> '
                            '${activeEntitlements}');
                      },
                      child: Text('Refresh Active Entitlements'),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed: () async {
                        print('Login button pressed');
                        NamiCustomerManager.login(withId: _testExternalIdentifier);
                      },
                      child: Text('Login'),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed: () async {
                        print('Logout button pressed');
                        NamiCustomerManager.logout();
                      },
                      child: Text('Logout'),
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
