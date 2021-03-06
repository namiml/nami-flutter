import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nami_flutter/billing/nami_purchase_manager.dart';
import 'package:nami_flutter/customer/nami_customer_manager.dart';
import 'package:nami_flutter/entitlement/nami_entitlement_manager.dart';
import 'package:nami_flutter/ml/nami_ml_manager.dart';
import 'package:nami_flutter/nami.dart';
import 'package:nami_flutter/nami_configuration.dart';
import 'package:nami_flutter/nami_log_level.dart';
import 'package:nami_flutter/paywall/nami_paywall_manager.dart';

import 'about.dart';
import 'paywall.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const _androidAppPlatformId = "e340101d-c581-4c32-acd1-af0f66184d92";
  static const _iosAppPlatformId = "6a13d56b-540b-497f-9721-478b8b59fc0f";

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
    _printCustomerJourneyState();
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
    NamiPaywallManager.paywallRaiseEvents().listen((paywallRaiseRequestData) {
      print('--------- RAISE PAYWALL REQUESTED ---------');
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PaywallPage(data: paywallRaiseRequestData)),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('--------- ON RESUME ---------');
      _printCustomerJourneyState();
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
    var namiConfiguration =
        NamiConfiguration(_iosAppPlatformId, _androidAppPlatformId);
    namiConfiguration.namiLogLevel = NamiLogLevel.debug;
    namiConfiguration.extraData.add("useStagingAPI");
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
                    "Basic Linked Flutter",
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
                        }
                      },
                      child: Text('Subscribe'),
                    ),
                  )
                ])));
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
