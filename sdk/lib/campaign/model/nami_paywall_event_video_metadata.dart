class NamiPaywallEventVideoMetadata {
  String? id;
  String? name;
  String? url;
  bool loopVideo;
  bool muteByDefault;
  bool autoplayVideo;
  double? contentTimeCode;
  double? contentDuration;

  NamiPaywallEventVideoMetadata(
      {this.id,
      this.name,
      this.url,
      this.loopVideo = false,
      this.muteByDefault = false,
      this.autoplayVideo = false,
      this.contentTimeCode,
      this.contentDuration});

  factory NamiPaywallEventVideoMetadata.fromMap(Map<dynamic, dynamic> map) {
    return NamiPaywallEventVideoMetadata(
      id: map['id'],
      name: map['name'],
      url: map['url'],
      loopVideo: map['loopVideo'],
      muteByDefault: map['muteByDefault'],
      autoplayVideo: map['autoplayVideo'],
      contentTimeCode: map['contentTimeCode'],
      contentDuration: map['contentDuration'],
    );
  }

  @override
  String toString() {
    return 'NamiPaywallEventVideoMetadata{id: $id, name: $name, url: $url,'
        ' loopVideo: $loopVideo, muteByDefault: $muteByDefault, autoplayVideo: $autoplayVideo,'
        ' contentTimeCode: $contentTimeCode, contentDuration: $contentDuration}';
  }
}
