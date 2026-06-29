import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<String?> showTvUrlKeyboard(
  BuildContext context, {
  required String initialValue,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _TvUrlKeyboardDialog(initialValue: initialValue),
  );
}

class _TvUrlKeyboardDialog extends StatefulWidget {
  final String initialValue;

  const _TvUrlKeyboardDialog({
    required this.initialValue,
  });

  @override
  State<_TvUrlKeyboardDialog> createState() => _TvUrlKeyboardDialogState();
}

class _TvUrlKeyboardDialogState extends State<_TvUrlKeyboardDialog> {
  late String _value;
  final FocusNode _keyboardFocus = FocusNode();

  final List<String> _keys = const [
    'https://',
    'http://',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '.',
    ':',
    '/',
    '-',
    '_',
  ];

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardFocus.dispose();
    super.dispose();
  }

  void _add(String text) {
    setState(() => _value += text);
  }

  void _backspace() {
    if (_value.isEmpty) return;
    setState(() {
      _value = _value.substring(0, _value.length - 1);
    });
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF171A22),
      insetPadding: const EdgeInsets.all(24),
      child: Focus(
        focusNode: _keyboardFocus,
        onKeyEvent: _handleKey,
        child: SizedBox(
          width: 900,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '서버 주소 입력',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0F15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF42A5F5),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _value.isEmpty ? '주소를 입력하세요' : _value,
                    style: TextStyle(
                      color: _value.isEmpty ? Colors.grey : Colors.white,
                      fontSize: 22,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 24),
                FocusTraversalGroup(
                  policy: ReadingOrderTraversalPolicy(),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ..._keys.map(
                        (key) => SizedBox(
                          width: key.length > 2 ? 115 : 56,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => _add(key),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A3040),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              key,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 115,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _backspace,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B2C2C),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            '⌫ 삭제',
                            style: TextStyle(fontSize: 17),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(_value),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            '완료',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '방향키로 이동하고 확인 버튼으로 입력합니다. 뒤로가기 버튼은 취소입니다.',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
