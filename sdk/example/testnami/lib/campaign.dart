import 'package:flutter/material.dart';
import 'package:nami_flutter/campaign/nami_campaign_manager.dart';

class CampaignWidget extends StatefulWidget {
  const CampaignWidget({Key? key}) : super(key: key);

  @override
  CampaignWidgetState createState() => CampaignWidgetState();

  @override
  setState() {}
}

class CampaignWidgetState extends State<CampaignWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        ///padding: EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 10),
              SizedBox(height: 10),
              Text(
                "Launch a Campaign",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 3),
              Text(
                "Tap a campaign to show a paywall",
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
                        'Campaign',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                ],
                rows: <DataRow>[
                  DataRow(
                    onSelectChanged: (value) async {
                      var launchCampaignResult =
                          await NamiCampaignManager.launch();

                      if (launchCampaignResult.success) {
                        print('Campaign Launch success -> ');
                      } else {
                        print('Campaign Launch error -> '
                            '${launchCampaignResult.error}');
                      }
                    },
                    cells: <DataCell>[
                      DataCell(Text('Default')),
                    ],
                  ),
                  DataRow(
                    onSelectChanged: (value) {
                      NamiCampaignManager.launch(label: "penguin");
                    },
                    cells: <DataCell>[
                      DataCell(Text('Penguin')),
                    ],
                  ),
                  DataRow(
                    onSelectChanged: (value) {
                      NamiCampaignManager.launch(label: "pacific");
                    },
                    cells: <DataCell>[
                      DataCell(Text('Pacific')),
                    ],
                  ),
                  DataRow(
                    onSelectChanged: (value) {
                      NamiCampaignManager.launch(label: "trident");
                    },
                    cells: <DataCell>[
                      DataCell(Text('Trident')),
                    ],
                  ),
                  DataRow(
                    onSelectChanged: (value) {
                      NamiCampaignManager.launch(label: "starfish");
                    },
                    cells: <DataCell>[
                      DataCell(Text('Starfish')),
                    ],
                  ),
                  DataRow(
                    onSelectChanged: (value) {
                      NamiCampaignManager.launch(label: "mantis");
                    },
                    cells: <DataCell>[
                      DataCell(Text('Mantis')),
                    ],
                  ),
                  DataRow(
                    onSelectChanged: (value) {
                      NamiCampaignManager.launch(label: "venice");
                    },
                    cells: <DataCell>[
                      DataCell(Text('Venice')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
