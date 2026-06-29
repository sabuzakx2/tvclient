import 'package:flutter/material.dart';

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
  }

  void _add(String text) {
    setState(() {
      _value += text;
    });
  }

  void _backspace() {
    if (_value.isEmpty) return;

    setState(() {
      _value = _value.substring(0, _value.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Dialog(
        backgroundColor: const Color(0xFF171A22),
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 1000,
          height: 720,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Text(
                  '서버 주소 입력',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 70),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0F15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF42A5F5),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _value.isEmpty ? '주소를 입력하세요' : _value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _value.isEmpty ? Colors.grey : Colors.white,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: FocusTraversalGroup(
                    policy: ReadingOrderTraversalPolicy(),
                    child: GridView.count(
                      crossAxisCount: 8,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.65,
                      children: [
                        for (var i = 0; i < _keys.length; i++)
                          ElevatedButton(
                            autofocus: i == 0,
                            onPressed: () => _add(_keys[i]),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A3040),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              _keys[i],
                              style: TextStyle(
                                fontSize: _keys[i].length > 2 ? 15 : 21,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FocusTraversalGroup(
                  policy: ReadingOrderTraversalPolicy(),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _backspace,
                          icon: const Icon(Icons.backspace_outlined),
                          label: const Text(
                            '삭제',
                            style: TextStyle(fontSize: 20),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 60),
                            backgroundColor: const Color(0xFF5B2C2C),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text(
                            '취소',
                            style: TextStyle(fontSize: 20),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 60),
                            backgroundColor: const Color(0xFF3A3A44),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(_value),
                          icon: const Icon(Icons.check),
                          label: const Text(
                            '완료',
                            style: TextStyle(fontSize: 20),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 60),
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '방향키로 이동하고 확인 버튼으로 입력합니다.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
