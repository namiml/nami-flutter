import 'package:flutter/material.dart';
import 'package:nami_flutter/campaign/nami_campaign.dart';
import 'package:nami_flutter/campaign/nami_campaign_manager.dart';

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
        _campaigns = list;
      });
    });

    NamiCampaignManager.allCampaigns().then((list) {
      setState(() {
        _campaigns = list;
      });
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
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
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
    );
  }

  Widget campaignItem(NamiCampaign campaign) {
    return InkWell(
      onTap: () async {
        LaunchCampaignResult result;
        switch (campaign.type) {
          case NamiCampaignRuleType.DEFAULT:
            result = await NamiCampaignManager.launch();
            break;
          case NamiCampaignRuleType.LABEL:
            result = await NamiCampaignManager.launch(label: campaign.value);
            break;
        }

        if (result.success) {
          print("Campaign ${campaign.value} launched successfully");
        } else {
          print("Campaign ${campaign.value} launched failed");
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: Colors.lightBlue)),
        child: Text(
          campaign.type == NamiCampaignRuleType.DEFAULT
              ? "Default"
              : campaign.value ?? '',
          style: const TextStyle(fontSize: 20),
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
