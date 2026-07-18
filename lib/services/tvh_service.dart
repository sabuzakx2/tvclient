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

  Map<String, EpgEvent?> _epgCache = {};
  DateTime? _epgCacheTime;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _baseUrl = (prefs.getString('server_url') ?? '')
        .trim()
        .replaceAll(RegExp(r'/$'), '');

    _username = prefs.getString('username') ?? '';
    _password = prefs.getString('password') ?? '';
  }

  Map<String, String> get _headers {
    if (_username.isNotEmpty) {
      final credentials = base64Encode(
        utf8.encode('$_username:$_password'),
      );

      return {
        'Authorization': 'Basic $credentials',
      };
    }

    return {};
  }

  Future<http.Response> _get(String path) async {
    await loadSettings();

    final uri = Uri.parse('$_baseUrl$path');

    return http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 30));
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
    String url = '/api/channel/grid?limit=2000&offset=0';

    if (tagUuid != null && tagUuid.isNotEmpty) {
      url += '&tag=${Uri.encodeQueryComponent(tagUuid)}';
    }

    final resp = await _get(url);

    if (resp.statusCode != 200) {
      throw Exception('채널 로드 실패: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    final entries = data['entries'] as List? ?? [];

    List<Channel> channels =
        entries.map((e) => Channel.fromJson(e)).toList();

    if (tagUuid != null && tagUuid.isNotEmpty) {
      channels = channels
          .where((channel) => channel.tags.contains(tagUuid))
          .toList();
    }

    channels.sort(
      (a, b) => (a.numberSort ?? 9999).compareTo(b.numberSort ?? 9999),
    );

    return channels;
  }

  Future<List<ChannelTag>> getChannelTags() async {
    try {
      final resp = await _get('/api/channeltag/grid?limit=500');

      if (resp.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(resp.body);
      final entries = data['entries'] as List? ?? [];

      return entries.map((e) => ChannelTag.fromJson(e)).toList()
        ..sort(
          (a, b) => (a.index ?? 9999).compareTo(b.index ?? 9999),
        );
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, EpgEvent?>> getAllNowPlaying() async {
    if (_epgCacheTime != null &&
        DateTime.now().difference(_epgCacheTime!).inMinutes < 5 &&
        _epgCache.isNotEmpty) {
      return _epgCache;
    }

    try {
      final resp = await _get('/api/epg/events/grid?limit=500');

      if (resp.statusCode != 200) {
        return {};
      }

      final data = jsonDecode(resp.body);
      final entries = data['entries'] as List? ?? [];

      final events = entries.map((e) => EpgEvent.fromJson(e)).toList();

      final Map<String, EpgEvent?> result = {};

      for (final event in events) {
        if (event.channelUuid == null) {
          continue;
        }

        if (event.isNow) {
          result[event.channelUuid!] = event;
        }
      }

      _epgCache = result;
      _epgCacheTime = DateTime.now();

      return result;
    } catch (_) {
      return {};
    }
  }

  Future<List<EpgEvent>> getEpg(
    String channelUuid, {
    int hours = 12,
  }) async {
    try {
      final resp = await _get('/api/epg/events/grid?limit=500');

      if (resp.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(resp.body);
      final entries = data['entries'] as List? ?? [];

      final events = entries.map((e) => EpgEvent.fromJson(e)).toList();

      return events
          .where((event) => event.channelUuid == channelUuid)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<StreamProfile>> getProfiles() async {
    try {
      final resp = await _get('/api/profile/list');

      if (resp.statusCode != 200) {
        return _defaultProfiles();
      }

      final dynamic data = jsonDecode(resp.body);

      List<dynamic> entries = [];

      if (data is Map<String, dynamic>) {
        final rawEntries = data['entries'];

        if (rawEntries is List) {
          entries = rawEntries;
        }
      } else if (data is List) {
        entries = data;
      }

      final profiles = entries
          .whereType<Map>()
          .map(
            (entry) => StreamProfile.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .where((profile) => profile.uuid.isNotEmpty)
          .toList();

      if (profiles.isEmpty) {
        return _defaultProfiles();
      }

      profiles.sort((a, b) {
        if (a.uuid == 'pass') return -1;
        if (b.uuid == 'pass') return 1;
        return a.name.compareTo(b.name);
      });

      return profiles;
    } catch (_) {
      return _defaultProfiles();
    }
  }

  List<StreamProfile> _defaultProfiles() => [
        StreamProfile(
          uuid: 'pass',
          name: 'pass (원본)',
        ),
        StreamProfile(
          uuid: 'htsp',
          name: 'htsp (기본)',
        ),
      ];

  String getStreamUrl(String channelUuid, String profileUuid) {
    final baseUri = Uri.parse(_baseUrl);

    final streamPath = '${baseUri.path}/stream/channel/$channelUuid'
        .replaceAll(RegExp(r'//+'), '/');

    final queryParameters = <String, String>{};

    if (profileUuid.isNotEmpty) {
      queryParameters['profile'] = profileUuid;
    }

    Uri streamUri = baseUri.replace(
      path: streamPath,
      queryParameters:
          queryParameters.isEmpty ? null : queryParameters,
    );

    if (_username.isNotEmpty) {
      streamUri = streamUri.replace(
        userInfo: '$_username:$_password',
      );
    }

    return streamUri.toString();
  }

  String get baseUrl => _baseUrl;
}
