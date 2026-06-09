import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tvh_service.dart';
import '../models/channel.dart';
import '../models/channel_tag.dart';
import '../models/epg_event.dart';
import '../models/profile.dart';
import 'player_screen.dart';
import 'setup_screen.dart';
import 'now_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Channel> _channels = [];
  List<Channel> _filtered = [];
  List<ChannelTag> _tags = [];
  List<StreamProfile> _profiles = [];
  String _selectedProfileUuid = '';
  String _selectedProfileName = 'pass';
  String? _selectedTagUuid;
  String _selectedTagName = '전체';
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  Map<String, EpgEvent?> _nowPlaying = {};
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _load();
    _searchCtrl.addListener(_filterChannels);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = (prefs.getStringList('favorites') ?? []).toSet();
    });
  }

  Future<void> _toggleFavorite(String uuid) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favorites.contains(uuid)) {
        _favorites.remove(uuid);
      } else {
        _favorites.add(uuid);
      }
    });
    await prefs.setStringList('favorites', _favorites.toList());
    _filterChannels();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      await TVHService.instance.loadSettings();
      final prefs = await SharedPreferences.getInstance();
      _selectedProfileUuid = prefs.getString('profile_uuid') ?? '';
      _selectedProfileName = prefs.getString('profile_name') ?? 'pass';
      _selectedTagUuid = prefs.getString('tag_uuid');
      _selectedTagName = prefs.getString('tag_name') ?? '전체';

      final channels = await TVHService.instance.getChannels(tagUuid: _selectedTagUuid);
      final tags = await TVHService.instance.getChannelTags();
      final profiles = await TVHService.instance.getProfiles();
      final epgMap = await TVHService.instance.getAllNowPlaying();

      if (!mounted) return;
      setState(() {
        _channels = channels;
        _tags = tags;
        _profiles = profiles;
        _nowPlaying = Map<String, EpgEvent?>.from(epgMap);
        _loading = false;
        if (_selectedProfileUuid.isEmpty && profiles.isNotEmpty) {
          _selectedProfileUuid = profiles.first.uuid;
          _selectedProfileName = profiles.first.name;
        }
      });
      _filterChannels();
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _filterChannels() {
    final q = _searchCtrl.text.toLowerCase();
    List<Channel> list = _channels;
    if (q.isNotEmpty) {
      list = list.where((c) => c.name.toLowerCase().contains(q)).toList();
    }
    // 즐겨찾기 먼저
    list = [
      ...list.where((c) => _favorites.contains(c.uuid)),
      ...list.where((c) => !_favorites.contains(c.uuid)),
    ];
    setState(() => _filtered = list);
  }

  void _openProfilePicker() async {
    final picked = await showModalBottomSheet<StreamProfile>(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProfileSheet(profiles: _profiles, selectedUuid: _selectedProfileUuid),
    );
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_uuid', picked.uuid);
      await prefs.setString('profile_name', picked.name);
      setState(() { _selectedProfileUuid = picked.uuid; _selectedProfileName = picked.name; });
    }
  }

  void _openTagPicker() async {
    final picked = await showModalBottomSheet<_TagChoice>(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _TagSheet(tags: _tags, selectedUuid: _selectedTagUuid),
    );
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      if (picked.uuid == null) {
        await prefs.remove('tag_uuid');
      } else {
        await prefs.setString('tag_uuid', picked.uuid!);
      }
      await prefs.setString('tag_name', picked.name);
      setState(() { _selectedTagUuid = picked.uuid; _selectedTagName = picked.name; });
      _load();
    }
  }

  void _openNowScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NowScreen(
        profileUuid: _selectedProfileUuid,
        tagUuid: _selectedTagUuid,
        favorites: _favorites,
      ),
    ));
  }

  void _playChannel(Channel ch) {
    final url = TVHService.instance.getStreamUrl(ch.uuid, _selectedProfileUuid);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerScreen(channel: ch, streamUrl: url, nowPlaying: _nowPlaying[ch.uuid]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.tv, color: Color(0xFF42A5F5), size: 22),
          SizedBox(width: 8),
          Text('TVH Client', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          // NOW 버튼
          InkWell(
            onTap: _openNowScreen,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.6)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('NOW', style: TextStyle(
                    fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          // 태그 버튼
          if (_tags.isNotEmpty)
            _ChipButton(
              icon: Icons.label_outline,
              label: _selectedTagName.length > 8 ? '${_selectedTagName.substring(0, 8)}…' : _selectedTagName,
              color: const Color(0xFF66BB6A),
              bgColor: const Color(0xFF1B5E20),
              onTap: _openTagPicker,
            ),
          // 프로파일 버튼
          _ChipButton(
            icon: Icons.tune,
            label: _selectedProfileName.length > 8 ? '${_selectedProfileName.substring(0, 8)}…' : _selectedProfileName,
            color: const Color(0xFF42A5F5),
            bgColor: const Color(0xFF0D2137),
            onTap: _openProfilePicker,
          ),
          IconButton(icon: const Icon(Icons.settings), onPressed: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const SetupScreen(isEdit: true)));
            if (changed == true) _load();
          }),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '채널 검색...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                      onPressed: () { _searchCtrl.clear(); })
                  : null,
              filled: true,
              fillColor: const Color(0xFF1E1E2E),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        if (!_loading && _error == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(children: [
              Text('${_filtered.length}개 채널',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (_favorites.isNotEmpty) ...[
                const SizedBox(width: 6),
                const Icon(Icons.star, color: Colors.amber, size: 12),
                Text(' ${_favorites.length}개 즐겨찾기',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
              if (_selectedTagUuid != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF388E3C).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_selectedTagName,
                      style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 11)),
                ),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('tag_uuid');
                    await prefs.setString('tag_name', '전체');
                    setState(() { _selectedTagUuid = null; _selectedTagName = '전체'; });
                    _load();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 24),
                  ),
                  child: const Text('✕', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ),
              ],
            ]),
          ),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: Color(0xFF1565C0)),
        SizedBox(height: 16),
        Text('채널 목록 불러오는 중...', style: TextStyle(color: Colors.grey)),
      ]));
    }
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off, size: 56, color: Colors.red),
          const SizedBox(height: 16),
          const Text('연결 실패', style: TextStyle(color: Colors.white,
              fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
          ),
        ]),
      ));
    }
    if (_filtered.isEmpty) {
      return const Center(child: Text('채널이 없어요', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _ChannelTile(
        channel: _filtered[i],
        nowPlaying: _nowPlaying[_filtered[i].uuid],
        isFavorite: _favorites.contains(_filtered[i].uuid),
        serverUrl: TVHService.instance.baseUrl,
        onTap: () => _playChannel(_filtered[i]),
        onFavorite: () => _toggleFavorite(_filtered[i].uuid),
      ),
    );
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }
}

// ─── Chip Button ───────────────────────────────────────────────────────────────
class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  const _ChipButton({required this.icon, required this.label,
      required this.color, required this.bgColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ]),
      ),
    );
  }
}

// ─── Channel Tile ──────────────────────────────────────────────────────────────
class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final EpgEvent? nowPlaying;
  final bool isFavorite;
  final String serverUrl;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  const _ChannelTile({required this.channel, required this.nowPlaying,
      required this.isFavorite, required this.serverUrl,
      required this.onTap, required this.onFavorite});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 8, 6, 8),
          child: Row(children: [
            // 채널 아이콘
            _ChannelIcon(channel: channel, serverUrl: serverUrl),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 채널 번호 + 이름
              Row(children: [
                if (isFavorite) const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.star, color: Colors.amber, size: 12),
                ),
                if (channel.numberStr != null)
                  Text('${channel.numberStr}  ',
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                Expanded(child: Text(channel.name,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 3),
              if (nowPlaying != null) ...[
                Text(nowPlaying!.title,
                    style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Text(nowPlaying!.timeRange,
                      style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  const SizedBox(width: 6),
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: nowPlaying!.progress, minHeight: 2,
                      backgroundColor: const Color(0xFF333355),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                    ),
                  )),
                ]),
              ] else
                const Text('EPG 정보 없음',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
            ])),
            Column(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: Icon(Icons.star,
                    color: isFavorite ? Colors.amber : Colors.grey.withOpacity(0.4),
                    size: 20),
                onPressed: onFavorite,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.play_circle_outline, color: Color(0xFF1565C0), size: 28),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Channel Icon ──────────────────────────────────────────────────────────────
class _ChannelIcon extends StatelessWidget {
  final Channel channel;
  final String serverUrl;
  const _ChannelIcon({required this.channel, required this.serverUrl});

  @override
  Widget build(BuildContext context) {
    final iconUrl = channel.iconUrl;
    final hasIcon = iconUrl != null && iconUrl.isNotEmpty;
    final fullUrl = hasIcon ? '$serverUrl/$iconUrl' : null;

    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasIcon
          ? Image.network(
              fullUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _fallback(),
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return Center(
      child: Text(
        channel.numberStr ?? '?',
        style: const TextStyle(color: Color(0xFF42A5F5),
            fontSize: 12, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Profile Sheet ─────────────────────────────────────────────────────────────
class _ProfileSheet extends StatelessWidget {
  final List<StreamProfile> profiles;
  final String selectedUuid;
  const _ProfileSheet({required this.profiles, required this.selectedUuid});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 16),
      const Text('스트리밍 프로파일', style: TextStyle(color: Colors.white,
          fontWeight: FontWeight.bold, fontSize: 16)),
      const Divider(color: Color(0xFF333355)),
      ...profiles.map((p) => ListTile(
        leading: Icon(
          selectedUuid == p.uuid ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selectedUuid == p.uuid ? const Color(0xFF42A5F5) : Colors.grey,
        ),
        title: Text(p.name, style: const TextStyle(color: Colors.white)),
        onTap: () => Navigator.of(context).pop(p),
      )),
      const SizedBox(height: 8),
    ]));
  }
}

// ─── Tag Sheet ─────────────────────────────────────────────────────────────────
class _TagChoice { final String? uuid; final String name; _TagChoice({this.uuid, required this.name}); }

class _TagSheet extends StatelessWidget {
  final List<ChannelTag> tags;
  final String? selectedUuid;
  const _TagSheet({required this.tags, required this.selectedUuid});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 16),
      const Text('채널 태그', style: TextStyle(color: Colors.white,
          fontWeight: FontWeight.bold, fontSize: 16)),
      const Divider(color: Color(0xFF333355)),
      ListTile(
        leading: Icon(
          selectedUuid == null ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selectedUuid == null ? const Color(0xFF66BB6A) : Colors.grey,
        ),
        title: const Text('전체 채널', style: TextStyle(color: Colors.white)),
        onTap: () => Navigator.of(context).pop(_TagChoice(uuid: null, name: '전체')),
      ),
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
        child: ListView(shrinkWrap: true, children: tags.map((t) => ListTile(
          leading: Icon(
            selectedUuid == t.uuid ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selectedUuid == t.uuid ? const Color(0xFF66BB6A) : Colors.grey,
          ),
          title: Text(t.name, style: const TextStyle(color: Colors.white)),
          onTap: () => Navigator.of(context).pop(_TagChoice(uuid: t.uuid, name: t.name)),
        )).toList()),
      ),
      const SizedBox(height: 8),
    ]));
  }
}
