class PaywallStyleData {
  final double bodyFontSize;

  /// In `"#RRGGBB"` format
  final String bodyTextColor;
  final double titleFontSize;

  /// In `"#RRGGBB"` format
  final String backgroundColor;

  /// In `"#RRGGBB"` format
  final String skuButtonColor;

  /// In `"#RRGGBB"` format
  final String skuButtonTextColor;

  /// In `"#RRGGBB"` format
  final String termsLinkColor;

  /// In `"#RRGGBB"` format
  final String titleTextColor;

  /// In `"#RRGGBB"` format
  final String bodyShadowColor;
  final double bodyShadowRadius;

  /// In `"#RRGGBB"` format
  final String titleShadowColor;
  final double titleShadowRadius;

  /// In `"#RRGGBB"` format
  final String bottomOverlayColor;
  final double bottomOverlayCornerRadius;
  final double closeButtonFontSize;

  /// In `"#RRGGBB"` format
  final String closeButtonTextColor;

  /// In `"#RRGGBB"` format
  final String closeButtonShadowColor;
  final double closeButtonShadowRadius;
  final double signInButtonFontSize;

  /// In `"#RRGGBB"` format
  final String signInButtonTextColor;

  /// In `"#RRGGBB"` format
  final String signInButtonShadowColor;
  final double signInButtonShadowRadius;
  final double purchaseTermsFontSize;

  /// In `"#RRGGBB"` format
  final String purchaseTermsTextColor;

  /// In `"#RRGGBB"` format
  final String purchaseTermsShadowColor;
  final double purchaseTermsShadowRadius;
  final double restoreButtonFontSize;
  final String restoreButtonTextColor;

  /// In `"#RRGGBB"` format
  final String restoreButtonShadowColor;
  final double restoreButtonShadowRadius;

  /// In `"#RRGGBB"` format
  final String featuredSkuButtonColor;

  /// In `"#RRGGBB"` format
  final String featuredSkuButtonTextColor;

  PaywallStyleData(
      this.bodyFontSize,
      this.bodyTextColor,
      this.titleFontSize,
      this.backgroundColor,
      this.skuButtonColor,
      this.skuButtonTextColor,
      this.termsLinkColor,
      this.titleTextColor,
      this.bodyShadowColor,
      this.bodyShadowRadius,
      this.titleShadowColor,
      this.titleShadowRadius,
      this.bottomOverlayColor,
      this.bottomOverlayCornerRadius,
      this.closeButtonFontSize,
      this.closeButtonTextColor,
      this.closeButtonShadowColor,
      this.closeButtonShadowRadius,
      this.signInButtonFontSize,
      this.signInButtonTextColor,
      this.signInButtonShadowColor,
      this.signInButtonShadowRadius,
      this.purchaseTermsFontSize,
      this.purchaseTermsTextColor,
      this.purchaseTermsShadowColor,
      this.purchaseTermsShadowRadius,
      this.restoreButtonFontSize,
      this.restoreButtonTextColor,
      this.restoreButtonShadowColor,
      this.restoreButtonShadowRadius,
      this.featuredSkuButtonColor,
      this.featuredSkuButtonTextColor);

  factory PaywallStyleData.fromMap(Map<dynamic, dynamic> map) {
    return PaywallStyleData(
        map['bodyFontSize'],
        map['bodyTextColor'],
        map['titleFontSize'],
        map['backgroundColor'],
        map['skuButtonColor'],
        map['skuButtonTextColor'],
        map['termsLinkColor'],
        map['titleTextColor'],
        map['bodyShadowColor'],
        map['bodyShadowRadius'],
        map['titleShadowColor'],
        map['titleShadowRadius'],
        map['bottomOverlayColor'],
        map['bottomOverlayCornerRadius'],
        map['closeButtonFontSize'],
        map['closeButtonTextColor'],
        map['closeButtonShadowColor'],
        map['closeButtonShadowRadius'],
        map['signInButtonFontSize'],
        map['signInButtonTextColor'],
        map['signInButtonShadowColor'],
        map['signInButtonShadowRadius'],
        map['purchaseTermsFontSize'],
        map['purchaseTermsTextColor'],
        map['purchaseTermsShadowColor'],
        map['purchaseTermsShadowRadius'],
        map['restoreButtonFontSize'],
        map['restoreButtonTextColor'],
        map['restoreButtonShadowColor'],
        map['restoreButtonShadowRadius'],
        map['featuredSkuButtonColor'],
        map['featuredSkuButtonTextColor']);
  }

  @override
  String toString() {
    return 'PaywallStyleData{bodyFontSize: $bodyFontSize, bodyTextColor: $bodyTextColor, titleFontSize: $titleFontSize, backgroundColor: $backgroundColor, skuButtonColor: $skuButtonColor, skuButtonTextColor: $skuButtonTextColor, termsLinkColor: $termsLinkColor, titleTextColor: $titleTextColor, bodyShadowColor: $bodyShadowColor, bodyShadowRadius: $bodyShadowRadius, titleShadowColor: $titleShadowColor, titleShadowRadius: $titleShadowRadius, bottomOverlayColor: $bottomOverlayColor, bottomOverlayCornerRadius: $bottomOverlayCornerRadius, closeButtonFontSize: $closeButtonFontSize, closeButtonTextColor: $closeButtonTextColor, closeButtonShadowColor: $closeButtonShadowColor, closeButtonShadowRadius: $closeButtonShadowRadius, signInButtonFontSize: $signInButtonFontSize, signInButtonTextColor: $signInButtonTextColor, signInButtonShadowColor: $signInButtonShadowColor, signInButtonShadowRadius: $signInButtonShadowRadius, purchaseTermsFontSize: $purchaseTermsFontSize, purchaseTermsTextColor: $purchaseTermsTextColor, purchaseTermsShadowColor: $purchaseTermsShadowColor, purchaseTermsShadowRadius: $purchaseTermsShadowRadius, restoreButtonFontSize: $restoreButtonFontSize, restoreButtonTextColor: $restoreButtonTextColor, restoreButtonShadowColor: $restoreButtonShadowColor, restoreButtonShadowRadius: $restoreButtonShadowRadius, featuredSkuButtonColor: $featuredSkuButtonColor, featuredSkuButtonTextColor: $featuredSkuButtonTextColor}';
  }
}
