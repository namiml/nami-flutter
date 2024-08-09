class NamiPaywallEventComponentChange {
  String? id;
  String? name;

  NamiPaywallEventComponentChange(this.id, this.name);

  factory NamiPaywallEventComponentChange.fromMap(Map<dynamic, dynamic> map) {
    return NamiPaywallEventComponentChange(map['id'], map['name']);
  }
}
