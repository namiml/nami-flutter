class NamiPaywall {
  final String id;
  final String type;
  final Map<dynamic, dynamic>? extraData;
  final List<String> namiSkus;

  NamiPaywall(
      this.id,
      this.type,
      this.extraData,
      this.namiSkus);

  factory NamiPaywall.fromMap(Map<dynamic, dynamic> map) {
    List<dynamic> dynamicSkus = map['namiSkus'];
    List<String> namiSkus = List.empty(growable: true);
    dynamicSkus.forEach((element) {
      namiSkus.add(element.toString());
    });

    return NamiPaywall(
        map['id'],
        map['type'],
        map['extraData'],
        namiSkus);
  }
}
