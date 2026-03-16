// lib/widgets/animations/cyber_file_review.dart
//
// ┌──────────────────────────────────────────────────────────────────────┐
// │  CyberFileReview  v3                                                 │
// │                                                                      │
// │  Two modes:                                                          │
// │   • Auto mode  — plays once, calls onComplete, disappears           │
// │   • Loop mode  — loops at loopAtScene until controller.complete()   │
// │                  then finishes the animation and calls onComplete    │
// │                                                                      │
// │  Parameters:                                                         │
// │   • logoImage   — optional logo shown top-right                    │
// │   • chatText    — caption text override                             │
// │   • loopAtScene — 0..1 loop point (enables loop mode)              │
// │   • controller  — CyberFileReviewController                        │
// │                                                                      │
// │  Scenes (12):                                                        │
// │   0.00–0.09  Walk in and sit                                        │
// │   0.09–0.18  Open File 1 (blue)                                     │
// │   0.18–0.30  Read File 1 — eye scan, page flip, nod                │
// │   0.30–0.38  Notes 1 — calm writing                                 │
// │   0.38–0.46  Open File 2 (red)                                      │
// │   0.46–0.56  Read File 2 — raised brow, lean closer                │
// │   0.56–0.62  Thinking — pen tap, thought bubbles, glasses push     │
// │   0.62–0.72  Notes 2 — urgent writing, red underline               │
// │   0.72–0.80  Open File 3 (green)                                    │
// │   0.80–0.89  Read File 3 — relaxed smile                           │
// │   0.89–0.96  Notes 3 — calm, sticky note                           │
// │   0.96–1.00  Finish — done pile with ✓, double nod                 │
// └──────────────────────────────────────────────────────────────────────┘

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import 'cyber_character.dart';

// ─── Controller ───────────────────────────────────────────────────────────────

class CyberFileReviewController {
  _CyberFileReviewState? _state;
  void _attach(_CyberFileReviewState s) => _state = s;
  void complete() => _state?._requestComplete();
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class CyberFileReview extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration duration;
  final double? loopAtScene;
  final CyberFileReviewController? controller;
  final ImageProvider? logoImage;
  final String? chatText;

  const CyberFileReview({
    super.key,
    this.onComplete,
    this.duration = const Duration(seconds: 10),
    this.loopAtScene,
    this.controller,
    this.logoImage,
    this.chatText,
  });

  bool get isLoopMode => loopAtScene != null;

  @override
  State<CyberFileReview> createState() => _CyberFileReviewState();
}

// ─── State ────────────────────────────────────────────────────────────────────

class _CyberFileReviewState extends State<CyberFileReview>
    with TickerProviderStateMixin {

  late final AnimationController _main;
  late final AnimationController _blink;
  late final AnimationController _glow;
  late final AnimationController _pen;       // 200ms pen wobble
  late final AnimationController _scan;      // 1100ms eye scan
  late final AnimationController _nod;       // 650ms nod
  late final AnimationController _page;      // 480ms page flip
  late final AnimationController _glasses;   // 380ms glasses push
  late final AnimationController _think;     // 320ms thought pulse

  bool _completionRequested = false;

  // Scene boundaries
  static const double _S00 = 0.00; // walk in
  static const double _S01 = 0.09; // open file 1
  static const double _S02 = 0.18; // read file 1
  static const double _S03 = 0.30; // notes 1
  static const double _S04 = 0.38; // open file 2
  static const double _S05 = 0.46; // read file 2
  static const double _S06 = 0.56; // thinking
  static const double _S07 = 0.62; // notes 2
  static const double _S08 = 0.72; // open file 3
  static const double _S09 = 0.80; // read file 3
  static const double _S10 = 0.89; // notes 3
  static const double _S11 = 0.96; // finish
  static const double _S12 = 1.00;

  double get _t => _main.value;
  double _s(double a, double b) => ((_t - a) / (b - a)).clamp(0.0, 1.0);
  double _e(double a, double b, {Curve c = Curves.easeInOut}) =>
      c.transform(_s(a, b));

  // Which file is open: 0=none, 1=blue, 2=red, 3=green
  int get _openFile {
    if (_t < _S01) return 0;
    if (_t < _S04) return 1;
    if (_t < _S08) return 2;
    return 3;
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);

    _main    = AnimationController(vsync: this, duration: widget.duration);
    _blink   = AnimationController(vsync: this, duration: const Duration(milliseconds: 115));
    _glow    = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..repeat(reverse: true);
    _pen     = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))..repeat(reverse: true);
    _scan    = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _nod     = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..repeat(reverse: true);
    _page    = AnimationController(vsync: this, duration: const Duration(milliseconds: 480))..repeat(reverse: true);
    _glasses = AnimationController(vsync: this, duration: const Duration(milliseconds: 380))..repeat(reverse: true);
    _think   = AnimationController(vsync: this, duration: const Duration(milliseconds: 320))..repeat(reverse: true);

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

    await _main.animateTo(loopEnd);

    while (mounted && !_completionRequested) {
      await _main.animateTo(
        (loopEnd - 0.04).clamp(0.0, 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      if (!mounted || _completionRequested) break;
      await _main.animateTo(
        loopEnd,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    if (!mounted) return;
    await _main.animateTo(1.0);
    if (mounted) widget.onComplete?.call();
  }

  void _startBlink() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 2200 + Random().nextInt(2200)));
      if (!mounted) break;
      await _blink.forward();
      await _blink.reverse();
    }
  }

  @override
  void dispose() {
    for (final c in [_main, _blink, _glow, _pen, _scan, _nod, _page, _glasses, _think]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D18),
      body: AnimatedBuilder(
        animation: Listenable.merge([_main, _blink, _glow, _pen, _scan, _nod, _page, _glasses, _think]),
        builder: (ctx, _) {
          final size = MediaQuery.of(ctx).size;
          // Max desk width 520 px, centred
          final deskW    = size.width.clamp(0.0, 520.0);
          final deskOffX = (size.width - deskW) / 2;

          return Stack(children: [
            _buildRoom(size),
            // Character drawn FIRST so desk appears in front of it
            _buildCharacter(size),
            _buildDeskShell(size, deskW, deskOffX),
            _buildDeskProps(size, deskW, deskOffX),
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

  // ── Room ────────────────────────────────────────────────────────────────────

  Widget _buildRoom(Size size) =>
      CustomPaint(size: size, painter: _FrRoomPainter(glow: _glow.value));

  // ── Desk shell ──────────────────────────────────────────────────────────────

  Widget _buildDeskShell(Size size, double deskW, double offX) => Positioned(
    left: offX, top: 0, width: deskW, height: size.height,
    child: CustomPaint(painter: _FrDeskShellPainter(sh: size.height)),
  );

  // ── Desk props (files, notepad, coffee, lamp) — drawn ABOVE desk, BELOW char ──

  Widget _buildDeskProps(Size size, double deskW, double offX) => Positioned(
    left: offX, top: 0, width: deskW, height: size.height,
    child: CustomPaint(
      painter: _FrDeskPropsPainter(
        t:         _t,
        s:         _s,
        e:         _e,
        openFile:  _openFile,
        glow:      _glow.value,
        penPhase:  _pen.value,
        scanPhase: _scan.value,
        nodPhase:  _nod.value,
        pagePhase: _page.value,
        glassesP:  _glasses.value,
        thinkPhase: _think.value,
        sh:        size.height,
      ),
    ),
  );

  // ── Character ───────────────────────────────────────────────────────────────

  Widget _buildCharacter(Size size) {
    // Walk-in X
    final walkP = _e(_S00, _S01, c: Curves.easeOutCubic);
    final charX = _t < _S01
        ? size.width * (1.08 - 0.46 * walkP)
        : size.width * 0.62;

    final isReading = (_t >= _S02 && _t < _S03) ||
        (_t >= _S05 && _t < _S07) ||
        (_t >= _S09 && _t < _S10);
    final isNoting  = (_t >= _S03 && _t < _S04) ||
        (_t >= _S07 && _t < _S08) ||
        (_t >= _S10 && _t < _S11);

    final glassP = (_t >= _S06 && _t < _S07) ? _glasses.value * 3.0 : 0.0;
    final penWob  = isNoting ? _pen.value : 0.0;

    CyberPose pose;
    CyberExpr expr;
    if (_t < _S01) {
      pose = CyberPose.stand;       expr = CyberExpr.neutral;
    } else if (_t < _S02) {
      pose = CyberPose.reach;       expr = CyberExpr.neutral;
    } else if (_t < _S03) {
      pose = CyberPose.writeRight;  expr = CyberExpr.focused;
    } else if (_t < _S04) {
      pose = CyberPose.writeRight;  expr = CyberExpr.focused;
    } else if (_t < _S05) {
      pose = CyberPose.reach;       expr = CyberExpr.curious;
    } else if (_t < _S06) {
      pose = CyberPose.writeRight;  expr = CyberExpr.curious;
    } else if (_t < _S07) {
      pose = CyberPose.penTap;      expr = CyberExpr.curious;
    } else if (_t < _S08) {
      pose = CyberPose.writeUrgent; expr = CyberExpr.focused;
    } else if (_t < _S09) {
      pose = CyberPose.reach;       expr = CyberExpr.neutral;
    } else if (_t < _S10) {
      pose = CyberPose.writeRight;  expr = CyberExpr.happy;
    } else if (_t < _S11) {
      pose = CyberPose.writeRight;  expr = CyberExpr.satisfied;
    } else {
      pose = CyberPose.stand;       expr = CyberExpr.satisfied;
    }

    return Positioned(
      left: charX - 170,
      top: size.height * 0.24,
      child: CustomPaint(
        size: const Size(340, 360),
        painter: CyberCharPainter(
          blink:       _blink.value,
          glow:        _glow.value,
          hairWave:    0.5,
          penWobble:   penWob,
          eyeScan:     isReading ? _scan.value : 0.5,
          glassesPush: glassP,
          pose:        pose,
          expr:        expr,
          isReading:   isReading,
        ),
      ),
    );
  }

  // ── Logo ────────────────────────────────────────────────────────────────────

  Widget _buildLogo(Size size) => Positioned(
    top: size.height * 0.06,
    right: size.width * 0.05,
    child: Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: widget.logoImage!, fit: BoxFit.contain),
        boxShadow: [BoxShadow(color: AppRawColors.cyan.withOpacity(0.18), blurRadius: 14)],
      ),
    ),
  );

  // ── Caption ──────────────────────────────────────────────────────────────────

  Widget _buildCaption(Size size) {
    final text = widget.chatText ??
        (_t < _S01 ? '📁 Dosyalar inceleniyor...'
            : _t < _S03 ? '🔵 Dosya 1 okunuyor...'
            : _t < _S04 ? '✏️ Notlar alınıyor...'
            : _t < _S06 ? '🔴 Dosya 2 okunuyor...'
            : _t < _S07 ? '🤔 Hmm... düşünüyorum...'
            : _t < _S08 ? '⚠️ Önemli notlar kaydediliyor!'
            : _t < _S10 ? '🟢 Dosya 3 okunuyor...'
            : _t < _S11 ? '✍️ Son notlar...'
            :             '✅ İnceleme tamamlandı!');

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
// ROOM PAINTER  (bookshelf, window, clock, ambient light)
// ═══════════════════════════════════════════════════════════════════════════════

class _FrRoomPainter extends CustomPainter {
  final double glow;
  _FrRoomPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint()..isAntiAlias = true;

    // Wall
    p.shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF05101C), Color(0xFF0A1828)],
    ).createShader(Rect.fromLTWH(0, 0, sz.width, sz.height * 0.64));
    canvas.drawRect(Rect.fromLTWH(0, 0, sz.width, sz.height * 0.64), p);
    p.shader = null;

    // Floor
    p.shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF0A1828), Color(0xFF060D18)],
    ).createShader(Rect.fromLTWH(0, sz.height * 0.64, sz.width, sz.height * 0.36));
    canvas.drawRect(Rect.fromLTWH(0, sz.height * 0.64, sz.width, sz.height * 0.36), p);
    p.shader = null;

    // Floor line
    p..color = const Color(0xFF1A2A40).withOpacity(0.70)
      ..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawLine(Offset(0, sz.height * 0.64), Offset(sz.width, sz.height * 0.64), p);
    p.style = PaintingStyle.fill;

    // Wall grid
    p..color = const Color(0xFF0C1C2E).withOpacity(0.35)
      ..style = PaintingStyle.stroke..strokeWidth = 0.5;
    for (double x = 0; x < sz.width; x += sz.width * 0.10) {
      canvas.drawLine(Offset(x, 0), Offset(x, sz.height * 0.64), p);
    }
    p.style = PaintingStyle.fill;

    // ── Bookshelf (left) ────────────────────────────────────────────────────
    final bsx = sz.width * 0.03;
    final bsy = sz.height * 0.10;
    final bsw = sz.width * 0.12;
    final bsh = sz.height * 0.50;

    p.color = const Color(0xFF261508);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(bsx, bsy, bsw, bsh), const Radius.circular(2)), p);

    // Shelves
    p.color = const Color(0xFF3A2010);
    for (int i = 0; i <= 3; i++) {
      canvas.drawRect(Rect.fromLTWH(bsx, bsy + i * bsh / 3, bsw, 4), p);
    }

    // Books
    final bookCols = [
      const Color(0xFF4466AA), const Color(0xFFAA4444), const Color(0xFF44AA66),
      const Color(0xFFAA8822), const Color(0xFF884488), const Color(0xFF448888),
      const Color(0xFFCC6633), const Color(0xFF337755), const Color(0xFF335599),
      const Color(0xFFAA3366), const Color(0xFF669933), const Color(0xFF226688),
    ];
    int bi = 0;
    for (int row = 0; row < 3; row++) {
      double bx = bsx + 3;
      final ry = bsy + row * bsh / 3 + 5;
      while (bx < bsx + bsw - 4) {
        final bw = 6.5 + (bi % 3) * 3.5;
        p.color = bookCols[bi % bookCols.length];
        canvas.drawRect(Rect.fromLTWH(bx, ry, bw, bsh / 3 - 8), p);
        // book spine line
        p..color = bookCols[bi % bookCols.length].withOpacity(0.5)
          ..style = PaintingStyle.stroke..strokeWidth = 0.5;
        canvas.drawLine(Offset(bx + bw * 0.5, ry + 3), Offset(bx + bw * 0.5, ry + bsh / 3 - 10), p);
        p.style = PaintingStyle.fill;
        bx += bw + 1.5;
        bi++;
      }
    }

    // ── Window (top-center) ─────────────────────────────────────────────────
    final wx = sz.width * 0.35; final wy = sz.height * 0.07;
    final ww = sz.width * 0.30; final wh = sz.height * 0.26;
    // Morning light fill
    p.color = const Color(0xFFAADDFF).withOpacity(0.04 + glow * 0.02);
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(Rect.fromLTWH(wx, wy, ww, wh), p);
    p.maskFilter = null;
    p..color = const Color(0xFF1E3050)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawRect(Rect.fromLTWH(wx, wy, ww, wh), p);
    // Cross
    canvas.drawLine(Offset(wx + ww / 2, wy), Offset(wx + ww / 2, wy + wh), p);
    canvas.drawLine(Offset(wx, wy + wh / 2), Offset(wx + ww, wy + wh / 2), p);
    p.style = PaintingStyle.fill;
    // Curtains
    p.color = const Color(0xFF0E2040).withOpacity(0.60);
    canvas.drawPath(Path()
      ..moveTo(wx, wy)..lineTo(wx + ww * 0.18, wy)..lineTo(wx + ww * 0.12, wy + wh)..lineTo(wx, wy + wh)..close(), p);
    canvas.drawPath(Path()
      ..moveTo(wx + ww, wy)..lineTo(wx + ww - ww * 0.18, wy)..lineTo(wx + ww - ww * 0.12, wy + wh)..lineTo(wx + ww, wy + wh)..close(), p);

    // ── Wall clock (top-right) ──────────────────────────────────────────────
    final clx = sz.width * 0.88; final cly = sz.height * 0.12;
    p.color = const Color(0xFF1A2A3E);
    canvas.drawCircle(Offset(clx, cly), 18, p);
    p..color = const Color(0xFF2A3A52)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawCircle(Offset(clx, cly), 18, p);
    // tick marks
    for (int i = 0; i < 12; i++) {
      final angle = i * pi / 6;
      final r1 = i % 3 == 0 ? 12.0 : 14.0;
      p..color = const Color(0xFF6688AA)..strokeWidth = i % 3 == 0 ? 1.5 : 0.8;
      canvas.drawLine(
          Offset(clx + cos(angle) * r1, cly + sin(angle) * r1),
          Offset(clx + cos(angle) * 16, cly + sin(angle) * 16), p);
    }
    // hands
    p..color = const Color(0xFFCCDDEE)..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(clx, cly), Offset(clx + cos(-pi / 2) * 10, cly + sin(-pi / 2) * 10), p);
    p..color = AppRawColors.cyan.withOpacity(0.8)..strokeWidth = 1.2;
    canvas.drawLine(Offset(clx, cly), Offset(clx + cos(pi / 4) * 13, cly + sin(pi / 4) * 13), p);
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFFCCDDEE);
    canvas.drawCircle(Offset(clx, cly), 2, p);

    // ── Ambient character glow ──────────────────────────────────────────────
    p.color = AppRawColors.cyan.withOpacity(0.022 + glow * 0.015);
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 55);
    canvas.drawCircle(Offset(sz.width * 0.62, sz.height * 0.42), 100, p);
    p.maskFilter = null;
  }

  @override
  bool shouldRepaint(covariant _FrRoomPainter old) => old.glow != glow;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESK SHELL PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _FrDeskShellPainter extends CustomPainter {
  final double sh;
  _FrDeskShellPainter({required this.sh});

  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint()..isAntiAlias = true;
    final cx = sz.width / 2;
    final ty = sh * 0.60;
    final hw = sz.width * 0.44;

    // Surface
    p.shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF6B4422), Color(0xFF4A2E14)],
    ).createShader(Rect.fromLTWH(cx - hw, ty, hw * 2, 22));
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - hw, ty, hw * 2, 22), const Radius.circular(4)), p);
    p.shader = null;

    p..color = const Color(0xFF9B6442).withOpacity(0.45)
      ..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawLine(Offset(cx - hw, ty), Offset(cx + hw, ty), p);
    p.style = PaintingStyle.fill;

    // Body
    p.color = const Color(0xFF3D2510);
    canvas.drawRect(Rect.fromLTWH(cx - hw + 18, ty + 22, (hw - 18) * 2, sh * 0.28), p);

    // Wood grain lines
    p..color = const Color(0xFF5A3818).withOpacity(0.20)
      ..style = PaintingStyle.stroke..strokeWidth = 0.6;
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
          Offset(cx - hw + 20, ty + 5 + i * 3.0),
          Offset(cx + hw - 20, ty + 5 + i * 2.7), p);
    }
    p.style = PaintingStyle.fill;

    // Legs
    p.color = const Color(0xFF2E1C0A);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - hw + 22, ty + 22, 14, sh * 0.30), const Radius.circular(3)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + hw - 36, ty + 22, 14, sh * 0.30), const Radius.circular(3)), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESK PROPS PAINTER  (files, notepad, pen, coffee, thought bubbles)
// Items drawn relative to desk surface — always ABOVE the desk line
// ═══════════════════════════════════════════════════════════════════════════════

class _FrDeskPropsPainter extends CustomPainter {
  final double t, glow, penPhase, scanPhase, nodPhase, pagePhase, glassesP, thinkPhase;
  final int openFile;
  final double Function(double, double) s;
  final double Function(double, double, {Curve c}) e;
  final double sh;

  static const _S01 = 0.09;
  static const _S02 = 0.18;
  static const _S03 = 0.30;
  static const _S04 = 0.38;
  static const _S05 = 0.46;
  static const _S06 = 0.56;
  static const _S07 = 0.62;
  static const _S08 = 0.72;
  static const _S09 = 0.80;
  static const _S10 = 0.89;
  static const _S11 = 0.96;

  _FrDeskPropsPainter({
    required this.t, required this.s, required this.e,
    required this.openFile, required this.glow,
    required this.penPhase, required this.scanPhase,
    required this.nodPhase, required this.pagePhase,
    required this.glassesP, required this.thinkPhase,
    required this.sh,
  });

  // Desk surface Y — all items drawn ABOVE this
  double get _ty => sh * 0.60;

  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint()..isAntiAlias = true;
    final cx = sz.width / 2;

    _drawInboxStack(canvas, p, sz, cx);
    _drawOpenFile(canvas, p, sz, cx);
    _drawNotepad(canvas, p, sz, cx);
    _drawCoffeeMug(canvas, p, sz, cx);
    _drawDeskLamp(canvas, p, sz, cx);
    _drawDonePile(canvas, p, sz, cx);
    _drawThoughtBubble(canvas, p, sz, cx);
  }

  void _drawInboxStack(Canvas canvas, Paint p, Size sz, double cx) {
    // Inbox on left side of desk — show until file 3 opened
    final alpha = t < _S08 ? 1.0 : (1.0 - s(_S08, _S08 + 0.06)).clamp(0.0, 1.0);
    if (alpha <= 0) return;

    final ix = cx - sz.width * 0.28;
    // Files sit ON desk surface: ty - small offset
    final iy = _ty - 4;

    final fileColors = [
      const Color(0xFF4488CC), // blue
      const Color(0xFFCC4444), // red
      const Color(0xFF44AA66), // green
    ];

    for (int i = 2; i >= 0; i--) {
      // Files already read shrink/fade slightly
      final fileAlpha = (t > _S01 + i * (_S08 - _S01) / 3)
          ? (alpha * 0.55).clamp(0.0, 1.0) : alpha;
      final yOff = -(i * 5.0);

      canvas.save();
      canvas.translate(ix + i * 3.0, iy + yOff);
      canvas.rotate(-0.04 + i * 0.03);

      p.color = fileColors[i].withOpacity(fileAlpha);
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 72, height: 52),
          const Radius.circular(2)), p);
      // folder tab
      p.color = fileColors[i].withOpacity(fileAlpha * 0.75);
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(-36, -29, 22, 7), const Radius.circular(2)), p);

      canvas.restore();
    }

    // Inbox tray
    p.color = const Color(0xFF1A2A3E).withOpacity(alpha * 0.75);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(ix - 40, iy + 6, 80, 8), const Radius.circular(2)), p);
  }

  void _drawOpenFile(Canvas canvas, Paint p, Size sz, double cx) {
    if (openFile == 0) return;

    final fileColor = openFile == 1 ? const Color(0xFF4488CC)
        : openFile == 2             ? const Color(0xFFCC4444)
        :                             const Color(0xFF44AA66);

    // File appears center-left, on the desk surface
    final fx = cx - 20;
    final fy = _ty - 14;

    final openP = openFile == 1 ? e(_S01, _S02)
        : openFile == 2         ? e(_S04, _S05)
        :                         e(_S08, _S09);

    canvas.save();
    canvas.translate(fx, fy);

    // Folder base
    p.color = fileColor;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 118, height: 82),
        const Radius.circular(3)), p);

    // Left page
    p.color = const Color(0xFFF5F0E6);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(-57, -38, 55, 76), const Radius.circular(2)), p);

    // Right page — flips open
    canvas.save();
    canvas.translate(2, 0);
    canvas.scale(1.0 - sin(pagePhase * pi) * 0.80, 1.0);
    p.color = sin(pagePhase * pi) > 0.5
        ? const Color(0xFFEBE5D5)
        : const Color(0xFFF8F4EA);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -38, 56, 76), const Radius.circular(2)), p);
    canvas.restore();

    // Scan highlight (moves with eyeScan)
    final scanY = -28.0 + scanPhase * 56;
    p.color = const Color(0xFFFFFF55).withOpacity(0.16);
    canvas.drawRect(Rect.fromLTWH(-56, scanY - 4, 55, 9), p);

    // Text lines (left page)
    p..color = const Color(0xFF505040).withOpacity(0.45)
      ..style = PaintingStyle.stroke..strokeWidth = 0.85;
    for (int l = 0; l < 8; l++) {
      final w = 44.0 - (l % 4) * 4;
      canvas.drawLine(Offset(-53, -32.0 + l * 9), Offset(-53 + w, -32.0 + l * 9), p);
    }
    // Headline
    p..strokeWidth = 2.0..color = const Color(0xFF1A1808).withOpacity(0.60);
    canvas.drawLine(const Offset(-53, -38), const Offset(-22, -38), p);

    // Text lines (right page)
    p..strokeWidth = 0.85..color = const Color(0xFF505040).withOpacity(0.38);
    for (int l = 0; l < 7; l++) {
      final w = 38.0 - (l % 3) * 5;
      canvas.drawLine(Offset(5, -30.0 + l * 9), Offset(5 + w, -30.0 + l * 9), p);
    }

    // Urgent underline (file 2 notes)
    if (openFile == 2 && t >= _S07 && t < _S08) {
      final ulP = s(_S07, _S07 + 0.05);
      p..color = const Color(0xFFDD2222).withOpacity(ulP * 0.85)
        ..strokeWidth = 2.2..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(-53, -30 + scanPhase * 56),
          Offset(-53 + 46 * ulP, -30 + scanPhase * 56), p);
    }

    p.style = PaintingStyle.fill;
    canvas.restore();
  }

  void _drawNotepad(Canvas canvas, Paint p, Size sz, double cx) {
    final nx = cx + sz.width * 0.20;
    // Notepad sits on desk surface
    final ny = _ty - 8;

    p.color = const Color(0xFFFFF8E8);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(nx - 40, ny - 52, 78, 60), const Radius.circular(2)), p);

    // Spiral binding
    p..color = const Color(0xFF888878)
      ..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for (int i = 0; i < 8; i++) {
      canvas.drawArc(
          Rect.fromCenter(center: Offset(nx - 40, ny - 48 + i * 7.0), width: 6, height: 6),
          0, pi, false, p);
    }

    // Ruled lines
    p..color = const Color(0xFFCCBBAA).withOpacity(0.50)..strokeWidth = 0.7;
    for (int l = 0; l < 6; l++) {
      canvas.drawLine(Offset(nx - 34, ny - 44.0 + l * 8), Offset(nx + 34, ny - 44.0 + l * 8), p);
    }
    p.style = PaintingStyle.fill;

    // Writing lines (grow during note scenes)
    final isNoting = (t >= _S03 && t < _S04) ||
        (t >= _S07 && t < _S08) ||
        (t >= _S10 && t < _S11);
    final isUrgent = t >= _S07 && t < _S08;

    if (isNoting || t > _S03) {
      final lineFill = isNoting ? penPhase : 1.0;
      p..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      for (int l = 0; l < 5; l++) {
        final lp = ((lineFill * 5 - l) / 1.0).clamp(0.0, 1.0);
        if (lp <= 0) continue;
        final wob = isUrgent ? sin(l * 2.1 + penPhase * 10) * 1.0 : 0.0;
        p..color = const Color(0xFF222244).withOpacity(isUrgent ? 0.75 : 0.65)
          ..strokeWidth = isUrgent ? 1.0 : 1.2;
        canvas.drawLine(
            Offset(nx - 34, ny - 44.0 + l * 8),
            Offset(nx - 34 + (66 - l * 3) * lp, ny - 44.0 + l * 8 + wob), p);
      }

      // Red underline when urgent
      if (isUrgent) {
        final cp = s(_S07, _S07 + 0.08);
        p..color = const Color(0xFFDD2222).withOpacity(cp * 0.80)
          ..strokeWidth = 1.8;
        canvas.drawLine(Offset(nx - 34, ny - 30), Offset(nx - 34 + 60 * cp, ny - 30), p);
        canvas.drawLine(Offset(nx - 34, ny - 27), Offset(nx - 34 + 40 * cp, ny - 27), p);
      }
      p.style = PaintingStyle.fill;
    }

    // Sticky note (appears in notes 3)
    if (t >= _S10 + 0.03) {
      final sa = ((t - _S10 - 0.03) / 0.05).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(nx + 10, ny - 52 - (1 - sa) * 14);
      canvas.rotate(-0.08);
      p.color = const Color(0xFFFFEE88).withOpacity(sa);
      canvas.drawRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 42, 36), const Radius.circular(2)), p);
      p.color = const Color(0xFFEEDD66).withOpacity(sa * 0.8);
      canvas.drawPath(Path()
        ..moveTo(32, 0)..lineTo(42, 0)..lineTo(42, 10)..close(), p);
      if (sa > 0.5) {
        p..color = const Color(0xFFCC3322).withOpacity((sa - 0.5) * 2 * 0.65)
          ..style = PaintingStyle.stroke..strokeWidth = 0.9;
        for (int l = 0; l < 3; l++) {
          canvas.drawLine(Offset(4, 8.0 + l * 7), Offset(36, 8.0 + l * 7), p);
        }
        p.style = PaintingStyle.fill;
      }
      canvas.restore();
    }
  }

  void _drawCoffeeMug(Canvas canvas, Paint p, Size sz, double cx) {
    final mx = cx + sz.width * 0.34;
    // Mug on desk surface
    final my = _ty - 4;

    // Saucer
    p.color = const Color(0xFFDDD5C5);
    canvas.drawOval(Rect.fromCenter(center: Offset(mx, my + 14), width: 36, height: 9), p);

    // Cup
    p.shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFFF2EAD8), Color(0xFFD8CAB2)],
    ).createShader(Rect.fromLTWH(mx - 13, my, 26, 16));
    canvas.drawPath(Path()
      ..moveTo(mx - 12, my + 1)
      ..lineTo(mx - 10, my + 14)
      ..quadraticBezierTo(mx, my + 16, mx + 10, my + 14)
      ..lineTo(mx + 12, my + 1)
      ..close(), p);
    p.shader = null;

    // Rim
    p.color = const Color(0xFFEAE2D2);
    canvas.drawOval(Rect.fromCenter(center: Offset(mx, my + 2), width: 24, height: 5), p);
    p.color = const Color(0xFF3D2010).withOpacity(0.88);
    canvas.drawOval(Rect.fromCenter(center: Offset(mx, my + 3), width: 19, height: 4), p);
    p.color = const Color(0xFFC08040).withOpacity(0.55);
    canvas.drawOval(Rect.fromCenter(center: Offset(mx - 1, my + 3), width: 11, height: 2.5), p);

    // Handle
    p..color = const Color(0xFFD8CAB2)
      ..style = PaintingStyle.stroke..strokeWidth = 2.8..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCenter(center: Offset(mx + 13, my + 9), width: 11, height: 11),
        -pi / 3, pi * 1.4, false, p);
    p.style = PaintingStyle.fill;

    // Steam
    for (int i = 0; i < 2; i++) {
      final phase = (glow + i * 0.5) % 1.0;
      final sy = my - 4 - phase * 18;
      final sx = mx + sin(phase * pi * 2 + i) * 3;
      final a  = sin(phase * pi) * 0.28;
      if (a < 0.02) continue;
      p..color = Colors.white.withOpacity(a)
        ..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round;
      canvas.drawPath(Path()
        ..moveTo(sx, sy + 8)
        ..quadraticBezierTo(sx + 4, sy + 4, sx, sy), p);
      p.style = PaintingStyle.fill;
    }
  }

  void _drawDeskLamp(Canvas canvas, Paint p, Size sz, double cx) {
    // Lamp on right side of desk
    final lx = cx + sz.width * 0.36;
    final ly = _ty - 4;

    // Base
    p.color = const Color(0xFF1E2030);
    canvas.drawOval(Rect.fromCenter(center: Offset(lx, ly + 2), width: 24, height: 7), p);

    // Arm
    p..color = const Color(0xFF26263A)
      ..style = PaintingStyle.stroke..strokeWidth = 4.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(lx, ly), Offset(lx + 6, ly - 56), p);
    canvas.drawLine(Offset(lx + 6, ly - 56), Offset(lx - 6, ly - 80), p);
    p.style = PaintingStyle.fill;

    // Shade
    p.color = const Color(0xFFDDCC44);
    canvas.drawPath(Path()
      ..moveTo(lx - 20, ly - 80)
      ..lineTo(lx + 8,  ly - 80)
      ..lineTo(lx + 2,  ly - 64)
      ..lineTo(lx - 14, ly - 64)
      ..close(), p);

    // Cone glow
    p.color = const Color(0xFFFFEE88).withOpacity(0.08 + glow * 0.06);
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawPath(Path()
      ..moveTo(lx - 14, ly - 64)
      ..lineTo(lx + 2,  ly - 64)
      ..lineTo(lx + 26, ly + 2)
      ..lineTo(lx - 38, ly + 2)
      ..close(), p);
    p.maskFilter = null;
  }

  void _drawDonePile(Canvas canvas, Paint p, Size sz, double cx) {
    if (t < _S11) return;
    final doneP = s(_S11, 1.0).clamp(0.0, 1.0);

    final dx = cx - sz.width * 0.36;
    // Done pile ON the desk surface
    final dy = _ty - 4;

    for (int i = 2; i >= 0; i--) {
      final stagger = ((doneP - i * 0.2) / 0.6).clamp(0.0, 1.0);
      if (stagger <= 0) continue;

      final cols = [const Color(0xFF4488CC), const Color(0xFFCC4444), const Color(0xFF44AA66)];
      canvas.save();
      canvas.translate(dx + i * 4.0 - 4, dy - i * 4.0 - (1 - stagger) * 22);
      canvas.rotate(-0.06 + i * 0.04);
      p.color = cols[i].withOpacity(stagger);
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 66, height: 46),
          const Radius.circular(2)), p);
      canvas.restore();
    }

    // Checkmark
    if (doneP > 0.5) {
      final ca = ((doneP - 0.5) / 0.5).clamp(0.0, 1.0);
      p..color = const Color(0xFF44EE88).withOpacity(ca * 0.88)
        ..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round;
      canvas.drawPath(Path()
        ..moveTo(dx - 14, dy - 8)
        ..lineTo(dx - 4,  dy + 4)
        ..lineTo(dx + 14, dy - 16), p);
      p.style = PaintingStyle.fill;

      // "DONE" label
      p.color = const Color(0xFF44EE88).withOpacity(ca * 0.50);
      final textRect = Rect.fromCenter(
        center: Offset(dx, dy - 30),
        width: 44, height: 14,
      );
      p.style = PaintingStyle.fill;
      // simple rect placeholder for text
      p.color = const Color(0xFF0C2018).withOpacity(ca * 0.6);
      canvas.drawRRect(RRect.fromRectAndRadius(textRect, const Radius.circular(3)), p);
      p..color = const Color(0xFF44EE88).withOpacity(ca * 0.7)
        ..style = PaintingStyle.stroke..strokeWidth = 0.8;
      canvas.drawRRect(RRect.fromRectAndRadius(textRect, const Radius.circular(3)), p);
      p.style = PaintingStyle.fill;
    }
  }

  void _drawThoughtBubble(Canvas canvas, Paint p, Size sz, double cx) {
    if (t < _S06 || t >= _S07) return;
    final alpha = sin(s(_S06, _S07) * pi) * 0.75;
    if (alpha < 0.05) return;

    // Bubbles float up from head area
    final baseX = cx + 44;
    final baseY = sz.height * 0.28;

    for (int i = 0; i < 3; i++) {
      final phase = (thinkPhase + i * 0.33) % 1.0;
      final by = baseY - i * 14.0 - phase * 8;
      final r  = 3.5 + i * 1.5;
      p.color = Colors.white.withOpacity(alpha * sin(phase * pi) * (0.4 + i * 0.2));
      canvas.drawCircle(Offset(baseX + i * 5.0, by), r, p);
    }

    // Main thought cloud
    p.color = Colors.white.withOpacity(alpha * 0.14);
    canvas.drawOval(Rect.fromCenter(
        center: Offset(baseX + 20, baseY - 46), width: 50, height: 28), p);
    p..color = Colors.white.withOpacity(alpha * 0.35)
      ..style = PaintingStyle.stroke..strokeWidth = 1.0;
    canvas.drawOval(Rect.fromCenter(
        center: Offset(baseX + 20, baseY - 46), width: 50, height: 28), p);
    p.style = PaintingStyle.fill;

    // "?" inside cloud
    p.color = const Color(0xFFAABBCC).withOpacity(alpha * 0.60);
    canvas.drawCircle(Offset(baseX + 20, baseY - 46), 3, p);
  }

  @override
  bool shouldRepaint(covariant _FrDeskPropsPainter old) => true;
}