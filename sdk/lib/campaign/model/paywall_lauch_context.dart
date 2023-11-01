class PaywallLaunchContext {
  List<String>? productGroups;
  Map<String, dynamic>? customAttributes = {};
  Map<String, dynamic> urlQueryParams = {};

  PaywallLaunchContext(this.productGroups, this.customAttributes);

  factory PaywallLaunchContext.fromJson(Map<dynamic, dynamic> map) {
    return PaywallLaunchContext(
        map['productGroups'] != null
            ? List<String>.from(map['productGroups'])
            : null,
        map['customAttributes'] != null
            ? Map<String, dynamic>.from(map['customAttributes'])
            : null);
  }
}
