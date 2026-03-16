// lib/widgets/cyber_ai_assistant.dart
//
// ┌─────────────────────────────────────────────────────┐
// │  CyberAiAssistant — Japanese anime office waifu     │
// │  Moods: happy · angry · sad · shocked · tired       │
// └─────────────────────────────────────────────────────┘
//
// Usage:
//   showGeneralDialog(
//     context: context,
//     barrierDismissible: false,
//     barrierColor: Colors.transparent,
//     pageBuilder: (_, __, ___) => CyberAiAssistant(
//       message: 'Merhaba! Bugün nasıl yardımcı olabilirim?',
//       mood: AssistantMood.happy,
//       displayDuration: const Duration(seconds: 6),
//     ),
//   );

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MOOD ENUM
// ═══════════════════════════════════════════════════════════════════════════

enum AssistantMood { happy, angry, sad, shocked, tired }

// ═══════════════════════════════════════════════════════════════════════════
// PUBLIC WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class CyberAiAssistant extends StatefulWidget {
  final String message;
  final AssistantMood mood;
  final Duration displayDuration;

  const CyberAiAssistant({
    super.key,
    required this.message,
    this.mood = AssistantMood.happy,
    this.displayDuration = const Duration(seconds: 6),
  });

  @override
  State<CyberAiAssistant> createState() => _CyberAiAssistantState();
}

// ═══════════════════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════════════════

class _CyberAiAssistantState extends State<CyberAiAssistant>
    with TickerProviderStateMixin {

  late final AnimationController _entryCtrl;
  late final AnimationController _exitCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _blinkCtrl;
  late final AnimationController _mouthCtrl;
  late final AnimationController _hairCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _scanCtrl;
  late final AnimationController _countdownCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _fxCtrl;

  bool _showBubble = false;
  String _displayedText = '';
  Timer? _typewriterTimer;

  double get _shakeX {
    if (widget.mood == AssistantMood.angry) {
      return sin(_shakeCtrl.value * pi * 14) * 3.5 * (1 - _shakeCtrl.value);
    }
    if (widget.mood == AssistantMood.shocked) {
      return sin(_shakeCtrl.value * pi * 6) * 2.0 * (1 - _shakeCtrl.value);
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();

    _entryCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
    _exitCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _floatCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat(reverse: true);
    _blinkCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _mouthCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 85));
    _hairCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _glowCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..repeat(reverse: true);
    _scanCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat();
    _countdownCtrl = AnimationController(vsync: this, duration: widget.displayDuration);
    _shakeCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fxCtrl       = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

    final blinkBase = widget.mood == AssistantMood.tired ? 700 : 1800;
    final blinkRand = widget.mood == AssistantMood.tired ? 800 : 2500;
    _startBlinkCycle(blinkBase, blinkRand);
    _runEntrySequence();
  }

  void _runEntrySequence() async {
    await _entryCtrl.forward();
    if (!mounted) return;
    setState(() => _showBubble = true);
    _startTypewriter();
    if (widget.mood != AssistantMood.tired) _mouthCtrl.repeat(reverse: true);
    _countdownCtrl.forward();
    if (widget.mood == AssistantMood.angry || widget.mood == AssistantMood.shocked) {
      _shakeCtrl.forward();
    }

    await Future.delayed(widget.displayDuration);
    if (!mounted) return;

    _mouthCtrl.stop();
    _exitCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 550));
    if (mounted) Navigator.of(context).maybePop();
  }

  void _startTypewriter() {
    _displayedText = '';
    int idx = 0;
    final ms = widget.mood == AssistantMood.tired ? 55 : 36;
    _typewriterTimer = Timer.periodic(Duration(milliseconds: ms), (t) {
      if (!mounted) { t.cancel(); return; }
      if (idx < widget.message.length) {
        setState(() => _displayedText = widget.message.substring(0, ++idx));
      } else {
        t.cancel();
        _mouthCtrl.stop();
        _mouthCtrl.reset();
      }
    });
  }

  void _startBlinkCycle(int baseMs, int randMs) async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: baseMs + Random().nextInt(randMs)));
      if (!mounted) break;
      if (widget.mood == AssistantMood.shocked && Random().nextBool()) continue;
      await _blinkCtrl.forward();
      await _blinkCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    for (final c in [
      _entryCtrl, _exitCtrl, _floatCtrl, _blinkCtrl, _mouthCtrl,
      _hairCtrl, _glowCtrl, _scanCtrl, _countdownCtrl, _shakeCtrl, _fxCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Color get _accent {
    switch (widget.mood) {
      case AssistantMood.angry:   return const Color(0xFFFF4444);
      case AssistantMood.sad:     return const Color(0xFF6699CC);
      case AssistantMood.shocked: return const Color(0xFFFFCC00);
      case AssistantMood.tired:   return const Color(0xFF9988BB);
      case AssistantMood.happy:   return AppRawColors.cyan;
    }
  }

  String get _moodLabel {
    switch (widget.mood) {
      case AssistantMood.angry:   return 'KIZGIN';
      case AssistantMood.sad:     return 'ÜZGÜN';
      case AssistantMood.shocked: return 'ŞAŞKIN';
      case AssistantMood.tired:   return 'YORGUN';
      case AssistantMood.happy:   return 'MUTLU';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ambient corner glow
          Positioned(
            bottom: 0, right: 0,
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Container(
                width: 360, height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _accent.withOpacity(0.04 + _glowCtrl.value * 0.04),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),

          // character + bubble
          Positioned(
            bottom: 70, right: 12,
            child: AnimatedBuilder(
              animation: Listenable.merge([_entryCtrl, _exitCtrl]),
              builder: (_, child) {
                final entry = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack).value.clamp(0.0, 1.0);
                final exit  = _exitCtrl.value;
                return Opacity(
                  opacity: (entry * (1 - exit)).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset((1 - entry) * 90 + exit * 70, (1 - entry) * 20),
                    child: child,
                  ),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_showBubble) _buildBubble(),
                  const SizedBox(width: 8),
                  _buildCharacter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Character ──────────────────────────────────────────────────────────────

  Widget _buildCharacter() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatCtrl, _blinkCtrl, _mouthCtrl, _hairCtrl, _glowCtrl, _shakeCtrl, _fxCtrl,
      ]),
      builder: (_, __) {
        final floatY = widget.mood == AssistantMood.tired
            ? -2.0 + _floatCtrl.value * -4.0
            : -8.0 + _floatCtrl.value * -10.0;
        final shockBounce = widget.mood == AssistantMood.shocked
            ? -(1 - _shakeCtrl.value) * 8 : 0.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            // glow halo
            Container(
              width: 155, height: 205,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.14 + _glowCtrl.value * 0.12),
                    blurRadius: 44 + _glowCtrl.value * 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // sprite
            Transform.translate(
              offset: Offset(_shakeX, floatY + shockBounce),
              child: CustomPaint(
                size: const Size(140, 190),
                painter: _CharacterPainter(
                  mood: widget.mood,
                  blinkValue: _blinkCtrl.value,
                  mouthValue: _mouthCtrl.value,
                  hairWave: _hairCtrl.value,
                  glowPulse: _glowCtrl.value,
                  fxProgress: _fxCtrl.value,
                  accent: _accent,
                ),
              ),
            ),
            // HUD brackets
            Transform.translate(
              offset: Offset(_shakeX, floatY + shockBounce),
              child: SizedBox(
                width: 140, height: 190,
                child: AnimatedBuilder(
                  animation: _scanCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _HudPainter(scan: _scanCtrl.value, glow: _glowCtrl.value, accent: _accent),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Bubble ─────────────────────────────────────────────────────────────────

  Widget _buildBubble() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, v, __) {
        final sv = v.clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.88 + sv * 0.12,
          alignment: Alignment.bottomRight,
          child: Opacity(
            opacity: sv,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 238,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0C1828), Color(0xFF080F1C)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(5),
                    ),
                    border: Border.all(color: _accent.withOpacity(0.55), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: _accent.withOpacity(0.16), blurRadius: 18, offset: const Offset(-1, -1)),
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(5),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: _DotGridPainter(_accent))),
                        AnimatedBuilder(
                          animation: _scanCtrl,
                          builder: (_, __) => Positioned(
                            top: _scanCtrl.value * 230,
                            left: 0, right: 0,
                            child: Container(height: 1.5, color: _accent.withOpacity(0.05)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // header
                              Row(
                                children: [
                                  AnimatedBuilder(
                                    animation: _glowCtrl,
                                    builder: (_, __) => Container(
                                      width: 6, height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _accent.withOpacity(0.75 + _glowCtrl.value * 0.25),
                                        boxShadow: [BoxShadow(color: _accent.withOpacity(0.7), blurRadius: 5)],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('AURA', style: TextStyle(
                                    color: _accent,
                                    fontSize: 9.5, letterSpacing: 2.5, fontWeight: FontWeight.w800,
                                  )),
                                  const SizedBox(width: 6),
                                  Container(width: 1, height: 9, color: _accent.withOpacity(0.3)),
                                  const SizedBox(width: 6),
                                  Text(_moodLabel, style: TextStyle(
                                    color: _accent.withOpacity(0.7),
                                    fontSize: 8, letterSpacing: 1.8,
                                  )),
                                ],
                              ),
                              const SizedBox(height: 9),
                              // message
                              Text(
                                _displayedText,
                                style: const TextStyle(
                                  color: Color(0xFFDDEEFF),
                                  fontSize: 13.5, height: 1.55, letterSpacing: 0.15,
                                ),
                              ),
                              // cursor
                              if (_displayedText.length < widget.message.length)
                                AnimatedBuilder(
                                  animation: _glowCtrl,
                                  builder: (_, __) => Container(
                                    width: 7, height: 13,
                                    margin: const EdgeInsets.only(top: 3),
                                    color: _accent.withOpacity(_glowCtrl.value > 0.5 ? 0.9 : 0.15),
                                  ),
                                ),
                              const SizedBox(height: 11),
                              // countdown bar
                              AnimatedBuilder(
                                animation: _countdownCtrl,
                                builder: (_, __) {
                                  final rem = (1.0 - _countdownCtrl.value).clamp(0.0, 1.0);
                                  final secs = ((widget.displayDuration.inMilliseconds / 1000.0) * rem).ceil();
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('AUTO CLOSE', style: TextStyle(
                                            color: _accent.withOpacity(0.45),
                                            fontSize: 7.5, letterSpacing: 1.4,
                                          )),
                                          Text('${secs}s', style: TextStyle(
                                            color: _accent.withOpacity(0.65),
                                            fontSize: 8, letterSpacing: 0.8,
                                          )),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Stack(
                                        children: [
                                          Container(
                                            height: 2,
                                            decoration: BoxDecoration(
                                              color: _accent.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(1),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: rem,
                                            child: Container(
                                              height: 2,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(colors: [_accent, _accent.withOpacity(0.4)]),
                                                borderRadius: BorderRadius.circular(1),
                                                boxShadow: [BoxShadow(color: _accent.withOpacity(0.55), blurRadius: 4)],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // tail
                Positioned(
                  bottom: -8, right: 0,
                  child: CustomPaint(size: const Size(14, 9), painter: _TailPainter(_accent)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CHARACTER PAINTER
// ═══════════════════════════════════════════════════════════════════════════

class _CharacterPainter extends CustomPainter {
  final AssistantMood mood;
  final double blinkValue;
  final double mouthValue;
  final double hairWave;
  final double glowPulse;
  final double fxProgress;
  final Color accent;

  const _CharacterPainter({
    required this.mood,
    required this.blinkValue,
    required this.mouthValue,
    required this.hairWave,
    required this.glowPulse,
    required this.fxProgress,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final cx = size.width / 2;

    _drawBackHair(canvas, p, size, cx);
    _drawNeckBody(canvas, p, size, cx);
    _drawFace(canvas, p, size, cx);
    _drawEyebrows(canvas, p, size, cx);
    _drawEyes(canvas, p, size, cx);
    _drawGlasses(canvas, p, size, cx);
    _drawNose(canvas, p, size, cx);
    _drawMouth(canvas, p, size, cx);
    _drawFrontHair(canvas, p, size, cx);
    _drawMoodFx(canvas, p, size, cx);
  }

  // ── Back hair ─────────────────────────────────────────────────────────────
  void _drawBackHair(Canvas canvas, Paint p, Size size, double cx) {
    final w = sin(hairWave * pi) * 5;

    // dark shadow
    p.color = const Color(0xFF1A0A00);
    canvas.drawPath(Path()
      ..moveTo(cx - 44, size.height * 0.14)
      ..cubicTo(cx - 72 + w * 0.5, size.height * 0.42, cx - 58 + w, size.height * 0.78, cx - 22 + w * 0.4, size.height * 0.98)
      ..lineTo(cx + 22 - w * 0.4, size.height * 0.98)
      ..cubicTo(cx + 58 - w, size.height * 0.78, cx + 72 - w * 0.5, size.height * 0.42, cx + 44, size.height * 0.14)
      ..close(), p);

    // golden main
    p.color = const Color(0xFFC8820A);
    canvas.drawPath(Path()
      ..moveTo(cx - 40, size.height * 0.14)
      ..cubicTo(cx - 66 + w * 0.4, size.height * 0.40, cx - 52 + w * 0.8, size.height * 0.76, cx - 18 + w * 0.3, size.height * 0.96)
      ..lineTo(cx + 18 - w * 0.3, size.height * 0.96)
      ..cubicTo(cx + 52 - w * 0.8, size.height * 0.76, cx + 66 - w * 0.4, size.height * 0.40, cx + 40, size.height * 0.14)
      ..close(), p);

    // highlight strand
    p..color = const Color(0xFFFFD060).withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()
      ..moveTo(cx - 28, size.height * 0.16)
      ..cubicTo(cx - 50 + w * 0.5, size.height * 0.42, cx - 38 + w * 0.8, size.height * 0.72, cx - 14, size.height * 0.90), p);
    p.style = PaintingStyle.fill;
  }

  // ── Neck + hoodie ─────────────────────────────────────────────────────────
  void _drawNeckBody(Canvas canvas, Paint p, Size size, double cx) {
    const hoodieMain = Color(0xFF0E1D30);
    const hoodieRib  = Color(0xFF0A1622);
    const hoodieEdge = Color(0xFF162440);
    const hoodiePock = Color(0xFF0C1928);

    // neck
    p.color = const Color(0xFFF5C99A);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, size.height * 0.69), width: 19, height: 24),
        const Radius.circular(4)), p);

    // hoodie body — wide shoulder curve, tapers to waist
    p.color = hoodieMain;
    canvas.drawPath(Path()
      ..moveTo(cx - 58, size.height)
      ..lineTo(cx - 48, size.height * 0.72)
      ..cubicTo(cx - 44, size.height * 0.70,
          cx - 32, size.height * 0.675,
          cx - 7,  size.height * 0.67)
      ..lineTo(cx + 7,  size.height * 0.67)
      ..cubicTo(cx + 32, size.height * 0.675,
          cx + 44, size.height * 0.70,
          cx + 48, size.height * 0.72)
      ..lineTo(cx + 58, size.height)
      ..close(), p);

    // hood drape visible behind head — panel hanging from collar
    p.color = const Color(0xFF0C1A2C);
    canvas.drawPath(Path()
      ..moveTo(cx - 31, size.height * 0.68)
      ..cubicTo(cx - 40, size.height * 0.725,
          cx - 36, size.height * 0.805,
          cx - 26, size.height * 0.855)
      ..lineTo(cx + 26, size.height * 0.855)
      ..cubicTo(cx + 36, size.height * 0.805,
          cx + 40, size.height * 0.725,
          cx + 31, size.height * 0.68)
      ..close(), p);

    // hood rim / collar curve
    p..color = hoodieEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()
      ..moveTo(cx - 30, size.height * 0.675)
      ..cubicTo(cx - 18, size.height * 0.660,
          cx - 8,  size.height * 0.655,
          cx,      size.height * 0.655)
      ..cubicTo(cx + 8,  size.height * 0.655,
          cx + 18, size.height * 0.660,
          cx + 30, size.height * 0.675), p);
    p.style = PaintingStyle.fill;

    // drawstrings (slight sway with hair wave)
    final strSway = sin(hairWave * pi) * 1.5;
    p..color = const Color(0xFF1E3050)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()
      ..moveTo(cx - 6, size.height * 0.660)
      ..quadraticBezierTo(cx - 10 + strSway, size.height * 0.725,
          cx - 8,            size.height * 0.785), p);
    canvas.drawPath(Path()
      ..moveTo(cx + 6, size.height * 0.660)
      ..quadraticBezierTo(cx + 10 - strSway, size.height * 0.725,
          cx + 8,            size.height * 0.785), p);
    p.style = PaintingStyle.fill;
    // string tips
    p.color = const Color(0xFF88AACC).withOpacity(0.72);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 8, size.height * 0.795), width: 4, height: 7),
        const Radius.circular(2)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 8, size.height * 0.795), width: 4, height: 7),
        const Radius.circular(2)), p);

    // front zip line
    p..color = const Color(0xFF1A3050).withOpacity(0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(cx, size.height * 0.68), Offset(cx, size.height * 0.90), p);
    p.style = PaintingStyle.fill;

    // zip pull tab (accent glow)
    p.color = accent.withOpacity(0.72 + glowPulse * 0.20);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, size.height * 0.725), width: 6, height: 3),
        const Radius.circular(1.5)), p);

    // kangaroo pocket
    p.color = hoodiePock;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 28, size.height * 0.81, 56, size.height * 0.11),
        const Radius.circular(5)), p);
    p..color = hoodieEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 28, size.height * 0.81, 56, size.height * 0.11),
        const Radius.circular(5)), p);
    canvas.drawLine(Offset(cx, size.height * 0.81), Offset(cx, size.height * 0.92), p);
    p.style = PaintingStyle.fill;

    // ribbed hem
    p.color = hoodieRib;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 44, size.height * 0.92, 88, size.height * 0.06),
        const Radius.circular(3)), p);
    p..color = hoodieEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;
    for (int i = 1; i <= 4; i++) {
      final ry = size.height * 0.92 + i * size.height * 0.01;
      canvas.drawLine(Offset(cx - 44, ry), Offset(cx + 44, ry), p);
    }
    p.style = PaintingStyle.fill;

    // accent glow edge lines
    p..color = accent.withOpacity(0.20 + glowPulse * 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(cx - 28, size.height * 0.72), Offset(cx - 12, size.height * 0.83), p);
    canvas.drawLine(Offset(cx + 28, size.height * 0.72), Offset(cx + 12, size.height * 0.83), p);
    p.style = PaintingStyle.fill;

    // ID badge clipped on pocket
    final badge = Offset(cx + 22, size.height * 0.78);
    p.color = const Color(0xFFE8EEF8).withOpacity(0.88);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: badge, width: 18, height: 11), const Radius.circular(2)), p);
    p..color = accent.withOpacity(0.55 + glowPulse * 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: badge, width: 18, height: 11), const Radius.circular(2)), p);
    // badge text lines
    p..color = const Color(0xFF4488AA).withOpacity(0.55)..strokeWidth = 0.7;
    canvas.drawLine(badge.translate(-7, -2), badge.translate(2, -2), p);
    canvas.drawLine(badge.translate(-7,  1), badge.translate(4,  1), p);
    // lanyard clip
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFF88AACC).withOpacity(0.52);
    canvas.drawRect(Rect.fromCenter(center: badge.translate(0, -7), width: 3, height: 4), p);
  }

  // ── Face ──────────────────────────────────────────────────────────────────
  void _drawFace(Canvas canvas, Paint p, Size size, double cx) {
    // jaw shadow
    p.color = const Color(0xFFE0A070);
    canvas.drawPath(Path()
      ..moveTo(cx - 33, size.height * 0.18)
      ..quadraticBezierTo(cx - 36, size.height * 0.56, cx, size.height * 0.66)
      ..quadraticBezierTo(cx + 36, size.height * 0.56, cx + 33, size.height * 0.18)
      ..close(), p);

    // face
    p.color = const Color(0xFFFAD0A0);
    canvas.drawPath(Path()
      ..moveTo(cx - 31, size.height * 0.18)
      ..quadraticBezierTo(cx - 34, size.height * 0.53, cx, size.height * 0.64)
      ..quadraticBezierTo(cx + 34, size.height * 0.53, cx + 31, size.height * 0.18)
      ..close(), p);

    // ears
    for (final side in [-1.0, 1.0]) {
      p.color = const Color(0xFFF5C58A);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + side * 33, size.height * 0.37), width: 9, height: 13), p);
      p.color = const Color(0xFFE8A070).withOpacity(0.6);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + side * 33, size.height * 0.37), width: 5, height: 8), p);
    }

    // blush
    final blushAlpha = mood == AssistantMood.angry ? 0.55
        : mood == AssistantMood.sad   ? 0.15
        : mood == AssistantMood.tired ? 0.18 : 0.28;
    p.color = const Color(0xFFFF9999).withOpacity(blushAlpha);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 19, size.height * 0.49), width: 20, height: 9), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 19, size.height * 0.49), width: 20, height: 9), p);
  }

  // ── Eyebrows ──────────────────────────────────────────────────────────────
  void _drawEyebrows(Canvas canvas, Paint p, Size size, double cx) {
    p..color = const Color(0xFF7A4010)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final browY = size.height;
    switch (mood) {
      case AssistantMood.angry:
        canvas.drawLine(Offset(cx - 24, browY * 0.285), Offset(cx - 8, browY * 0.305), p);
        canvas.drawLine(Offset(cx + 8,  browY * 0.305), Offset(cx + 24, browY * 0.285), p);
        break;
      case AssistantMood.sad:
        canvas.drawLine(Offset(cx - 24, browY * 0.305), Offset(cx - 8, browY * 0.285), p);
        canvas.drawLine(Offset(cx + 8,  browY * 0.285), Offset(cx + 24, browY * 0.305), p);
        break;
      case AssistantMood.shocked:
        canvas.drawLine(Offset(cx - 24, browY * 0.245), Offset(cx - 8, browY * 0.255), p);
        canvas.drawLine(Offset(cx + 8,  browY * 0.255), Offset(cx + 24, browY * 0.245), p);
        break;
      case AssistantMood.tired:
        canvas.drawLine(Offset(cx - 24, browY * 0.310), Offset(cx - 8, browY * 0.305), p);
        canvas.drawLine(Offset(cx + 8,  browY * 0.305), Offset(cx + 24, browY * 0.310), p);
        break;
      case AssistantMood.happy:
        canvas.drawLine(Offset(cx - 24, browY * 0.286), Offset(cx - 8, browY * 0.274), p);
        canvas.drawLine(Offset(cx + 8,  browY * 0.274), Offset(cx + 24, browY * 0.286), p);
        break;
    }
    p.style = PaintingStyle.fill;
  }

  // ── Eyes ──────────────────────────────────────────────────────────────────
  void _drawEyes(Canvas canvas, Paint p, Size size, double cx) {
    final eyeL = Offset(cx - 14, size.height * 0.385);
    final eyeR = Offset(cx + 14, size.height * 0.385);
    final baseH = mood == AssistantMood.shocked ? 22.0 : mood == AssistantMood.tired ? 13.0 : 18.0;
    final openH  = baseH * (1 - blinkValue);
    final topH   = mood == AssistantMood.tired ? openH * 0.55 : openH;

    if (openH > 2.5) {
      // sclera
      p.color = Colors.white;
      canvas.drawOval(Rect.fromCenter(center: eyeL, width: 21, height: topH), p);
      canvas.drawOval(Rect.fromCenter(center: eyeR, width: 21, height: topH), p);

      // iris — warm amber-brown
      final irisR = 7.5 * (1 - blinkValue * 0.4);
      p.color = const Color(0xFF8B4513);
      canvas.drawCircle(eyeL, irisR, p);
      canvas.drawCircle(eyeR, irisR, p);
      p.color = const Color(0xFFBB6622).withOpacity(0.7);
      canvas.drawCircle(eyeL, irisR * 0.6, p);
      canvas.drawCircle(eyeR, irisR * 0.6, p);

      // pupil
      p.color = Colors.black.withOpacity(0.9);
      canvas.drawCircle(eyeL, irisR * 0.45, p);
      canvas.drawCircle(eyeR, irisR * 0.45, p);

      // accent ring
      p..color = accent.withOpacity(0.32 + glowPulse * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(eyeL, irisR, p);
      canvas.drawCircle(eyeR, irisR, p);
      p.style = PaintingStyle.fill;

      // catchlights
      p.color = Colors.white.withOpacity(0.95);
      canvas.drawCircle(eyeL.translate(2.2, -2.2), 2.2, p);
      canvas.drawCircle(eyeR.translate(2.2, -2.2), 2.2, p);
      canvas.drawCircle(eyeL.translate(-2.8, 2.5), 1.1, p);
      canvas.drawCircle(eyeR.translate(-2.8, 2.5), 1.1, p);

      // shocked — extra ring
      if (mood == AssistantMood.shocked) {
        p..color = Colors.white.withOpacity(0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(eyeL, irisR * 1.15, p);
        canvas.drawCircle(eyeR, irisR * 1.15, p);
        p.style = PaintingStyle.fill;
      }

      // eyelashes
      final lashLen = 4.5 * (1 - blinkValue);
      if (lashLen > 0.5) {
        p..color = const Color(0xFF2C1005)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        for (final eye in [eyeL, eyeR]) {
          for (int i = 0; i < 6; i++) {
            final t = i / 5.0;
            final lx = eye.dx - 10 + t * 20;
            final by = eye.dy - topH / 2 + 1;
            canvas.drawLine(Offset(lx, by), Offset(lx, by - lashLen - sin(t * pi) * 1.8), p);
          }
        }
        p.style = PaintingStyle.fill;
      }

      // tired — drooping lower lid shadow
      if (mood == AssistantMood.tired) {
        p..color = const Color(0xFF2C1005).withOpacity(0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        for (final eye in [eyeL, eyeR]) {
          canvas.drawPath(Path()
            ..moveTo(eye.dx - 10, eye.dy + topH / 2 - 1)
            ..quadraticBezierTo(eye.dx, eye.dy - 1, eye.dx + 10, eye.dy + topH / 2 - 1), p);
        }
        p.style = PaintingStyle.fill;
      }

    } else {
      // closed — cute curve
      p..color = const Color(0xFF2C1005)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      for (final eye in [eyeL, eyeR]) {
        canvas.drawPath(Path()
          ..moveTo(eye.dx - 10, eye.dy)
          ..quadraticBezierTo(eye.dx, eye.dy - 4, eye.dx + 10, eye.dy), p);
      }
      if (mood == AssistantMood.happy) {
        p.style = PaintingStyle.fill;
        p.color = const Color(0xFFFFDD44).withOpacity(0.8);
        canvas.drawCircle(eyeL.translate(0, -6), 1.5, p);
        canvas.drawCircle(eyeR.translate(0, -6), 1.5, p);
      }
      p.style = PaintingStyle.fill;
    }
  }

  // ── Glasses ───────────────────────────────────────────────────────────────
  void _drawGlasses(Canvas canvas, Paint p, Size size, double cx) {
    final eyeL = Offset(cx - 14, size.height * 0.385);
    final eyeR = Offset(cx + 14, size.height * 0.385);
    p..color = accent.withOpacity(0.52 + glowPulse * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;
    final gl = RRect.fromRectAndRadius(Rect.fromCenter(center: eyeL, width: 26, height: 19), const Radius.circular(5));
    final gr = RRect.fromRectAndRadius(Rect.fromCenter(center: eyeR, width: 26, height: 19), const Radius.circular(5));
    canvas.drawRRect(gl, p);
    canvas.drawRRect(gr, p);
    canvas.drawLine(Offset(eyeL.dx + 13, eyeL.dy), Offset(eyeR.dx - 13, eyeR.dy), p);
    canvas.drawLine(Offset(eyeL.dx - 13, eyeL.dy), Offset(eyeL.dx - 22, eyeL.dy - 3), p);
    canvas.drawLine(Offset(eyeR.dx + 13, eyeR.dy), Offset(eyeR.dx + 22, eyeR.dy - 3), p);
    p..color = accent.withOpacity(0.06 + glowPulse * 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(gl, p);
    canvas.drawRRect(gr, p);
  }

  // ── Nose ──────────────────────────────────────────────────────────────────
  void _drawNose(Canvas canvas, Paint p, Size size, double cx) {
    p..color = const Color(0xFFCC8050).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()
      ..moveTo(cx, size.height * 0.44)
      ..quadraticBezierTo(cx - 4, size.height * 0.505, cx - 4, size.height * 0.518)
      ..moveTo(cx - 4, size.height * 0.518)
      ..quadraticBezierTo(cx, size.height * 0.528, cx + 4, size.height * 0.518), p);
    p.style = PaintingStyle.fill;
  }

  // ── Mouth ─────────────────────────────────────────────────────────────────
  void _drawMouth(Canvas canvas, Paint p, Size size, double cx) {
    final mc = Offset(cx, size.height * 0.565);
    const lip = Color(0xFFE07070);

    if (mouthValue > 0.05) {
      p.color = const Color(0xFF7A1010);
      canvas.drawOval(Rect.fromCenter(center: mc, width: 10, height: 5 + mouthValue * 8), p);
      p.color = Colors.white.withOpacity(0.88);
      canvas.drawRect(Rect.fromCenter(center: mc.translate(0, -0.5), width: 8, height: 2), p);
      return;
    }

    p..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round;

    switch (mood) {
      case AssistantMood.happy:
        p.color = lip;
        final smile = Path()
          ..moveTo(mc.dx - 7, mc.dy - 1)
          ..quadraticBezierTo(mc.dx, mc.dy + 6, mc.dx + 7, mc.dy - 1);
        canvas.drawPath(smile, p);
        p..style = PaintingStyle.fill
          ..color = Colors.white.withOpacity(0.85);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: mc.translate(0, 2), width: 9, height: 3),
            const Radius.circular(1.5)), p);
        p..style = PaintingStyle.stroke
          ..color = lip;
        canvas.drawPath(smile, p);
        break;

      case AssistantMood.angry:
        p.color = const Color(0xFFDD3333);
        canvas.drawPath(Path()
          ..moveTo(mc.dx - 7, mc.dy + 2)
          ..quadraticBezierTo(mc.dx, mc.dy - 4, mc.dx + 7, mc.dy + 2), p);
        p..strokeWidth = 1.0
          ..color = Colors.white.withOpacity(0.5);
        for (int i = -2; i <= 2; i++) {
          canvas.drawLine(Offset(mc.dx + i * 2.2, mc.dy - 2.5), Offset(mc.dx + i * 2.2, mc.dy + 0.5), p);
        }
        break;

      case AssistantMood.sad:
        p.color = const Color(0xFF88AACC);
        canvas.drawPath(Path()
          ..moveTo(mc.dx - 7, mc.dy - 2)
          ..quadraticBezierTo(mc.dx, mc.dy + 6, mc.dx + 7, mc.dy - 2), p);
        // lower lip quiver dot
        p..style = PaintingStyle.fill
          ..color = const Color(0xFF88AACC).withOpacity(0.6);
        canvas.drawCircle(mc.translate(0, 6), 1.2, p);
        break;

      case AssistantMood.shocked:
        p..style = PaintingStyle.fill
          ..color = const Color(0xFF7A1010);
        canvas.drawOval(Rect.fromCenter(center: mc, width: 12, height: 14), p);
        p.color = Colors.white.withOpacity(0.7);
        canvas.drawOval(Rect.fromCenter(center: mc.translate(0, -1), width: 8, height: 5), p);
        break;

      case AssistantMood.tired:
        p..color = lip.withOpacity(0.65);
        canvas.drawPath(Path()
          ..moveTo(mc.dx - 6, mc.dy)
          ..quadraticBezierTo(mc.dx, mc.dy + 2.5, mc.dx + 6, mc.dy), p);
        break;
    }
    p.style = PaintingStyle.fill;
  }

  // ── Front hair / bangs ────────────────────────────────────────────────────
  void _drawFrontHair(Canvas canvas, Paint p, Size size, double cx) {
    // dark outline
    p.color = const Color(0xFF1A0A00);
    canvas.drawPath(Path()
      ..moveTo(cx - 42, size.height * 0.19)
      ..lineTo(cx - 32, size.height * 0.30)
      ..lineTo(cx - 22, size.height * 0.22)
      ..lineTo(cx - 11, size.height * 0.33)
      ..lineTo(cx - 3,  size.height * 0.20)
      ..lineTo(cx + 3,  size.height * 0.29)
      ..lineTo(cx + 11, size.height * 0.19)
      ..lineTo(cx + 22, size.height * 0.28)
      ..lineTo(cx + 36, size.height * 0.18)
      ..lineTo(cx + 42, size.height * 0.19)
      ..quadraticBezierTo(cx + 44, -4, cx, -7)
      ..quadraticBezierTo(cx - 44, -4, cx - 42, size.height * 0.19)
      ..close(), p);

    // golden bangs
    p.color = const Color(0xFFDAA020);
    canvas.drawPath(Path()
      ..moveTo(cx - 40, size.height * 0.19)
      ..lineTo(cx - 30, size.height * 0.29)
      ..lineTo(cx - 21, size.height * 0.22)
      ..lineTo(cx - 10, size.height * 0.32)
      ..lineTo(cx - 2,  size.height * 0.20)
      ..lineTo(cx + 2,  size.height * 0.28)
      ..lineTo(cx + 10, size.height * 0.19)
      ..lineTo(cx + 21, size.height * 0.27)
      ..lineTo(cx + 35, size.height * 0.18)
      ..lineTo(cx + 40, size.height * 0.19)
      ..quadraticBezierTo(cx + 42, -3, cx, -6)
      ..quadraticBezierTo(cx - 42, -3, cx - 40, size.height * 0.19)
      ..close(), p);

    // specular
    p.color = const Color(0xFFFFF0A0).withOpacity(0.55);
    canvas.drawPath(Path()
      ..moveTo(cx - 14, size.height * 0.025)
      ..quadraticBezierTo(cx, size.height * 0.005, cx + 14, size.height * 0.025)
      ..lineTo(cx + 10, size.height * 0.10)
      ..quadraticBezierTo(cx, size.height * 0.075, cx - 10, size.height * 0.10)
      ..close(), p);

    // hair clip accessory (mood color)
    final clip = Offset(cx + 22, size.height * 0.15);
    p.color = accent.withOpacity(0.85 + glowPulse * 0.1);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: clip, width: 10, height: 5), const Radius.circular(2)), p);
    p.color = Colors.white.withOpacity(0.4);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: clip.translate(-1, -0.5), width: 5, height: 2), const Radius.circular(1)), p);
  }

  // ── Mood FX ───────────────────────────────────────────────────────────────
  void _drawMoodFx(Canvas canvas, Paint p, Size size, double cx) {
    switch (mood) {
      case AssistantMood.angry:   _fxAngry(canvas, p, size, cx);   break;
      case AssistantMood.sad:     _fxSad(canvas, p, size, cx);     break;
      case AssistantMood.shocked: _fxShocked(canvas, p, size, cx); break;
      case AssistantMood.tired:   _fxTired(canvas, p, size, cx);   break;
      case AssistantMood.happy:   _fxHappy(canvas, p, size, cx);   break;
    }
  }

  void _fxAngry(Canvas canvas, Paint p, Size size, double cx) {
    // forehead vein
    p..color = const Color(0xFFFF3333).withOpacity(0.65 + glowPulse * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()
      ..moveTo(cx - 12, size.height * 0.145)
      ..lineTo(cx - 8,  size.height * 0.115)
      ..lineTo(cx - 5,  size.height * 0.145)
      ..lineTo(cx - 2,  size.height * 0.120), p);
    // steam puffs
    p..color = const Color(0xFFFF7755).withOpacity(0.30 + glowPulse * 0.15)
      ..strokeWidth = 2.2;
    for (int i = 0; i < 3; i++) {
      final x = cx - 14 + i * 14.0;
      canvas.drawPath(Path()
        ..moveTo(x, -6)
        ..quadraticBezierTo(x + 4, -14, x, -20)
        ..quadraticBezierTo(x - 4, -26, x, -32), p);
    }
    p.style = PaintingStyle.fill;
  }

  void _fxSad(Canvas canvas, Paint p, Size size, double cx) {
    final t = fxProgress % 1.0;

    void tear(double xPos, double phase) {
      final ty = size.height * 0.46 + (phase % 1.0) * size.height * 0.20;
      final ta = sin((phase % 1.0) * pi);
      p.color = const Color(0xFF88BBEE).withOpacity(ta * 0.75);
      canvas.drawPath(Path()
        ..moveTo(xPos, ty)
        ..quadraticBezierTo(xPos + 3, ty + 6, xPos, ty + 10)
        ..quadraticBezierTo(xPos - 3, ty + 6, xPos, ty), p);
    }

    tear(cx - 23, t);
    tear(cx + 23, (t + 0.45) % 1.0);
  }

  void _fxShocked(Canvas canvas, Paint p, Size size, double cx) {
    // radial lines
    p..color = const Color(0xFFFFCC00).withOpacity(0.50 + glowPulse * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final fc = Offset(cx, size.height * 0.35);
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8.0) * 2 * pi;
      canvas.drawLine(
        fc.translate(cos(angle) * 42, sin(angle) * 42),
        fc.translate(cos(angle) * (56 + (i % 3) * 4), sin(angle) * (56 + (i % 3) * 4)),
        p,
      );
    }
    // sweat drop
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFF88DDFF).withOpacity(0.75);
    canvas.drawPath(Path()
      ..moveTo(cx + 38, size.height * 0.16)
      ..quadraticBezierTo(cx + 42, size.height * 0.22, cx + 38, size.height * 0.26)
      ..quadraticBezierTo(cx + 34, size.height * 0.22, cx + 38, size.height * 0.16), p);
  }

  void _fxTired(Canvas canvas, Paint p, Size size, double cx) {
    final t = fxProgress % 1.0;
    // Z Z Z letters
    final zData = [
      (cx + 28.0, size.height * 0.15 - t * 22, 10.0, t),
      (cx + 37.0, size.height * 0.07 - ((t + 0.33) % 1.0) * 22, 8.0, (t + 0.33) % 1.0),
      (cx + 45.0, size.height * 0.01 - ((t + 0.66) % 1.0) * 22, 6.0, (t + 0.66) % 1.0),
    ];
    p..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final (x, y, sz, phase) in zData) {
      final alpha = sin(phase * pi) * 0.7;
      if (alpha < 0.05) continue;
      p..color = const Color(0xFFAA99CC).withOpacity(alpha)
        ..strokeWidth = sz * 0.2;
      canvas.drawPath(Path()
        ..moveTo(x, y)
        ..lineTo(x + sz, y)
        ..lineTo(x, y + sz)
        ..lineTo(x + sz, y + sz), p);
    }
    p.style = PaintingStyle.fill;
  }

  void _fxHappy(Canvas canvas, Paint p, Size size, double cx) {
    // 4-point sparkle stars
    final stars = [
      (cx - 38.0, size.height * 0.10, 5.0),
      (cx + 40.0, size.height * 0.12, 4.0),
      (cx - 42.0, size.height * 0.30, 3.5),
      (cx + 44.0, size.height * 0.33, 3.0),
    ];
    for (final (x, y, r) in stars) {
      final pulse = 0.6 + glowPulse * 0.4;
      p.color = const Color(0xFFFFEE44).withOpacity(pulse * 0.85);
      final path = Path();
      for (int i = 0; i < 8; i++) {
        final a = (i / 8.0) * 2 * pi - pi / 2;
        final rad = i.isEven ? r * pulse : r * pulse * 0.4;
        final pt = Offset(x + cos(a) * rad, y + sin(a) * rad);
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter old) =>
      old.blinkValue != blinkValue || old.mouthValue != mouthValue ||
          old.hairWave != hairWave || old.glowPulse != glowPulse ||
          old.fxProgress != fxProgress || old.mood != mood;
}

// ═══════════════════════════════════════════════════════════════════════════
// HUD FRAME
// ═══════════════════════════════════════════════════════════════════════════

class _HudPainter extends CustomPainter {
  final double scan, glow;
  final Color accent;
  const _HudPainter({required this.scan, required this.glow, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = accent.withOpacity(0.44 + glow * 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square;
    const a = 16.0;
    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o.translate(a * dx, 0), p);
      canvas.drawLine(o, o.translate(0, a * dy), p);
    }
    corner(Offset.zero, 1, 1);
    corner(Offset(size.width, 0), -1, 1);
    corner(Offset(0, size.height), 1, -1);
    corner(Offset(size.width, size.height), -1, -1);
    p..color = accent.withOpacity(0.06)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, scan * size.height), Offset(size.width, scan * size.height), p);
  }

  @override
  bool shouldRepaint(covariant _HudPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// DOT GRID
// ═══════════════════════════════════════════════════════════════════════════

class _DotGridPainter extends CustomPainter {
  final Color accent;
  const _DotGridPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = accent.withOpacity(0.04);
    for (double x = 0; x < size.width; x += 13) {
      for (double y = 0; y < size.height; y += 13) {
        canvas.drawCircle(Offset(x, y), 0.8, p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// BUBBLE TAIL
// ═══════════════════════════════════════════════════════════════════════════

class _TailPainter extends CustomPainter {
  final Color accent;
  const _TailPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF080F1C)
      ..style = PaintingStyle.fill;
    canvas.drawPath(Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.25, size.height)
      ..close(), p);
    p..color = accent.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, 0), Offset(size.width * 0.25, size.height), p);
  }

  @override
  bool shouldRepaint(_) => false;
}