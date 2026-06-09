class Channel {
  final String uuid;
  final String name;
  final int? number;
  final String? iconUrl;

  Channel({
    required this.uuid,
    required this.name,
    this.number,
    this.iconUrl,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '알 수 없음',
      number: json['number'] is int ? json['number'] : int.tryParse('${json['number'] ?? ''}'),
      iconUrl: json['icon_public_url'] as String?,
    );
  }
}
