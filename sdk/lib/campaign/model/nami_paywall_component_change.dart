class NamiPaywallComponentChange {
  String? id;
  String? name;

  NamiPaywallComponentChange(this.id, this.name);

  factory NamiPaywallComponentChange.fromMap(Map<dynamic, dynamic> map) {
    return NamiPaywallComponentChange(map['id'], map['name']);
  }
}
