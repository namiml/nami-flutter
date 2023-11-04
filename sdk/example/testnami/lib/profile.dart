import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nami_flutter/customer/nami_customer_manager.dart';
import 'package:testnami/constants.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({Key? key}) : super(key: key);

  @override
  ProfileWidgetState createState() => ProfileWidgetState();
}

class ProfileWidgetState extends State<ProfileWidget>
    with WidgetsBindingObserver {
  final List<StreamSubscription> _subscriptions = [];
  String _deviceId = "";
  String? _externalId;
  bool _isLoggedIn = false;

  bool _formerSubscriber = false;
  bool _inTrialPeriod = false;
  bool _inIntroOfferPeriod = false;
  bool _inGracePeriod = false;
  bool _inPause = false;
  bool _inAccountHold = false;
  bool _isCancelled = false;

  void getDeviceId() async {
    var deviceId = await NamiCustomerManager.deviceId();
    print("deviceId $deviceId");

    setState(() {
      _deviceId = deviceId;
    });
  }

  void updateAccountState() async {
    var isLoggedIn = await NamiCustomerManager.isLoggedIn();
    var loggedInId = await NamiCustomerManager.loggedInId();

    setState(() {
      _isLoggedIn = isLoggedIn;
      _externalId = loggedInId;
      print(
          "isLoggedIn $_isLoggedIn, loggedInId $_externalId, deviceId $_deviceId");
    });
  }

  void _updateAccountState(AccountState accountState) {
    print("AccountStateHandler triggered");
    updateAccountState();

    if (accountState.success) {
      if (accountState.accountStateAction == AccountStateAction.login) {
        print("Login success");
      } else if (accountState.accountStateAction == AccountStateAction.logout) {
        print("Logout success");
      }
    } else {
      if (accountState.accountStateAction == AccountStateAction.login) {
        print("Login error - ${accountState.error}");
      } else if (accountState.accountStateAction == AccountStateAction.logout) {
        print("Logout error - ${accountState.error}");
      }
    }
  }

  void _updateJourneyState(CustomerJourneyState journeyState) {
    setState(() {
      _formerSubscriber = journeyState.formerSubscriber;
      _inTrialPeriod = journeyState.inTrialPeriod;
      _inIntroOfferPeriod = journeyState.inIntroOfferPeriod;
      _inGracePeriod = journeyState.inGracePeriod;
      _inPause = journeyState.inPause;
      _inAccountHold = journeyState.inAccountHold;
      _isCancelled = journeyState.isCancelled;
      print("JourneyStateHandler triggered");
    });

    print('--------- Start ---------');
    print("currentCustomerJourneyState");
    print("formerSubscriber ==> ${journeyState.formerSubscriber}");
    print("inGracePeriod ==> ${journeyState.inGracePeriod}");
    print("inIntroOfferPeriod ==> ${journeyState.inIntroOfferPeriod}");
    print("inTrialPeriod ==> ${journeyState.inTrialPeriod}");
    print("isCancelled ==> ${journeyState.isCancelled}");
    print("inPause ==> ${journeyState.inPause}");
    print("inAccountHold ==> ${journeyState.inAccountHold}");
    print('--------- End ---------');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsFlutterBinding.ensureInitialized();

    getDeviceId();

    StreamSubscription journeyStateSubscription =
        NamiCustomerManager.registerJourneyStateHandler()
            .listen((journeyState) {
      _updateJourneyState(journeyState);
    });

    _subscriptions.add(journeyStateSubscription);

    StreamSubscription accountsStateSubscription =
        NamiCustomerManager.registerAccountStateHandler()
            .listen((accountState) {
      _updateAccountState(accountState);
    });

    _subscriptions.add(accountsStateSubscription);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  DataRow dataRowItem(bool? enabled, String label) {
    return DataRow(
      cells: <DataCell>[
        DataCell(Text(label)),
        DataCell(Icon(
            enabled == true ? Icons.check_circle : Icons.radio_button_unchecked,
            color: enabled == true ? namiGreen : namiGray)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 20),
                Text(
                  _isLoggedIn ? "Registered User" : "Anonymous User",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isLoggedIn
                      ? "External Id: $_externalId"
                      : "Device Id: $_deviceId",
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 20),
                DataTable(
                  showCheckboxColumn: false,
                  columns: const <DataColumn>[
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'Customer Journey State',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'True?',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  ],
                  rows: <DataRow>[
                    dataRowItem(_inTrialPeriod, 'In Trial Period'),
                    dataRowItem(_inIntroOfferPeriod, 'In Intro Offer Period'),
                    dataRowItem(_inGracePeriod, 'In Grace Period'),
                    dataRowItem(_inPause, 'In Pause'),
                    dataRowItem(_inAccountHold, 'In Account Hold'),
                    dataRowItem(_isCancelled, 'Is Cancelled'),
                    dataRowItem(_formerSubscriber, 'Former Subscriber')
                  ],
                )
              ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text(_isLoggedIn ? "Logout" : "Login"),
        icon: Icon(_isLoggedIn ? Icons.logout : Icons.login),
        backgroundColor: namiPrimaryBlue,
        onPressed: () {
          if (_isLoggedIn == false) {
            NamiCustomerManager.login(withId: testExternalIdentifier);
          } else {
            NamiCustomerManager.logout();
          }
        },
      ),
    );
  }
}
