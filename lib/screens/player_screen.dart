import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/channel.dart';
import '../models/epg_event.dart';
import '../services/tvh_service.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final String streamUrl;
  final EpgEvent? nowPlaying;

  const PlayerScreen({
    super.key,
    required this.channel,
    required this.streamUrl,
    this.nowPlaying,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  late final Player _player;
  late final VideoController _controller;
  List<EpgEvent> _epgList = [];
  bool _showEpg = false;
  Timer? _sleepTimer;
  int? _sleepMinutes;
  int _sleepRemaining = 0;
  Timer? _sleepCountdown;
  bool _isLocked = false;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 세로모드로 고정 시작
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.streamUrl));
    _loadEpg();
  }

  @override
  void didChangeMetrics() {
    // 기기 회전 감지
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.landscape && !_isFullscreen) {
      setState(() => _isFullscreen = true);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else if (orientation == Orientation.portrait && _isFullscreen) {
      setState(() => _isFullscreen = false);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _loadEpg() async {
    try {
      final events = await TVHService.instance.getEpg(widget.channel.uuid, hours: 12);
      if (mounted) setState(() => _epgList = events);
    } catch (_) {}
  }

  void _toggleFullscreen() {
    if (_isFullscreen) {
      // 세로모드로 복귀
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      setState(() => _isFullscreen = false);
    } else {
      // 가로모드 전환
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      setState(() => _isFullscreen = true);
    }
  }

  void _showSleepTimerDialog() {
    final options = [15, 30, 60, 90, 120];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 16),
        const Text('수면 타이머', style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        const Text('선택한 시간 후 자동 종료',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const Divider(color: Color(0xFF333355)),
        if (_sleepTimer != null)
          ListTile(
            leading: const Icon(Icons.timer_off, color: Colors.red),
            title: Text('타이머 취소 (${_sleepRemaining}분 남음)',
                style: const TextStyle(color: Colors.red)),
            onTap: () { _cancelSleepTimer(); Navigator.pop(context); },
          ),
        ...options.map((min) => ListTile(
          leading: Icon(Icons.timer,
              color: _sleepMinutes == min ? const Color(0xFF42A5F5) : Colors.grey),
          title: Text('$min분 후 종료',
              style: TextStyle(
                  color: _sleepMinutes == min ? const Color(0xFF42A5F5) : Colors.white)),
          onTap: () { _setSleepTimer(min); Navigator.pop(context); },
        )),
        const SizedBox(height: 8),
      ])),
    );
  }

  void _setSleepTimer(int minutes) {
    _cancelSleepTimer();
    setState(() { _sleepMinutes = minutes; _sleepRemaining = minutes; });
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      if (mounted) Navigator.of(context).pop();
    });
    _sleepCountdown = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _sleepRemaining--);
    });
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepCountdown?.cancel();
    if (mounted) setState(() { _sleepTimer = null; _sleepMinutes = null; _sleepRemaining = 0; });
  }

  void _toggleLock() {
    setState(() => _isLocked = !_isLocked);
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('화면이 잠겼어요. 길게 누르면 해제돼요.'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF1A1A2E),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sleepTimer?.cancel();
    _sleepCountdown?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 화면 잠금 모드
    if (_isLocked) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onLongPress: _toggleLock,
          child: SizedBox.expand(
            child: Stack(children: [
              Video(controller: _controller, controls: NoVideoControls),
              Positioned(
                bottom: 40, left: 0, right: 0,
                child: Column(children: [
                  const Icon(Icons.lock, color: Colors.white54, size: 32),
                  const SizedBox(height: 8),
                  const Text('화면 잠금 중',
                      style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const Text('길게 누르면 잠금 해제',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  if (_sleepTimer != null) ...[
                    const SizedBox(height: 8),
                    Text('수면 타이머: $_sleepRemaining분 남음',
                        style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 12)),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      );
    }

    // 전체화면 모드
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Video(
            controller: _controller,
            controls: AdaptiveVideoControls,
          ),
          // 전체화면에서 상단 버튼들
          Positioned(
            top: 8, left: 8, right: 8,
            child: Row(children: [
              _iconBtn(Icons.fullscreen_exit, _toggleFullscreen),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.channel.name,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 15, fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              _iconBtn(Icons.lock_outline, _toggleLock),
              Stack(children: [
                _iconBtn(Icons.bedtime,
                    _showSleepTimerDialog,
                    color: _sleepTimer != null ? const Color(0xFF42A5F5) : Colors.white),
                if (_sleepTimer != null)
                  Positioned(right: 4, top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle),
                      child: Text('$_sleepRemaining',
                          style: const TextStyle(color: Colors.white, fontSize: 8)),
                    )),
              ]),
            ]),
          ),
        ]),
      );
    }

    // 세로모드 (기본)
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Container(
            color: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(widget.channel.name,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Stack(children: [
                IconButton(
                  icon: Icon(Icons.bedtime,
                      color: _sleepTimer != null ? const Color(0xFF42A5F5) : Colors.white),
                  onPressed: _showSleepTimerDialog,
                ),
                if (_sleepTimer != null)
                  Positioned(right: 6, top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle),
                      child: Text('$_sleepRemaining',
                          style: const TextStyle(color: Colors.white, fontSize: 9)),
                    )),
              ]),
              IconButton(
                icon: const Icon(Icons.lock_outline, color: Colors.white),
                onPressed: _toggleLock,
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: _toggleFullscreen,
              ),
              IconButton(
                icon: Icon(_showEpg ? Icons.list_alt : Icons.list_alt_outlined,
                    color: _showEpg ? const Color(0xFF42A5F5) : Colors.white),
                onPressed: () => setState(() => _showEpg = !_showEpg),
              ),
            ]),
          ),
          // Video - 세로모드에서는 16:9 비율로
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Video(
              controller: _controller,
              controls: AdaptiveVideoControls,
            ),
          ),
          if (widget.nowPlaying != null) _buildNowPlaying(),
          if (_showEpg) Expanded(child: _buildEpgPanel()),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {Color color = Colors.white}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildNowPlaying() {
    final ep = widget.nowPlaying!;
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 10),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ep.title, style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(ep.timeRange, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ])),
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: ep.progress,
            backgroundColor: const Color(0xFF333355),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
            minHeight: 3,
          ),
        ),
      ]),
    );
  }

  Widget _buildEpgPanel() {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Icon(Icons.list_alt, color: Color(0xFF42A5F5), size: 18),
            const SizedBox(width: 8),
            const Text('편성표', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
              onPressed: () => setState(() => _showEpg = false),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFF333355)),
        Expanded(
          child: _epgList.isEmpty
              ? const Center(child: Text('편성 정보 없음', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _epgList.length,
                  itemBuilder: (_, i) {
                    final e = _epgList[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: e.isNow ? const Color(0xFF1565C0).withOpacity(0.2) : Colors.transparent,
                        border: e.isNow ? const Border(left: BorderSide(color: Color(0xFF1565C0), width: 3)) : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${e.start.hour.toString().padLeft(2, '0')}:${e.start.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: e.isNow ? const Color(0xFF42A5F5) : Colors.grey,
                              fontSize: 12,
                              fontWeight: e.isNow ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.title,
                              style: TextStyle(
                                color: e.isNow ? Colors.white : Colors.white70,
                                fontSize: 13,
                                fontWeight: e.isNow ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (e.subtitle != null)
                            Text(e.subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 11),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        Text('${e.durationMinutes}분',
                            style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
