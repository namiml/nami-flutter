class FormattedSku {
  final String id;
  final bool featured;

  /// iOS only
  final int presentationPosition;

  FormattedSku(this.id, this.featured, this.presentationPosition);

  factory FormattedSku.fromMap(Map<dynamic, dynamic> map) {
    return FormattedSku(
        map['id'], map['featured'], map['presentationPosition']);
  }

  @override
  String toString() {
    return 'FormattedSku{id: $id, featured: $featured, presentationPosition: $presentationPosition}';
  }
}
