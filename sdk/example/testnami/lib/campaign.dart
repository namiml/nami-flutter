import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nami_flutter/billing/nami_purchase.dart';
import 'package:nami_flutter/campaign/nami_campaign.dart';
import 'package:nami_flutter/campaign/nami_campaign_manager.dart';
import 'package:nami_flutter/paywall/nami_paywall_manager.dart';
import 'package:nami_flutter/paywall/nami_purchase_success.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';
import 'package:testnami/constants.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

class CampaignWidget extends StatefulWidget {
  const CampaignWidget({Key? key}) : super(key: key);

  @override
  CampaignWidgetState createState() => CampaignWidgetState();
}

class CampaignWidgetState extends State<CampaignWidget> {
  List<NamiCampaign> _campaigns = [];
  Map<String, NamiSKU> identifiers = {};
  List<ProductDetails> productDetails = [];
  ProductDetails? productDetail;

  late final StreamSubscription<List<PurchaseDetails>> _subscription;
  final InAppPurchase inAppPurchase = InAppPurchase.instance;

  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> _purchaseUpdated =
        InAppPurchase.instance.purchaseStream;
    _subscription = _purchaseUpdated.listen((purchaseDetailList) {
      _listenToPurchaseUpdated(purchaseDetailList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      print(error.toString());
    });

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
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await inAppPurchase.isAvailable();
    if (isAvailable) {
      NamiPaywallManager.registerBuySkuHandler().listen((sku) async {
        identifiers.addAll(Map.of({sku.skuId: sku}));
        ProductDetailsResponse productDetailsResponse =
            await inAppPurchase.queryProductDetails({sku.skuId});
        productDetails = productDetailsResponse.productDetails;
        _buyProduct(sku, productDetails.first);
      });
    }
  }

  //To buy any Product
  Future<void> _buyProduct(NamiSKU sku, ProductDetails productDetails) async {
    PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetail!);
    if (sku.type == NamiSKUType.subscription) {
      await inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      await inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    if (purchaseDetailsList.isNotEmpty) {
      for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
        if (!purchaseDetails.pendingCompletePurchase) continue;
        if (purchaseDetails.status == PurchaseStatus.purchased) {
          NamiSKU namiSku = identifiers[purchaseDetails.productID]!;
          final namiPurchaseSuccess = Platform.isIOS
              ? handleiOSPurchase(namiSku, purchaseDetails)
              : handleAndroidPurchase(namiSku, purchaseDetails);
          if (namiPurchaseSuccess != null) {
            NamiPaywallManager.buySkuComplete(namiPurchaseSuccess);
          }
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          NamiPaywallManager.buySkuCancel();
        }
      }
    }
  }

  NamiPurchaseSuccess? handleAndroidPurchase(
      NamiSKU sku, PurchaseDetails purchaseDetails) {
    NamiPurchaseSuccess? namiPurchaseSuccessGoogle;
    GooglePlayPurchaseDetails googlePlayPurchaseDetails =
        purchaseDetails as GooglePlayPurchaseDetails;
    GooglePlayProductDetails googlePlayProductDetails =
        productDetails as GooglePlayProductDetails;
    namiPurchaseSuccessGoogle = NamiPurchaseSuccessGoogle(
        NamiSKU(sku.name, sku.skuId, sku.type),
        null,
        googlePlayPurchaseDetails.transactionDate!,
        NamiPurchaseSource.campaign,
        googlePlayProductDetails.description,
        googlePlayPurchaseDetails.purchaseID!,
        googlePlayPurchaseDetails.verificationData.serverVerificationData);
    return namiPurchaseSuccessGoogle;
  }

  NamiPurchaseSuccess? handleiOSPurchase(
      NamiSKU sku, PurchaseDetails purchaseDetail) {
    NamiPurchaseSuccess? namiPurchaseSuccessApple;
    AppStoreProductDetails appStoreProductDetails =
        productDetails as AppStoreProductDetails;
    AppStorePurchaseDetails appStorePurchaseDetails =
        purchaseDetail as AppStorePurchaseDetails;
    final originalTransaction =
        appStorePurchaseDetails.skPaymentTransaction.originalTransaction;
    if (originalTransaction != null) {
      namiPurchaseSuccessApple = NamiPurchaseSuccessApple(
          NamiSKU(sku.name, sku.skuId, sku.type),
          null,
          appStorePurchaseDetails.transactionDate!,
          NamiPurchaseSource.campaign,
          appStorePurchaseDetails.purchaseID!,
          originalTransaction.transactionIdentifier!,
          originalTransaction.transactionTimeStamp.toString(),
          appStoreProductDetails.price,
          appStoreProductDetails.currencyCode,
          appStoreProductDetails.skProduct.priceLocale.countryCode);
    }
    return namiPurchaseSuccessApple;
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
            label: const Text("Refresh"),
            icon: Icon(Icons.refresh),
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
          case NamiCampaignRuleType.URL:
          // TODO: Handle this case.
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
