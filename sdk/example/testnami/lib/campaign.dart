import 'package:flutter/material.dart';
import 'package:nami_flutter/campaign/nami_campaign.dart';
import 'package:nami_flutter/campaign/nami_campaign_manager.dart';
import 'package:nami_flutter/campaign/nami_paywall_event.dart';
import 'package:nami_flutter/paywall/nami_paywall_manager.dart';
import 'package:testnami/constants.dart';

class CampaignWidget extends StatefulWidget {
  const CampaignWidget({Key? key}) : super(key: key);

  @override
  CampaignWidgetState createState() => CampaignWidgetState();
}

class CampaignWidgetState extends State<CampaignWidget> {
  List<NamiCampaign> _campaigns = [];

  @override
  void initState() {
    super.initState();

    NamiCampaignManager.registerAvailableCampaignsHandler().listen((list) {
      setState(() {
        print("registerAvailableCampaignsHandler triggered");
        _campaigns = list;
      });
    });

    NamiCampaignManager.allCampaigns().then((list) {
      setState(() {
        _campaigns = list;
      });
    });

    NamiPaywallManager.registerBuySkuHandler().listen((sku) {
      print('start purchase process for $sku');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    NamiCampaign? defaultCampaign;
    try {
      defaultCampaign = _campaigns.firstWhere(
          (element) => element.type == NamiCampaignRuleType.DEFAULT);
    } catch (e) {
      defaultCampaign = null;
    }

    List<NamiCampaign> labeledCampaigns = _campaigns
        .where((element) => element.type == NamiCampaignRuleType.LABEL)
        .toList();

    List<Widget> campaignItems = [];

    if (defaultCampaign != null) {
      campaignItems.add(header("Default campaign"));
      campaignItems.add(campaignItem(defaultCampaign));
    }

    if (labeledCampaigns.isNotEmpty) {
      campaignItems.add(header("Labeled campaign"));
      campaignItems
          .addAll(labeledCampaigns.map((e) => campaignItem(e)).toList());
    }

    return Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                const Text(
                  "Launch a Campaign",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  "Tap a campaign to show a paywall",
                  style: TextStyle(
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                    child: SingleChildScrollView(
                  child: Column(
                    children: campaignItems,
                  ),
                ))
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
            label: Text("Refresh"),
            icon: new Icon(Icons.refresh),
            backgroundColor: namiPrimaryBlue,
            onPressed: () {
              NamiCampaignManager.refresh();
            }));
  }

  Widget campaignItem(NamiCampaign campaign) {
    return InkWell(
      onTap: () async {
        LaunchCampaignResult result;
        switch (campaign.type) {
          case NamiCampaignRuleType.DEFAULT:
            if (await NamiCampaignManager.isCampaignAvailable()) {
              result = await NamiCampaignManager.launch(
                  label: campaign.value,
                  onPaywallAction: (paywallEvent) {
                    print("Paywall event $paywallEvent");
                  });

              if (result.success) {
                print("Campaign (no label) launched successfully");
              } else {
                print("Campaign (no label) launched failed");
              }
            } else {
              print("Campaign (no label) is not available on this device.");
            }
            break;
          case NamiCampaignRuleType.LABEL:
            if (await NamiCampaignManager.isCampaignAvailable(
                label: campaign.value)) {
              result = await NamiCampaignManager.launch(
                  label: campaign.value,
                  onPaywallAction: (paywallEvent) {
                    print("Paywall event $paywallEvent");
                  });

              if (result.success) {
                print("Campaign ${campaign.value} launched successfully");
              } else {
                print("Campaign ${campaign.value} launched failed");
              }
            } else {
              print(
                  "Campaign ${campaign.value} is not available on this device.");
            }
            break;
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: Colors.lightBlue)),
        child: Text(
          campaign.type == NamiCampaignRuleType.DEFAULT
              ? "default"
              : campaign.value ?? '',
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget header(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
