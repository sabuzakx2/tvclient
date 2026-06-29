class Channel {
  final String uuid;
  final String name;
  final String? numberStr;
  final int? numberSort;
  final String? iconUrl;
  final List<String> tags;

  Channel({
    required this.uuid,
    required this.name,
    this.numberStr,
    this.numberSort,
    this.iconUrl,
    this.tags = const [],
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    final rawNum = json['number']?.toString() ?? '';
    String? numStr;
    int? numSort;
    if (rawNum.isNotEmpty) {
      numStr = rawNum.contains('.') ? rawNum.replaceAll('.', '-') : rawNum;
      final parts = rawNum.split('.');
      final main = int.tryParse(parts[0]) ?? 9999;
      final sub = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      numSort = main * 100 + sub;
    }
    final rawTags = json['tags'];
    List<String> tags = [];
    if (rawTags is List) tags = rawTags.map((t) => t.toString()).toList();
    return Channel(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '알 수 없음',
      numberStr: numStr,
      numberSort: numSort,
      iconUrl: json['icon_public_url'] as String?,
      tags: tags,
    );
  }
}
