class FormattedSku {
  final String skuId;
  final bool featured;

  /// iOS only
  final int presentationPosition;

  FormattedSku(this.skuId, this.featured, this.presentationPosition);

  factory FormattedSku.fromMap(Map<dynamic, dynamic> map) {
    return FormattedSku(
        map['skuId'], map['featured'], map['presentationPosition']);
  }

  @override
  String toString() {
    return 'FormattedSku{skuId: $skuId, featured: $featured, presentationPosition: $presentationPosition}';
  }
}