import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tvh_service.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  final bool isEdit;
  const SetupScreen({super.key, this.isEdit = false});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  final _urlFocus = FocusNode(debugLabel: 'server-url');
  final _userFocus = FocusNode(debugLabel: 'username');
  final _passFocus = FocusNode(debugLabel: 'password');
  final _saveFocus = FocusNode(debugLabel: 'save-button');

  bool _loading = false;
  String? _error;
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    _loadExisting();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _urlFocus.requestFocus();
    });
  }

  Future<void> _loadExisting() async {
    final prefs = await SharedPreferences.getInstance();
    _urlCtrl.text = prefs.getString('server_url') ?? '';
    _userCtrl.text = prefs.getString('username') ?? '';
    _passCtrl.text = prefs.getString('password') ?? '';
  }

  KeyEventResult _moveFocus(
    KeyEvent event, {
    FocusNode? previous,
    FocusNode? next,
  }) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown && next != null) {
      next.requestFocus();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp && previous != null) {
      previous.requestFocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _save() async {
    final url = _urlCtrl.text.trim();

    if (url.isEmpty) {
      setState(() => _error = '서버 URL을 입력해주세요');
      _urlFocus.requestFocus();
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() => _error = 'URL은 http:// 또는 https://로 시작해야 해요');
      _urlFocus.requestFocus();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
    await prefs.setString('username', _userCtrl.text.trim());
    await prefs.setString('password', _passCtrl.text);

    await TVHService.instance.loadSettings();
    final ok = await TVHService.instance.testConnection();

    if (!mounted) return;

    setState(() => _loading = false);

    if (ok) {
      if (widget.isEdit) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        _error = '서버에 연결할 수 없어요.\nURL과 포트를 확인해주세요.';
      });
      _urlFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.tv, size: 72, color: Color(0xFF1565C0)),
                    const SizedBox(height: 16),
                    const Text(
                      'TVH Client',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isEdit ? '서버 설정 변경' : 'TVHeadend 서버를 설정해주세요',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 40),

                    Focus(
                      onKeyEvent: (_, event) => _moveFocus(
                        event,
                        next: _userFocus,
                      ),
                      child: _buildField(
                        focusNode: _urlFocus,
                        controller: _urlCtrl,
                        label: '서버 URL',
                        hint: 'https://192.168.1.100:9981',
                        icon: Icons.dns,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _userFocus.requestFocus(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Focus(
                      onKeyEvent: (_, event) => _moveFocus(
                        event,
                        previous: _urlFocus,
                        next: _passFocus,
                      ),
                      child: _buildField(
                        focusNode: _userFocus,
                        controller: _userCtrl,
                        label: '아이디 (없으면 비워두세요)',
                        hint: '',
                        icon: Icons.person,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _passFocus.requestFocus(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Focus(
                      onKeyEvent: (_, event) => _moveFocus(
                        event,
                        previous: _userFocus,
                        next: _saveFocus,
                      ),
                      child: TextField(
                        focusNode: _passFocus,
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveFocus.requestFocus(),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: '비밀번호 (없으면 비워두세요)',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() => _obscurePass = !_obscurePass);
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1E1E2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF333355),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF42A5F5),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    Focus(
                      onKeyEvent: (_, event) => _moveFocus(
                        event,
                        previous: _passFocus,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          focusNode: _saveFocus,
                          onPressed: _loading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  '연결 확인 및 저장',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required FocusNode focusNode,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      focusNode: focusNode,
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1E1E2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF333355)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF42A5F5),
            width: 2,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();

    _urlFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _saveFocus.dispose();

    super.dispose();
  }
}
