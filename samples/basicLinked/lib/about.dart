import 'package:flutter/material.dart';
import 'package:nami_flutter/ml/nami_ml_manager.dart';
import 'package:nami_flutter/paywall/nami_paywall_manager.dart';

import 'main.dart';

class AboutPage extends StatefulWidget {
  @override
  _AboutState createState() => _AboutState();
}

class _AboutState extends State<AboutPage> with WidgetsBindingObserver {
  static const _label = "about";

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
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              centerTitle: true,
              title: Text("About"),
            ),
            body: Padding(
                padding: EdgeInsets.all(16.0),
                child: buildHeaderBodyContainer("Introduction",
                    "This application demonstrates common calls used in a Nami enabled application."))));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('--------- ABOUT INIT ---------');
    NamiMLManager.enterCoreContent([_label]);
    NamiPaywallManager.blockPaywallAutoRaise(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('--------- ABOUT RESUME ---------');
      NamiMLManager.enterCoreContent([_label]);
    }
  }

  @override
  void dispose() {
    print('--------- ABOUT EXIT ---------');
    NamiMLManager.exitCoreContent([_label]);
    WidgetsBinding.instance.removeObserver(this);
    NamiPaywallManager.blockPaywallAutoRaise(false);
    super.dispose();
  }
}
