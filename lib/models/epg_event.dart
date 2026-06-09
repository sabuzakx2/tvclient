class EpgEvent {
  final int id;
  final String title;
  final String? subtitle;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String? channelUuid;

  EpgEvent({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    required this.start,
    required this.end,
    this.channelUuid,
  });

  factory EpgEvent.fromJson(Map<String, dynamic> json) {
    return EpgEvent(
      id: json['eventId'] ?? 0,
      title: json['title'] ?? '제목 없음',
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      start: DateTime.fromMillisecondsSinceEpoch((json['start'] ?? 0) * 1000),
      end: DateTime.fromMillisecondsSinceEpoch((json['stop'] ?? 0) * 1000),
      channelUuid: json['channelUuid'] as String?,
    );
  }

  bool get isNow {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  double get progress {
    final now = DateTime.now();
    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(end)) return 1.0;
    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    return elapsed / total;
  }

  String get timeRange {
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${fmt(start)} ~ ${fmt(end)}';
  }

  int get durationMinutes => end.difference(start).inMinutes;
}
