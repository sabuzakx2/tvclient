import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../models/epg_event.dart';
import '../services/tvh_service.dart';
import 'player_screen.dart';

class NowScreen extends StatefulWidget {
  final String profileUuid;
  final String? tagUuid;
  final Set<String> favorites;

  const NowScreen({
    super.key,
    required this.profileUuid,
    this.tagUuid,
    this.favorites = const {},
  });

  @override
  State<NowScreen> createState() => _NowScreenState();
}

class _NowScreenState extends State<NowScreen> {
  List<_NowItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      await TVHService.instance.loadSettings();
      // 태그 선택돼 있으면 해당 태그 채널만, 아니면 전체
      final channels = await TVHService.instance.getChannels(tagUuid: widget.tagUuid);
      final epgMap = await TVHService.instance.getAllNowPlaying();

      final items = <_NowItem>[];
      for (final ch in channels) {
        final epg = epgMap[ch.uuid];
        if (epg != null && epg.isNow) {
          items.add(_NowItem(channel: ch, event: epg));
        }
      }

      // 즐겨찾기 먼저, 그 다음 채널 번호 순
      items.sort((a, b) {
        final aFav = widget.favorites.contains(a.channel.uuid);
        final bFav = widget.favorites.contains(b.channel.uuid);
        if (aFav && !bFav) return -1;
        if (!aFav && bFav) return 1;
        return (a.channel.numberSort ?? 9999).compareTo(b.channel.numberSort ?? 9999);
      });

      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _play(_NowItem item) {
    final url = TVHService.instance.getStreamUrl(item.channel.uuid, widget.profileUuid);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerScreen(
        channel: item.channel,
        streamUrl: url,
        nowPlaying: item.event,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 8, height: 8,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Text('NOW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(width: 8),
          Text('현재 방송 중 ${_items.isEmpty ? '' : '(${_items.length})'}',
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: Colors.red),
        SizedBox(height: 12),
        Text('현재 방송 중 불러오는 중...', style: TextStyle(color: Colors.grey)),
      ]));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _load, child: const Text('다시 시도')),
      ]));
    }
    if (_items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.tv_off, size: 56, color: Colors.grey),
        const SizedBox(height: 12),
        const Text('현재 방송 중인 EPG 정보가 없어요', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        TextButton(onPressed: _load, child: const Text('새로고침')),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: Colors.red,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          final e = item.event;
          final ch = item.channel;
          final isFav = widget.favorites.contains(ch.uuid);
          final serverUrl = TVHService.instance.baseUrl;
          final iconUrl = ch.iconUrl;
          final hasIcon = iconUrl != null && iconUrl.isNotEmpty;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: InkWell(
              onTap: () => _play(item),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  // 채널 아이콘
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1A2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasIcon
                        ? Image.network('$serverUrl/$iconUrl',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(ch.numberStr ?? '?',
                                  style: const TextStyle(color: Color(0xFF42A5F5),
                                      fontSize: 11, fontWeight: FontWeight.bold))),
                          )
                        : Center(child: Text(ch.numberStr ?? '?',
                            style: const TextStyle(color: Color(0xFF42A5F5),
                                fontSize: 11, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // 채널 번호 + 이름
                    Row(children: [
                      if (isFav) const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.star, color: Colors.amber, size: 12),
                      ),
                      if (ch.numberStr != null)
                        Text('${ch.numberStr}  ',
                            style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      Expanded(child: Text(ch.name,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 2),
                    // 프로그램명
                    Text(e.title,
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (e.subtitle != null)
                      Text(e.subtitle!,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text(e.timeRange,
                          style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      const SizedBox(width: 8),
                      Expanded(child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: e.progress, minHeight: 3,
                          backgroundColor: const Color(0xFF333355),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      )),
                      const SizedBox(width: 8),
                      Text('${((1 - e.progress) * e.durationMinutes).round()}분 남음',
                          style: const TextStyle(color: Colors.red, fontSize: 10)),
                    ]),
                  ])),
                  const SizedBox(width: 8),
                  const Icon(Icons.play_circle, color: Color(0xFF1565C0), size: 32),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NowItem {
  final Channel channel;
  final EpgEvent event;
  _NowItem({required this.channel, required this.event});
}
