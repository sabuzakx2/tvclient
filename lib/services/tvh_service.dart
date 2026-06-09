import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../models/channel_tag.dart';
import '../models/epg_event.dart';
import '../models/profile.dart';

class TVHService {
  static TVHService? _instance;
  static TVHService get instance => _instance ??= TVHService._();
  TVHService._();

  String _baseUrl = '';
  String _username = '';
  String _password = '';

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = (prefs.getString('server_url') ?? '').trimRight().replaceAll(RegExp(r'/$'), '');
    _username = prefs.getString('username') ?? '';
    _password = prefs.getString('password') ?? '';
  }

  Map<String, String> get _headers {
    if (_username.isNotEmpty) {
      final credentials = base64Encode(utf8.encode('$_username:$_password'));
      return {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  Future<http.Response> _get(String path) async {
    await loadSettings();
    final uri = Uri.parse('$_baseUrl$path');
    return http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
  }

  Future<bool> testConnection() async {
    try {
      final resp = await _get('/api/serverinfo');
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Channel>> getChannels({String? tagUuid}) async {
    // TVHeadend API: 태그 필터링은 filter 파라미터 사용
    String url = '/api/channel/grid?limit=2000&offset=0&sort=number&dir=ASC';
    if (tagUuid != null && tagUuid.isNotEmpty) {
      // TVHeadend uses filter with tags field
      final filter = jsonEncode([{"field": "tags", "type": "string", "value": tagUuid}]);
      url += '&filter=${Uri.encodeComponent(filter)}';
    }
    final resp = await _get(url);
    if (resp.statusCode != 200) throw Exception('채널 로드 실패: ${resp.statusCode}');
    final data = jsonDecode(resp.body);
    final entries = data['entries'] as List? ?? [];
    return entries.map((e) => Channel.fromJson(e)).toList()
      ..sort((a, b) => (a.number ?? 9999).compareTo(b.number ?? 9999));
  }

  Future<List<ChannelTag>> getChannelTags() async {
    try {
      final resp = await _get('/api/channeltag/grid?limit=500&offset=0');
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body);
      final entries = data['entries'] as List? ?? [];
      final tags = entries.map((e) => ChannelTag.fromJson(e)).toList();
      tags.sort((a, b) => (a.index ?? 9999).compareTo(b.index ?? 9999));
      return tags;
    } catch (_) {
      return [];
    }
  }

  Future<List<EpgEvent>> getEpg(String channelUuid, {int hours = 12}) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final end = now + (hours * 3600);
      // TVHeadend EPG API - channel UUID 정확히 전달
      final resp = await _get(
        '/api/epg/events/grid?limit=50&channel=$channelUuid&start=$now&stop=$end',
      );
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body);
      final entries = data['entries'] as List? ?? [];
      return entries.map((e) => EpgEvent.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // 현재 방영중인 EPG만 가져오기
  Future<EpgEvent?> getNowPlaying(String channelUuid) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final resp = await _get(
        '/api/epg/events/grid?limit=5&channel=$channelUuid&start=${now - 7200}&stop=${now + 60}',
      );
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body);
      final entries = data['entries'] as List? ?? [];
      final events = entries.map((e) => EpgEvent.fromJson(e)).toList();
      return events.where((e) => e.isNow).firstOrNull;
    } catch (_) {
      return null;
    }
  }

  Future<List<StreamProfile>> getProfiles() async {
    try {
      final resp = await _get('/api/profile/list');
      if (resp.statusCode != 200) return _defaultProfiles();
      final data = jsonDecode(resp.body);
      final entries = data['entries'] as List? ?? [];
      if (entries.isEmpty) return _defaultProfiles();
      return entries.map((e) => StreamProfile.fromJson(e)).toList();
    } catch (_) {
      return _defaultProfiles();
    }
  }

  List<StreamProfile> _defaultProfiles() => [
    StreamProfile(uuid: 'pass', name: 'pass (원본)'),
    StreamProfile(uuid: 'htsp', name: 'htsp (기본)'),
  ];

  String getStreamUrl(String channelUuid, String profileUuid) {
    final profileParam = profileUuid.isNotEmpty ? '?profile=$profileUuid' : '';
    if (_username.isNotEmpty) {
      final uri = Uri.parse(_baseUrl);
      return '${uri.scheme}://$_username:$_password@${uri.host}:${uri.port}'
             '/stream/channel/$channelUuid$profileParam';
    }
    return '$_baseUrl/stream/channel/$channelUuid$profileParam';
  }

  String get baseUrl => _baseUrl;
}
