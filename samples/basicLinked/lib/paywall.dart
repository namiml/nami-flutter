import 'package:flutter/material.dart';
import 'package:nami_flutter/billing/nami_purchase_manager.dart';
import 'package:nami_flutter/paywall/nami_paywall_manager.dart';
import 'package:nami_flutter/paywall/nami_sku.dart';

class PaywallPage extends StatefulWidget {
  final PaywallRaiseRequestData data;

  const PaywallPage({Key? key, required this.data}) : super(key: key);

  @override
  _PaywallState createState() => _PaywallState();
}

class _PaywallState extends State<PaywallPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: _buildPaywallBody()));
  }

  @override
  void initState() {
    super.initState();
    NamiPaywallManager.blockPaywallAutoRaise(true);
  }

  @override
  void dispose() {
    NamiPaywallManager.blockPaywallAutoRaise(false);
    super.dispose();
  }

  _buildPaywallBody() {
    return Container(
        decoration: _getBackgroundImageDecoration(),
        child: Container(
          margin: const EdgeInsets.only(top: 96),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [_buildTitle(), _buildDescription(), _buildSkuButtons()],
          ),
        ));
  }

  Widget _buildDescription() {
    return Container(
        margin: const EdgeInsets.only(top: 16),
        child: Text(
          widget.data.namiPaywall.body ?? "",
          textAlign: TextAlign.center,
          style: TextStyle(
              color:
                  widget.data.namiPaywall.styleData?.bodyTextColor.hexToColor(),
              fontSize: widget.data.namiPaywall.styleData?.bodyFontSize,
              fontWeight: FontWeight.bold),
        ));
  }

  Widget _buildTitle() {
    return Text(
      widget.data.namiPaywall.title ?? "",
      textAlign: TextAlign.center,
      style: TextStyle(
          color: widget.data.namiPaywall.styleData?.titleTextColor.hexToColor(),
          fontSize: widget.data.namiPaywall.styleData?.titleFontSize,
          fontWeight: FontWeight.bold),
    );
  }

  Decoration _getBackgroundImageDecoration() {
    return BoxDecoration(
        image: DecorationImage(
            image: NetworkImage(
                widget.data.namiPaywall.backgroundImageUrlPhone ?? ""),
            fit: BoxFit.fill));
  }

  Widget _buildSkuButtons() {
    var widgetList = <Widget>[];
    var buttonBgColor =
        widget.data.namiPaywall.styleData?.skuButtonColor.hexToColor();
    var buttonBgTextColor =
        widget.data.namiPaywall.styleData?.skuButtonTextColor.hexToColor();
    widget.data.skus.forEach((element) {
      var button = Padding(
        padding: EdgeInsets.only(bottom: 8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              primary: buttonBgColor, onPrimary: buttonBgTextColor),
          onPressed: () async {
            _buySKU(element.skuId);
          },
          child: Text(
              "${element.price} / ${element.periodUnit.toDisplayString()}",
              style: TextStyle(fontSize: 18)),
        ),
      );
      widgetList.add(button);
    });
    return Expanded(
        child: Container(
            margin: const EdgeInsets.only(bottom: 48),
            child: Padding(
                padding: EdgeInsets.only(left: 32.0, right: 32.0),
                child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widgetList))));
  }

  void _buySKU(String skuRefId) async {
    NamiPurchaseCompleteResult result =
        await NamiPurchaseManager.buySKU(skuRefId);
    print('Purchase Complete with state ${result.purchaseState}--');
    if (result.purchaseState == NamiPurchaseState.purchased) {
      Navigator.pop(context);
    }
  }
}

extension on String {
  Color hexToColor() {
    return new Color(int.parse(this.substring(1, 7), radix: 16) + 0xFF000000);
  }
}

extension on PeriodUnit {
  String toDisplayString() {
    switch (this) {
      case PeriodUnit.not_used:
        return "Error";
      case PeriodUnit.day:
        return "Day";
      case PeriodUnit.weekly:
        return "Week";
      case PeriodUnit.monthly:
        return "Month";
      case PeriodUnit.quarterly:
        return "3 months";
      case PeriodUnit.half_year:
        return "6 months";
      case PeriodUnit.annual:
        return "year";
    }
  }
}
