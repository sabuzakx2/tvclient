class ChannelTag {
  final String uuid;
  final String name;
  final int? index;

  ChannelTag({required this.uuid, required this.name, this.index});

  factory ChannelTag.fromJson(Map<String, dynamic> json) {
    return ChannelTag(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '알 수 없음',
      index: json['index'] as int?,
    );
  }
}
