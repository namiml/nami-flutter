import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nami_flutter/nami.dart';
import 'package:nami_flutter/nami_configuration.dart';
import 'package:nami_flutter/nami_paywall_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const testExternalIdentifier = "9a9999a9-99aa-99a9-aa99-999a999999a8";

  @override
  void initState() {
    super.initState();
    initPlatformState();
    Nami.signInEvents().listen((map) {
      Nami.clearExternalIdentifier();
      Nami.setExternalIdentifier(
          testExternalIdentifier, NamiExternalIdentifierType.uuid);
      print('Sign In Clicked');
    });
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
}
