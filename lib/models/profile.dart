class StreamProfile {
  final String uuid;
  final String name;

  StreamProfile({required this.uuid, required this.name});

  factory StreamProfile.fromJson(Map<String, dynamic> json) {
    return StreamProfile(
      uuid: json['key'] ?? json['uuid'] ?? '',
      name: json['val'] ?? json['name'] ?? '알 수 없음',
    );
  }
}
