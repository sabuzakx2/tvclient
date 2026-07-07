class StreamProfile {
  final String uuid; // 실제로는 프로파일 이름 (pass, mobile, 720p 등)
  final String name;

  StreamProfile({required this.uuid, required this.name});

  factory StreamProfile.fromJson(Map<String, dynamic> json) {
    // TVHeadend API: key=UUID, val=이름
    // 스트림 URL에는 이름을 사용해야 함
    final name = json['val'] ?? json['name'] ?? '';
    return StreamProfile(uuid: name, name: name);
  }
}
