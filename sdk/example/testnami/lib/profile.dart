import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nami_flutter/customer/nami_customer_manager.dart';
import 'package:testnami/constants.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({Key? key}) : super(key: key);

  @override
  _ProfileWidgetState createState() => new _ProfileWidgetState();

  @override
  setState() {}
}

class _ProfileWidgetState extends State<ProfileWidget>
    with WidgetsBindingObserver {
  List<StreamSubscription> _subscriptions = [];
  CustomerJourneyState? _journeyState;
  String _deviceId = "";
  String _externalId = "";
  bool _isLoggedIn = false;

  void getDeviceId() async {
    var deviceId = await NamiCustomerManager.deviceId();

    setState(() {
      _deviceId = deviceId;
    });
  }

  void updateAccountState() async {
    var isLoggedIn = await NamiCustomerManager.isLoggedIn();
    var loggedInId = await NamiCustomerManager.loggedInId();

    setState(() {
      _isLoggedIn = isLoggedIn;
      if (_externalId != null) {
        _externalId = loggedInId!;
      }
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
      _journeyState = journeyState;
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

    StreamSubscription journeyStateSubscription = NamiCustomerManager.registerJourneyStateHandler().listen((journeyState) {
      print("JourneyStateHandler triggered");
      _updateJourneyState(journeyState);
    });

    _subscriptions.add(journeyStateSubscription);

    StreamSubscription accountsStateSubscription = NamiCustomerManager.registerAccountStateHandler().listen((accountState) {
      _updateAccountState(accountState);
    });

    _subscriptions.add(accountsStateSubscription);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscriptions.forEach((subscription) {
      subscription.cancel();
    });
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
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 10),
                SizedBox(height: 10),
                Text(
                  _isLoggedIn ? "Registered User" : "Anonymous User",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  _isLoggedIn
                      ? "External Id: ${_externalId}"
                      : "Device Id: ${_deviceId}",
                  style: TextStyle(
                    fontSize: 10,
                  ),
                ),
                SizedBox(height: 20),
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
                    dataRowItem(
                        _journeyState != null
                            ? _journeyState?.inTrialPeriod
                            : false,
                        'In Trial Period'),
                    dataRowItem(
                        _journeyState != null
                            ? _journeyState?.inIntroOfferPeriod
                            : false,
                        'In Intro Offer Period'),
                    dataRowItem(
                        _journeyState != null
                            ? _journeyState?.inGracePeriod
                            : false,
                        'In Grace Period'),
                    dataRowItem(
                        _journeyState != null ? _journeyState?.inPause : false,
                        'In Pause'),
                    dataRowItem(
                        _journeyState != null
                            ? _journeyState?.inAccountHold
                            : false,
                        'In Account Hold'),
                    dataRowItem(
                        _journeyState != null
                            ? _journeyState?.isCancelled
                            : false,
                        'Is Cancelled'),
                    dataRowItem(
                        _journeyState != null
                            ? _journeyState?.formerSubscriber
                            : false,
                        'Former Subscriber')
                  ],
                )
              ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text(_isLoggedIn ? "Logout" : "Login"),
        icon: new Icon(_isLoggedIn ? Icons.logout : Icons.login),
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
