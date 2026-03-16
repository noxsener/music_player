import 'package:flutter/material.dart';

import 'dart:async'; import 'dart:math';
import 'package:flutter/material.dart';

class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool playOnBuild;
  const GlitchText({super.key, required this.text,
    this.style, this.playOnBuild = true});
  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText> {
  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#@!%';
  late String _display;
  Timer? _timer;
  int _frame = 0;
  static const _glitchFrames = 6;

  @override
  void initState() {
    super.initState();
    _display = widget.text;
    if (widget.playOnBuild) _startGlitch();
  }

  void _startGlitch() {
    _frame = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_frame >= _glitchFrames) {
        setState(() => _display = widget.text);
        t.cancel(); return;
      }
      final r = Random();
      setState(() {
        _display = widget.text.split('').map((c) {
          return c == ' ' ? ' '
              : r.nextBool() ? c
              : _chars[r.nextInt(_chars.length)];
        }).join();
      });
      _frame++;
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) =>
      Text(_display, style: widget.style);
}
