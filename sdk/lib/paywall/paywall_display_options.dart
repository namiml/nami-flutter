class PaywallDisplayOptions {
  final bool allowClosing;
  final bool restoreControl;
  final bool signInControl;
  final bool useBottomOverlay;
  final String scrollableRegionSize;
  final bool shouldShowNamiPurchaseSuccessMessage;
  final bool showSkusInScrollableRegion;

  PaywallDisplayOptions(
      this.allowClosing,
      this.restoreControl,
      this.signInControl,
      this.useBottomOverlay,
      this.scrollableRegionSize,
      this.shouldShowNamiPurchaseSuccessMessage,
      this.showSkusInScrollableRegion);

  factory PaywallDisplayOptions.fromMap(Map<dynamic, dynamic> map) {
    return PaywallDisplayOptions(
        map['allow_closing'],
        map['restore_control'],
        map['sign_in_control'],
        map['use_bottom_overlay'],
        map['scrollable_region_size'],
        map['show_nami_purchase_success_message'],
        map['skus_in_scrollable_region']);
  }

  @override
  String toString() {
    return 'PaywallDisplayOptions{allowClosing: $allowClosing, '
        'restoreControl: $restoreControl, signInControl: $signInControl, '
        'useBottomOverlay: $useBottomOverlay, '
        'scrollableRegionSize: $scrollableRegionSize, '
        'shouldShowNamiPurchaseSuccessMessage: '
        '$shouldShowNamiPurchaseSuccessMessage, '
        'showSkusInScrollableRegion: $showSkusInScrollableRegion}';
  }
}
