import 'dart:async';
import 'package:flutter/material.dart';

import 'package:nami_flutter/entitlement/nami_entitlement_manager.dart';
import 'package:testnami/constants.dart';

class EntitlementsWidget extends StatefulWidget {
  const EntitlementsWidget({Key? key}) : super(key: key);

  @override
  _EntitlementsWidgetState createState() => new _EntitlementsWidgetState();

  @override
  setState() {}
}

class _EntitlementsWidgetState extends State<EntitlementsWidget>
    with WidgetsBindingObserver {
  List<NamiEntitlement> _activeEntitlements = [];
  List<StreamSubscription> _subscriptions = [];

  void _handleActiveEntitlements(List<NamiEntitlement> activeEntitlements) {
    if (activeEntitlements.isNotEmpty) {
      _activeEntitlements = activeEntitlements;
    } else {}
  }

  void _handleActiveEntitlementsFuture(
      Future<List<NamiEntitlement>> activeEntitlementsFuture) async {
    _handleActiveEntitlements(await activeEntitlementsFuture);
  }

  List<DataRow> _getActiveEntitlementsRows() {
    List<DataRow> dataRows = [];

    _activeEntitlements.forEach((entitlement) {
      dataRows.add(dataRowItem(entitlement.referenceId));
    });
    return dataRows;
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      NamiEntitlementManager.refresh();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    StreamSubscription activeEntitlementsSubscription =
        NamiEntitlementManager.registerActiveEntitlementsHandler()
            .listen((activeEntitlements) {
      print("ActiveEntitlementsHandler triggered");
      _handleActiveEntitlements(activeEntitlements);
    });

    _subscriptions.add(activeEntitlementsSubscription);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscriptions.forEach((subscription) {
      subscription.cancel();
    });
    super.dispose();
  }

  DataRow dataRowItem(String entitlementRefId) {
    return DataRow(
      cells: <DataCell>[
        DataCell(Text(entitlementRefId)),
        DataCell(Icon(Icons.check_circle, color: namiGreen)),
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
                  _activeEntitlements.length > 0
                      ? "Current Entitlements for User"
                      : "No Active Entitlements for User",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 20),
                DataTable(
                  showCheckboxColumn: false,
                  columns: <DataColumn>[
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          _activeEntitlements.length > 0
                              ? "Active Entitlements"
                              : "",
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          '',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  ],
                  rows: _getActiveEntitlementsRows(),
                )
              ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text("Refresh Entitlements"),
        icon: new Icon(Icons.refresh),
        backgroundColor: namiPrimaryBlue,
        onPressed: () {
          NamiEntitlementManager.refresh();
        },
      ),
    );
  }
}
