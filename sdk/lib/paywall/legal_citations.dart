class LegalCitations {
  final String id;
  final String? tosText;
  final String tosUrl;
  final String? privacyText;
  final String? privacyUrl;
  final String language;
  final String clickWrapText;

  LegalCitations(this.id, this.tosText, this.tosUrl, this.privacyText,
      this.privacyUrl, this.language, this.clickWrapText);

  factory LegalCitations.fromMap(Map<dynamic, dynamic> map) {
    return LegalCitations(
        map['id'],
        map['tos_text'],
        map['tos_url'],
        map['privacy_text'],
        map['privacy_url'],
        map['language'],
        map['clickwrap_text']);
  }

  @override
  String toString() {
    return 'LegalCitations{id: $id, tosText: $tosText, tosUrl: $tosUrl, '
        'privacyText: $privacyText, privacyUrl: $privacyUrl, '
        'language: $language, clickWrapText: $clickWrapText}';
  }
}
