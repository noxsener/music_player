// lib/widgets/animations/cyber_morning_service.dart
//
// ┌──────────────────────────────────────────────────────────────────────┐
// │  CyberMorningService  v2                                             │
// │                                                                      │
// │  Two modes:                                                          │
// │   • Auto mode  — plays once, calls onComplete, disappears           │
// │   • Loop mode  — loops at loopAtScene until controller.complete()   │
// │                  is called, then finishes and calls onComplete       │
// │                                                                      │
// │  Parameters:                                                         │
// │   • logoImage   — optional logo shown top-center                   │
// │   • chatText    — overrides caption text                            │
// │   • loopAtScene — 0..1 loop point (enables loop mode)              │
// │   • controller  — CyberMorningServiceController                    │
// │                                                                      │
// │  Usage (auto):                                                       │
// │    CyberMorningService(onComplete: () => pop())                      │
// │                                                                      │
// │  Usage (loop):                                                       │
// │    final ctrl = CyberMorningServiceController();                     │
// │    CyberMorningService(loopAtScene: 0.66, controller: ctrl);         │
// │    // later: ctrl.complete();                                        │
// └──────────────────────────────────────────────────────────────────────┘

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import 'cyber_character.dart';

// ─── Controller ───────────────────────────────────────────────────────────────

class CyberMorningServiceController {
  _CyberMorningServiceState? _state;
  void _attach(_CyberMorningServiceState s) => _state = s;
  void complete() => _state?._requestComplete();
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class CyberMorningService extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration duration;
  final double? loopAtScene;
  final CyberMorningServiceController? controller;
  final ImageProvider? logoImage;
  final String? chatText;

  const CyberMorningService({
    super.key,
    this.onComplete,
    this.duration = const Duration(seconds: 7),
    this.loopAtScene,
    this.controller,
    this.logoImage,
    this.chatText,
  });

  bool get isLoopMode => loopAtScene != null;

  @override
  State<CyberMorningService> createState() => _CyberMorningServiceState();
}

// ─── State ────────────────────────────────────────────────────────────────────

class _CyberMorningServiceState extends State<CyberMorningService>
    with TickerProviderStateMixin {

  late final AnimationController _main;
  late final AnimationController _blink;
  late final AnimationController _float;
  late final AnimationController _steam;
  late final AnimationController _glow;

  bool _completionRequested = false;
  bool _isLooping = false;

  static const double _sWalkEnd      = 0.14;
  static const double _sClothEnd     = 0.30;
  static const double _sNewspaperEnd = 0.48;
  static const double _sFetchEnd     = 0.66;
  static const double _sCoffeeEnd    = 0.82;

  double get _t => _main.value;
  double _s(double a, double b) => ((_t - a) / (b - a)).clamp(0.0, 1.0);
  double _e(double a, double b, {Curve c = Curves.easeInOut}) =>
      c.transform(_s(a, b));

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);

    _main  = AnimationController(vsync: this, duration: widget.duration);
    _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 115));
    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _steam = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _glow  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _startBlink();

    if (widget.isLoopMode) {
      _runLoopMode();
    } else {
      _main.addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onComplete?.call();
      });
      _main.forward();
    }
  }

  void _requestComplete() {
    if (!mounted) return;
    _completionRequested = true;
  }

  Future<void> _runLoopMode() async {
    final loopEnd = widget.loopAtScene!.clamp(0.01, 0.99);

    // Phase 1: play intro
    await _main.animateTo(loopEnd);

    // Phase 2: idle loop at loopEnd
    _isLooping = true;
    while (mounted && !_completionRequested) {
      await _main.animateTo(
        (loopEnd - 0.04).clamp(0.0, 1.0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
      if (!mounted || _completionRequested) break;
      await _main.animateTo(
        loopEnd,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
    _isLooping = false;

    // Phase 3: complete rest of animation
    if (!mounted) return;
    await _main.animateTo(1.0);
    if (mounted) widget.onComplete?.call();
  }

  void _startBlink() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 1600 + Random().nextInt(2200)));
      if (!mounted) break;
      await _blink.forward();
      await _blink.reverse();
    }
  }

  @override
  void dispose() {
    _main.dispose(); _blink.dispose(); _float.dispose();
    _steam.dispose(); _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D18),
      body: AnimatedBuilder(
        animation: Listenable.merge([_main, _blink, _float, _steam, _glow]),
        builder: (ctx, _) {
          final size = MediaQuery.of(ctx).size;
          // Constrain table to max 520px wide, centred
          final tableW    = size.width.clamp(0.0, 520.0);
          final tableOffX = (size.width - tableW) / 2;

          return Stack(children: [
            _buildBg(size),
            _buildCharacter(size),
            _buildTableScene(size, tableW, tableOffX),
            if (widget.logoImage != null) _buildLogo(size),
            _buildCaption(size),
            Positioned(
              bottom: 20, left: 30, right: 30,
              child: _buildProgressBar(),
            ),
          ]);
        },
      ),
    );
  }

  // ── Background ──────────────────────────────────────────────────────────────

  Widget _buildBg(Size size) =>
      CustomPaint(size: size, painter: _MsBgPainter(glow: _glow.value));

  // ── Table ───────────────────────────────────────────────────────────────────

  Widget _buildTableScene(Size size, double tableW, double offX) =>
      Positioned(
        left: offX, top: 0, width: tableW, height: size.height,
        child: CustomPaint(
          painter: _MsTablePainter(
            t: _t, s: _s, e: _e,
            steamPhase: _steam.value,
            glow: _glow.value,
          ),
        ),
      );

  // ── Logo ────────────────────────────────────────────────────────────────────

  Widget _buildLogo(Size size) => Positioned(
    top: size.height * 0.07,
    left: size.width / 2 - 44,
    child: Container(
      width: 88, height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: DecorationImage(image: widget.logoImage!, fit: BoxFit.contain),
        boxShadow: [
          BoxShadow(color: AppRawColors.cyan.withOpacity(0.18), blurRadius: 18),
        ],
      ),
    ),
  );

  // ── Character ───────────────────────────────────────────────────────────────

  Widget _buildCharacter(Size size) {
    double charX;
    if (_t < _sWalkEnd) {
      final p = _e(0.0, _sWalkEnd, c: Curves.easeOutCubic);
      charX = size.width * (1.12 - 0.54 * p);
    } else {
      charX = size.width * 0.58;
    }

    CyberPose pose;
    CyberExpr expr;
    if (_t < _sWalkEnd) {
      pose = CyberPose.stand;         expr = CyberExpr.happy;
    } else if (_t < _sClothEnd) {
      pose = CyberPose.holdBothHands; expr = CyberExpr.neutral;
    } else if (_t < _sNewspaperEnd) {
      pose = CyberPose.reach;         expr = CyberExpr.neutral;
    } else if (_t < _sFetchEnd) {
      pose = CyberPose.stand;         expr = CyberExpr.neutral;
    } else if (_t < _sCoffeeEnd) {
      pose = CyberPose.sip;           expr = CyberExpr.neutral;
    } else {
      pose = CyberPose.wave;          expr = CyberExpr.happy;
    }

    return Positioned(
      left: charX - 170,
      top: size.height * 0.24,
      child: CustomPaint(
        size: const Size(340, 360),
        painter: CyberCharPainter(
          blink:    _blink.value,
          glow:     _glow.value,
          hairWave: _float.value,
          pose:     pose,
          expr:     expr,
        ),
      ),
    );
  }

  // ── Caption ──────────────────────────────────────────────────────────────────

  Widget _buildCaption(Size size) {
    final text = widget.chatText ??
        (_t < _sWalkEnd        ? '✨ İyi günler!'
            : _t < _sClothEnd       ? '🗂 Masanızı hazırlıyorum...'
            : _t < _sNewspaperEnd   ? '📰 Gazeteniz buyrun!'
            : _t < _sFetchEnd       ? '☕ Kahvenizi getiriyorum...'
            : _t < _sCoffeeEnd      ? '☕ Kahveniz hazır!'
            :                         '🙇 どうぞ！ Buyrun efendim~');

    return Positioned(
      bottom: 48, left: 0, right: 0,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(text),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1828).withOpacity(0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppRawColors.cyan.withOpacity(0.30), width: 1),
              boxShadow: [BoxShadow(color: AppRawColors.cyan.withOpacity(0.08), blurRadius: 14)],
            ),
            child: Text(text, style: const TextStyle(
              color: Color(0xFFDDEEFF), fontSize: 14,
              letterSpacing: 0.4, fontWeight: FontWeight.w500,
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() => Stack(children: [
    Container(height: 2, decoration: BoxDecoration(
      color: AppRawColors.cyan.withOpacity(0.10),
      borderRadius: BorderRadius.circular(1),
    )),
    FractionallySizedBox(
      widthFactor: _t,
      child: Container(height: 2, decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppRawColors.cyan, AppRawColors.cyan.withOpacity(0.35)]),
        borderRadius: BorderRadius.circular(1),
        boxShadow: [BoxShadow(color: AppRawColors.cyan.withOpacity(0.55), blurRadius: 5)],
      )),
    ),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════════
// BACKGROUND PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _MsBgPainter extends CustomPainter {
  final double glow;
  _MsBgPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint();

    // Wall gradient
    p.shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF06101E), Color(0xFF0A1828)],
    ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height * 0.65));
    canvas.drawRect(Rect.fromLTWH(0, 0, sz.width, sz.height * 0.65), p);
    p.shader = null;

    // Floor
    p.shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF0A1828), Color(0xFF060D18)],
    ).createShader(Rect.fromLTWH(0, sz.height * 0.65, sz.width, sz.height * 0.35));
    canvas.drawRect(Rect.fromLTWH(0, sz.height * 0.65, sz.width, sz.height * 0.35), p);
    p.shader = null;

    // Floor line
    p..color = const Color(0xFF1A2A40).withOpacity(0.7)
      ..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawLine(Offset(0, sz.height * 0.65), Offset(sz.width, sz.height * 0.65), p);
    p.style = PaintingStyle.fill;

    // Wall grid
    p..color = const Color(0xFF0C1C2E).withOpacity(0.40)
      ..style = PaintingStyle.stroke..strokeWidth = 0.5;
    for (double x = 0; x < sz.width; x += sz.width * 0.10) {
      canvas.drawLine(Offset(x, 0), Offset(x, sz.height * 0.65), p);
    }
    p.style = PaintingStyle.fill;

    // Window (left side behind character area)
    final wx = sz.width * 0.05; final wy = sz.height * 0.13;
    final ww = sz.width * 0.14; final wh = sz.height * 0.28;
    p.color = AppRawColors.cyan.withOpacity(0.04 + glow * 0.02);
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawRect(Rect.fromLTWH(wx, wy, ww, wh), p);
    p.maskFilter = null;
    p..color = const Color(0xFF1E3050)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawRect(Rect.fromLTWH(wx, wy, ww, wh), p);
    canvas.drawLine(Offset(wx + ww / 2, wy), Offset(wx + ww / 2, wy + wh), p);
    canvas.drawLine(Offset(wx, wy + wh / 2), Offset(wx + ww, wy + wh / 2), p);
    p.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant _MsBgPainter old) => old.glow != glow;
}

// ═══════════════════════════════════════════════════════════════════════════════
// TABLE SCENE PAINTER  (max-width constrained)
// ═══════════════════════════════════════════════════════════════════════════════

class _MsTablePainter extends CustomPainter {
  final double t;
  final double Function(double, double) s;
  final double Function(double, double, {Curve c}) e;
  final double steamPhase, glow;

  static const _sWalkEnd      = 0.14;
  static const _sClothEnd     = 0.30;
  static const _sNewspaperEnd = 0.48;
  static const _sFetchEnd     = 0.66;
  static const _sCoffeeEnd    = 0.82;

  _MsTablePainter({
    required this.t, required this.s, required this.e,
    required this.steamPhase, required this.glow,
  });

  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint()..isAntiAlias = true;
    final cx = sz.width / 2;
    final tableY = sz.height * 0.60;
    // Table extends 44% either side of centre (within constrained width)
    final hw = sz.width * 0.44;

    _drawTableBase(canvas, p, sz, cx, tableY, hw);
    _drawTablecloth(canvas, p, sz, cx, tableY, hw);
    _drawNewspaper(canvas, p, sz, cx, tableY);
    _drawCoffee(canvas, p, sz, cx, tableY);
  }

  void _drawTableBase(Canvas canvas, Paint p, Size sz, double cx,
      double ty, double hw) {
    // Surface
    p.shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF6B4422), Color(0xFF4A2E14)],
    ).createShader(Rect.fromLTWH(cx - hw, ty, hw * 2, 18));
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - hw, ty, hw * 2, 18), const Radius.circular(4)), p);
    p.shader = null;

    // Edge highlight
    p..color = const Color(0xFF9B6442).withOpacity(0.45)
      ..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawLine(Offset(cx - hw, ty), Offset(cx + hw, ty), p);
    p.style = PaintingStyle.fill;

    // Body
    p.color = const Color(0xFF3D2510);
    canvas.drawRect(Rect.fromLTWH(cx - hw + 18, ty + 18, (hw - 18) * 2, sz.height * 0.26), p);

    // Legs
    p.color = const Color(0xFF2E1C0A);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - hw + 20, ty + 18, 14, sz.height * 0.28), const Radius.circular(3)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + hw - 34, ty + 18, 14, sz.height * 0.28), const Radius.circular(3)), p);

    // Wood grain
    p..color = const Color(0xFF5A3818).withOpacity(0.25)
      ..style = PaintingStyle.stroke..strokeWidth = 0.6;
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
          Offset(cx - hw + 18, ty + 4 + i * 3.0),
          Offset(cx + hw - 18, ty + 4 + i * 2.5), p);
    }
    p.style = PaintingStyle.fill;
  }

  void _drawTablecloth(Canvas canvas, Paint p, Size sz, double cx,
      double ty, double hw) {
    final clothP = e(_sWalkEnd, _sClothEnd);
    if (clothP <= 0) return;

    final cw = hw * 2 * clothP;

    // Fill
    p.color = const Color(0xFFF8F5F0).withOpacity(0.93);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - cw / 2, ty - 2, cw, 24), const Radius.circular(3)), p);

    // Embroidery line
    if (clothP > 0.3) {
      p..color = const Color(0xFFDDD8CC).withOpacity((clothP - 0.3) / 0.7 * 0.7)
        ..style = PaintingStyle.stroke..strokeWidth = 0.8;
      canvas.drawLine(
          Offset(cx - cw / 2 + 4, ty + 3),
          Offset(cx + cw / 2 - 4, ty + 3), p);
      p.style = PaintingStyle.fill;
    }

    // Lace scallop
    if (clothP > 0.55) {
      final a = ((clothP - 0.55) / 0.45).clamp(0.0, 1.0);
      p..color = const Color(0xFFEEEAE0).withOpacity(a * 0.9)
        ..style = PaintingStyle.stroke..strokeWidth = 1.2;
      double sx = cx - cw / 2;
      while (sx < cx + cw / 2 - 9) {
        canvas.drawArc(Rect.fromLTWH(sx, ty + 17, 11, 9), 0, pi, false, p);
        sx += 11;
      }
      p.style = PaintingStyle.fill;
    }
  }

  void _drawNewspaper(Canvas canvas, Paint p, Size sz, double cx, double ty) {
    final newsP = e(_sClothEnd, _sNewspaperEnd);
    if (newsP <= 0) return;

    final nw  = 100.0 * newsP;
    final nx  = cx - 40;
    final ny  = ty - 14;

    p.color = const Color(0xFFF0EBE0).withOpacity(newsP);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(nx, ny, nw, 76), const Radius.circular(2)), p);

    if (newsP > 0.35) {
      final a = ((newsP - 0.35) / 0.65).clamp(0.0, 1.0);
      // Headline block
      p.color = const Color(0xFF1A1808).withOpacity(a * 0.60);
      canvas.drawRect(Rect.fromLTWH(nx + 4, ny + 4, nw - 8, 12), p);
      // Text lines
      p..color = const Color(0xFF555040).withOpacity(a * 0.38)
        ..style = PaintingStyle.stroke..strokeWidth = 0.9;
      for (int l = 0; l < 7; l++) {
        final lw = (nw - 14) * (1 - l * 0.04);
        canvas.drawLine(Offset(nx + 5, ny + 22.0 + l * 8), Offset(nx + 5 + lw, ny + 22.0 + l * 8), p);
      }
      // Fold crease
      p..color = const Color(0xFFCCBBAA).withOpacity(a * 0.35)..strokeWidth = 0.7;
      canvas.drawLine(Offset(nx, ny + 38), Offset(nx + nw, ny + 38), p);
      p.style = PaintingStyle.fill;
      // Column divider
      p..color = const Color(0xFF888070).withOpacity(a * 0.25)
        ..style = PaintingStyle.stroke..strokeWidth = 0.6;
      canvas.drawLine(Offset(nx + nw / 2, ny + 22), Offset(nx + nw / 2, ny + 72), p);
      p.style = PaintingStyle.fill;
    }
  }

  void _drawCoffee(Canvas canvas, Paint p, Size sz, double cx, double ty) {
    final coffeeP = e(_sFetchEnd, _sCoffeeEnd, c: Curves.easeOut);
    if (coffeeP <= 0) return;

    final cpx = cx + 55;
    final cpy = ty - 6 - (1 - coffeeP) * 20;

    // Saucer
    p.color = const Color(0xFFDDD5C5).withOpacity(coffeeP);
    canvas.drawOval(Rect.fromCenter(center: Offset(cpx, cpy + 16), width: 40, height: 10), p);

    // Cup
    p.shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [
        const Color(0xFFF2EAD8).withOpacity(coffeeP),
        const Color(0xFFD8CAB2).withOpacity(coffeeP),
      ],
    ).createShader(Rect.fromLTWH(cpx - 15, cpy, 30, 20));
    canvas.drawPath(Path()
      ..moveTo(cpx - 14, cpy + 2)
      ..lineTo(cpx - 11, cpy + 17)
      ..quadraticBezierTo(cpx, cpy + 20, cpx + 11, cpy + 17)
      ..lineTo(cpx + 14, cpy + 2)
      ..close(), p);
    p.shader = null;

    // Rim
    p.color = const Color(0xFFEAE2D2).withOpacity(coffeeP);
    canvas.drawOval(Rect.fromCenter(center: Offset(cpx, cpy + 3), width: 28, height: 7), p);

    // Coffee surface
    p.color = const Color(0xFF3D2010).withOpacity(coffeeP * 0.9);
    canvas.drawOval(Rect.fromCenter(center: Offset(cpx, cpy + 4), width: 22, height: 5), p);
    p.color = const Color(0xFFC08040).withOpacity(coffeeP * 0.60);
    canvas.drawOval(Rect.fromCenter(center: Offset(cpx - 1, cpy + 4), width: 13, height: 3), p);

    // Handle
    p..color = const Color(0xFFD8CAB2).withOpacity(coffeeP)
      ..style = PaintingStyle.stroke..strokeWidth = 3.0..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCenter(center: Offset(cpx + 15, cpy + 11), width: 13, height: 13),
        -pi / 3, pi * 1.4, false, p);
    p.style = PaintingStyle.fill;

    // Steam
    if (coffeeP > 0.55) {
      for (int i = 0; i < 3; i++) {
        final phase = (steamPhase + i * 0.33) % 1.0;
        final sy = cpy - 4 - phase * 28;
        final sx = cpx + sin(phase * pi * 2 + i) * 4.5;
        final a  = sin(phase * pi) * 0.40 * ((coffeeP - 0.55) / 0.45).clamp(0.0, 1.0);
        if (a < 0.02) continue;
        p..color = Colors.white.withOpacity(a)
          ..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round;
        canvas.drawPath(Path()
          ..moveTo(sx, sy + 13)
          ..quadraticBezierTo(sx + 5, sy + 7, sx, sy), p);
        p.style = PaintingStyle.fill;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MsTablePainter old) => true;
}