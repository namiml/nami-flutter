import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nami_flutter/campaign/nami_campaign.dart';
import 'package:nami_flutter/campaign/nami_campaign_manager.dart';
import 'package:nami_flutter/customer/nami_customer_manager.dart';
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
  ProductDetails? productDetails;
  final List<StreamSubscription> _subscriptions = [];

  StreamSubscription? _purchaseStreamSubscription;
  final InAppPurchase inAppPurchase = InAppPurchase.instance;

  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        InAppPurchase.instance.purchaseStream;

    _purchaseStreamSubscription =
        purchaseUpdated.listen((purchaseDetailList) async {
      await _listenToPurchaseUpdated(purchaseDetailList);
    }, onDone: () {
      _purchaseStreamSubscription?.cancel();
    }, onError: (error) {
      print('Error: $error');
    });

    _subscriptions.add(_purchaseStreamSubscription!);

    StreamSubscription availableCampaignStreamSubscription =
        NamiCampaignManager.registerAvailableCampaignsHandler().listen((list) {
      setState(() {
        print("registerAvailableCampaignsHandler triggered");
        _campaigns = list;
      });
    });

    _subscriptions.add(availableCampaignStreamSubscription);

    NamiCampaignManager.allCampaigns().then((list) {
      setState(() {
        _campaigns = list;
      });
    });

    NamiCustomerManager.setCustomerAttribute({"creatorCode": "Taylor"});

    StreamSubscription restoreStateSubscription =
        NamiPaywallManager.registerRestoreHandler().listen((event) async {
      await inAppPurchase.restorePurchases();
    });
    _subscriptions.add(restoreStateSubscription);

    initStoreInfo();
  }

  @override
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await inAppPurchase.isAvailable();

    if (isAvailable) {
      NamiPaywallManager.registerBuySkuHandler().listen((sku) async {
        identifiers.addAll(Map.of({sku.skuId: sku}));
        ProductDetailsResponse productDetailsResponse =
            await inAppPurchase.queryProductDetails({sku.skuId});
        productDetails = productDetailsResponse.productDetails.where((ProductDetails product) => product.id == sku.skuId).first;
        await _buyProduct(sku, productDetails!);
      });
    }
  }

  //To buy any Product
  Future<void> _buyProduct(NamiSKU sku, ProductDetails productDetails) async {
    PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    if (sku.type == NamiSKUType.subscription) {
      await inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      await inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    if (purchaseDetailsList.isNotEmpty) {
      for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
        if (purchaseDetails.pendingCompletePurchase) {
          await inAppPurchase.completePurchase(purchaseDetails);
        }
        if (purchaseDetails.status == PurchaseStatus.purchased) {
          NamiSKU namiSku = identifiers[purchaseDetails.productID]!;
          final namiPurchaseSuccess = Platform.isIOS
              ? handleiOSPurchase(namiSku, purchaseDetails)
              : handleAndroidPurchase(namiSku, purchaseDetails);
          if (namiPurchaseSuccess != null) {
            await NamiPaywallManager.buySkuComplete(namiPurchaseSuccess);
            await inAppPurchase.completePurchase(purchaseDetails);
          }
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          await NamiPaywallManager.buySkuCancel();
        }
      }
    }
  }

  NamiPurchaseSuccess? handleAndroidPurchase(
      NamiSKU sku, PurchaseDetails purchaseDetails) {
    NamiPurchaseSuccess? namiPurchaseSuccessGoogle;
    GooglePlayPurchaseDetails googlePlayPurchaseDetails =
        purchaseDetails as GooglePlayPurchaseDetails;
    namiPurchaseSuccessGoogle = NamiPurchaseSuccessGoogle(
        NamiSKU(sku.name, sku.skuId, sku.type, sku.id),
        googlePlayPurchaseDetails.purchaseID!,
        googlePlayPurchaseDetails.billingClientPurchase.purchaseToken);
    return namiPurchaseSuccessGoogle;
  }

  NamiPurchaseSuccess? handleiOSPurchase(
      NamiSKU sku, PurchaseDetails purchaseDetail) {
    NamiPurchaseSuccess? namiPurchaseSuccessApple;
    AppStoreProductDetails appStoreProductDetails =
        productDetails as AppStoreProductDetails;
    AppStorePurchaseDetails appStorePurchaseDetails =
        purchaseDetail as AppStorePurchaseDetails;
    namiPurchaseSuccessApple = NamiPurchaseSuccessApple(
      NamiSKU(sku.name, sku.skuId, sku.type, sku.id),
      appStorePurchaseDetails.purchaseID!,
      appStorePurchaseDetails.skPaymentTransaction.transactionIdentifier!,
      appStoreProductDetails.skProduct.price,
      appStoreProductDetails.currencyCode,
    );
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
            icon: const Icon(Icons.refresh),
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
                    print("Paywall event ${paywallEvent.toString()}");
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
                    print("Paywall event ${paywallEvent.toString()}");
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
