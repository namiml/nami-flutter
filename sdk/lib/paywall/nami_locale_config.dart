class NamiLocaleConfig {
  final String closeButtonText;
  final String signInButtonText;
  final String restorePurchaseButtonText;
  final String purchaseTermsPrefixHintTextToSpeech;
  final String purchaseButtonHintTextToSpeech;

  NamiLocaleConfig(
      this.closeButtonText,
      this.signInButtonText,
      this.restorePurchaseButtonText,
      this.purchaseTermsPrefixHintTextToSpeech,
      this.purchaseButtonHintTextToSpeech);

  factory NamiLocaleConfig.fromMap(Map<dynamic, dynamic?> map) {
    return NamiLocaleConfig(
        map['close_button_text'],
        map['sign_in_button_text'],
        map['restore_purchase_button_text'],
        map['purchase_terms_prefix_hint_text_to_speech'],
        map['purchase_button_hint_text_to_speech']);
  }

  @override
  String toString() {
    return 'NamiLocaleConfig{closeButtonText: $closeButtonText, '
        'signInButtonText: $signInButtonText, '
        'restorePurchaseButtonText: $restorePurchaseButtonText, '
        'purchaseTermsPrefixHintTextToSpeech: '
        '$purchaseTermsPrefixHintTextToSpeech, '
        'purchaseButtonHintTextToSpeech: $purchaseButtonHintTextToSpeech}';
  }
}
