// lib/widgets/animations/cyber_busy_work.dart
//
// ┌──────────────────────────────────────────────────────────────────────┐
// │  CyberBusyWork                                                       │
// │                                                                      │
// │  Seamless looping loading screen — waifu intensely working at desk. │
// │  Uses CyberCharPainter for consistent style with all other widgets. │
// │                                                                      │
// │  final ctrl = CyberBusyWorkController();
// │
// │showGeneralDialog(
// │  context: context,
// │  barrierDismissible: false,
// │  barrierColor: Colors.black54,
// │  pageBuilder: (_, __, ___) => CyberBusyWork(
// │    statusText: 'Veriler işleniyor...',
// │    controller: ctrl,
// │    onComplete: () => Navigator.of(context).pop(),
// │  ),
// │);
// │
// │// When your work is done:                                            │
// │await doYourWork();                                                   │
// │ctrl.complete(); // → triggers onComplete → pops the dialog           │
// └──────────────────────────────────────────────────────────────────────┘


import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import 'cyber_character.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PUBLIC WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Controller ───────────────────────────────────────────────────────────────

class CyberBusyWorkController {
  _CyberBusyWorkState? _state;
  void _attach(_CyberBusyWorkState s) => _state = s;
  /// Call when background work finishes — widget calls onComplete.
  void complete() => _state?._requestComplete();
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class CyberBusyWork extends StatefulWidget {
  final String statusText;
  final VoidCallback? onComplete;
  final CyberBusyWorkController? controller;

  const CyberBusyWork({
    super.key,
    this.statusText = 'İşleniyor...',
    this.onComplete,
    this.controller,
  });

  @override
  State<CyberBusyWork> createState() => _CyberBusyWorkState();
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════════════════════

class _CyberBusyWorkState extends State<CyberBusyWork>
    with TickerProviderStateMixin {

  // ── Looping controllers ────────────────────────────────────────────────────
  late final AnimationController _blink;       // eye blink
  late final AnimationController _glow;        // cyan glow pulse  (1.9 s)
  late final AnimationController _penCycle;    // pen action cycle (4.8 s)
  late final AnimationController _eyeScan;     // eye scan L↔R    (0.9 s)
  late final AnimationController _leanCycle;   // lean in/back     (6.8 s)
  late final AnimationController _headBob;     // head bob         (2.1 s)
  late final AnimationController _coffeeGrab;  // coffee sip       (9.0 s)
  late final AnimationController _paperRustle; // paper shuffle    (3.6 s)
  late final AnimationController _sweatDrop;   // stress bead      (2.2 s)
  late final AnimationController _shimmer;     // status bar shimmer (1.6 s)

  // ── One-shot triggered controllers ────────────────────────────────────────
  late final AnimationController _glassesPush; // glasses nudge    (0.38 s)
  late final AnimationController _pageFlip;    // page turn        (0.48 s)
  late final AnimationController _hairTuck;    // hair tuck        (0.5 s)
  late final AnimationController _underline;   // urgent underline (0.35 s)
  late final AnimationController _stickySlap;  // sticky note slap (0.55 s)

  final _rng = Random();
  bool _glassesActive = false;
  bool _pageActive    = false;
  bool _hairActive    = false;
  bool _underActive   = false;
  bool _stickyActive  = false;

  @override
  void initState() {
    super.initState();

    // Looping
    _blink       = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _glow        = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..repeat(reverse: true);
    _penCycle    = AnimationController(vsync: this, duration: const Duration(milliseconds: 4800))..repeat();
    _eyeScan     = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _leanCycle   = AnimationController(vsync: this, duration: const Duration(milliseconds: 6800))..repeat(reverse: true);
    _headBob     = AnimationController(vsync: this, duration: const Duration(milliseconds: 2100))..repeat(reverse: true);
    _coffeeGrab  = AnimationController(vsync: this, duration: const Duration(milliseconds: 9000))..repeat();
    _paperRustle = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();
    _sweatDrop   = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    _shimmer     = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

    // One-shot
    _glassesPush = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _pageFlip    = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _hairTuck    = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _underline   = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _stickySlap  = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));

    _startBlinkLoop();
    _startRandomTriggers();
    widget.controller?._attach(this);
  }

  void _requestComplete() {
    if (!mounted) return;
    widget.onComplete?.call();
  }

  void _startBlinkLoop() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 2200 + _rng.nextInt(2400)));
      if (!mounted) break;
      await _blink.forward();
      await _blink.reverse();
    }
  }

  void _startRandomTriggers() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 800 + _rng.nextInt(1600)));
      if (!mounted) break;
      final roll = _rng.nextInt(5);
      switch (roll) {
        case 0:
          if (!_glassesActive) {
            _glassesActive = true;
            await _glassesPush.forward();
            await _glassesPush.reverse();
            _glassesActive = false;
          }
          break;
        case 1:
          if (!_pageActive) {
            _pageActive = true;
            await _pageFlip.forward();
            await _pageFlip.reverse();
            _pageActive = false;
          }
          break;
        case 2:
          if (!_hairActive) {
            _hairActive = true;
            await _hairTuck.forward();
            await _hairTuck.reverse();
            _hairActive = false;
          }
          break;
        case 3:
          if (!_underActive) {
            _underActive = true;
            await _underline.forward();
            _underline.reset();
            _underActive = false;
          }
          break;
        case 4:
          if (!_stickyActive) {
            _stickyActive = true;
            await _stickySlap.forward();
            _stickyActive = false;
          }
          break;
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _blink, _glow, _penCycle, _eyeScan, _leanCycle, _headBob,
      _coffeeGrab, _paperRustle, _sweatDrop, _shimmer,
      _glassesPush, _pageFlip, _hairTuck, _underline, _stickySlap,
    ]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D18),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _blink, _glow, _penCycle, _eyeScan, _leanCycle, _headBob,
          _coffeeGrab, _paperRustle, _sweatDrop, _shimmer,
          _glassesPush, _pageFlip, _hairTuck, _underline, _stickySlap,
        ]),
        builder: (ctx, _) {
          final size = MediaQuery.of(ctx).size;
          final deskW    = size.width.clamp(0.0, 520.0);
          final deskOffX = (size.width - deskW) / 2;

          // Derive pose/expr from penCycle phase
          final phase = _penCycle.value;
          CyberPose pose;
          CyberExpr expr;
          if (phase < 0.30) {
            pose = CyberPose.writeRight;  expr = CyberExpr.focused;
          } else if (phase < 0.48) {
            pose = CyberPose.writeUrgent; expr = CyberExpr.focused;
          } else if (phase < 0.62) {
            pose = CyberPose.penTap;      expr = CyberExpr.curious;
          } else if (phase < 0.80) {
            pose = CyberPose.writeRight;  expr = CyberExpr.focused;
          } else {
            pose = _coffeeGrab.value > 0.4 && _coffeeGrab.value < 0.7
                ? CyberPose.sip
                : CyberPose.writeRight;
            expr = CyberExpr.neutral;
          }

          // Pen wobble
          final penWob = (pose == CyberPose.writeUrgent)
              ? sin(_penCycle.value * pi * 28) * 0.5
              : 0.0;

          // Glasses push
          final glassesP = _glassesPush.value * 3.2;

          // Hair tuck
          final hairTuckV = _hairTuck.value;

          final charCx = size.width * 0.62;

          return Stack(children: [
            _buildRoom(size),
            // Character drawn FIRST — desk renders in front
            Positioned(
              left: charCx - 170,
              top: size.height * 0.24,
              child: CustomPaint(
                size: const Size(340, 360),
                painter: CyberCharPainter(
                  blink:       _blink.value,
                  glow:        _glow.value,
                  hairWave:    0.5,
                  penWobble:   penWob,
                  eyeScan:     _eyeScan.value,
                  glassesPush: glassesP,
                  hairTuck:    hairTuckV,
                  pose:        pose,
                  expr:        expr,
                  isReading:   phase > 0.60 && phase < 0.80,
                ),
              ),
            ),
            _buildDesk(size, deskW, deskOffX),
            _buildDeskProps(size, deskW, deskOffX),
            _buildStatusBar(size),
          ]);
        },
      ),
    );
  }

  // ── Room ────────────────────────────────────────────────────────────────────

  Widget _buildRoom(Size size) =>
      CustomPaint(size: size, painter: _BwRoomPainter(glow: _glow.value));

  // ── Desk shell ──────────────────────────────────────────────────────────────

  Widget _buildDesk(Size size, double deskW, double offX) => Positioned(
    left: offX, top: 0, width: deskW, height: size.height,
    child: CustomPaint(painter: _BwDeskPainter(sh: size.height)),
  );

  // ── Desk props (animated files, notepad, coffee) ─────────────────────────────

  Widget _buildDeskProps(Size size, double deskW, double offX) => Positioned(
    left: offX, top: 0, width: deskW, height: size.height,
    child: CustomPaint(
      painter: _BwDeskPropsPainter(
        penPhase:     _penCycle.value,
        paperPhase:   _paperRustle.value,
        pagePhase:    _pageFlip.value,
        coffeePhase:  _coffeeGrab.value,
        underlineP:   _underline.value,
        stickyP:      _stickySlap.value,
        sweatP:       _sweatDrop.value,
        glow:         _glow.value,
        sh:           size.height,
      ),
    ),
  );

  // ── Status bar ───────────────────────────────────────────────────────────────

  Widget _buildStatusBar(Size size) {
    return Positioned(
      bottom: 32, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF080F1C).withOpacity(0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppRawColors.cyan.withOpacity(0.28), width: 1),
            boxShadow: [BoxShadow(color: AppRawColors.cyan.withOpacity(0.08), blurRadius: 16)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing dot
              AnimatedBuilder(
                animation: _glow,
                builder: (_, __) => Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppRawColors.cyan.withOpacity(0.55 + _glow.value * 0.40),
                    boxShadow: [BoxShadow(
                      color: AppRawColors.cyan.withOpacity(0.40 + _glow.value * 0.35),
                      blurRadius: 8,
                    )],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.statusText,
                style: const TextStyle(
                  color: Color(0xFFCCDDEE), fontSize: 14,
                  letterSpacing: 0.5, fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              // Animated ellipsis
              AnimatedBuilder(
                animation: _shimmer,
                builder: (_, __) {
                  final dots = ['   ', '.  ', '.. ', '...'];
                  final idx  = (_shimmer.value * 4).floor().clamp(0, 3);
                  return Text(dots[idx], style: TextStyle(
                    color: AppRawColors.cyan.withOpacity(0.75),
                    fontSize: 14, fontWeight: FontWeight.w700,
                  ));
                },
              ),
              const SizedBox(width: 14),
              // Shimmer bar
              SizedBox(
                width: 80, height: 3,
                child: AnimatedBuilder(
                  animation: _shimmer,
                  builder: (_, __) => Stack(children: [
                    Container(decoration: BoxDecoration(
                      color: AppRawColors.cyan.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(2),
                    )),
                    FractionallySizedBox(
                      widthFactor: (0.3 + _shimmer.value * 0.7).clamp(0.0, 1.0),
                      child: Container(decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppRawColors.cyan.withOpacity(0.70),
                          AppRawColors.cyan.withOpacity(0.20),
                        ]),
                        borderRadius: BorderRadius.circular(2),
                      )),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ROOM PAINTER  (bookshelf, window, clock, ambient glow)
// ═══════════════════════════════════════════════════════════════════════════════

class _BwRoomPainter extends CustomPainter {
  final double glow;
  _BwRoomPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint()..isAntiAlias = true;

    // Wall gradient
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

    // Wall vertical lines
    p..color = const Color(0xFF0C1C2E).withOpacity(0.35)
      ..style = PaintingStyle.stroke..strokeWidth = 0.5;
    for (double x = 0; x < sz.width; x += sz.width * 0.10) {
      canvas.drawLine(Offset(x, 0), Offset(x, sz.height * 0.64), p);
    }
    p.style = PaintingStyle.fill;

    // ── Bookshelf (left) ─────────────────────────────────────────────────────
    final bsx = sz.width * 0.03;
    final bsy = sz.height * 0.09;
    final bsw = sz.width * 0.11;
    final bsh = sz.height * 0.51;
    p.color = const Color(0xFF261508);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(bsx, bsy, bsw, bsh), const Radius.circular(2)), p);
    p.color = const Color(0xFF3A2010);
    for (int i = 0; i <= 3; i++) {
      canvas.drawRect(Rect.fromLTWH(bsx, bsy + i * bsh / 3, bsw, 4), p);
    }
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
        final bw = 6.5 + (bi % 3) * 3.0;
        p.color = bookCols[bi % bookCols.length];
        canvas.drawRect(Rect.fromLTWH(bx, ry, bw, bsh / 3 - 8), p);
        bx += bw + 1.5;
        bi++;
      }
    }

    // ── Window (top-center) ──────────────────────────────────────────────────
    final wx = sz.width * 0.36; final wy = sz.height * 0.07;
    final ww = sz.width * 0.28; final wh = sz.height * 0.25;
    p.color = const Color(0xFFAADDFF).withOpacity(0.03 + glow * 0.02);
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRect(Rect.fromLTWH(wx, wy, ww, wh), p);
    p.maskFilter = null;
    p..color = const Color(0xFF1E3050)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawRect(Rect.fromLTWH(wx, wy, ww, wh), p);
    canvas.drawLine(Offset(wx + ww / 2, wy), Offset(wx + ww / 2, wy + wh), p);
    canvas.drawLine(Offset(wx, wy + wh / 2), Offset(wx + ww, wy + wh / 2), p);
    p.style = PaintingStyle.fill;
    // Curtains
    p.color = const Color(0xFF0E2040).withOpacity(0.55);
    canvas.drawPath(Path()
      ..moveTo(wx, wy)..lineTo(wx + ww * 0.18, wy)..lineTo(wx + ww * 0.12, wy + wh)..lineTo(wx, wy + wh)..close(), p);
    canvas.drawPath(Path()
      ..moveTo(wx + ww, wy)..lineTo(wx + ww - ww * 0.18, wy)..lineTo(wx + ww - ww * 0.12, wy + wh)..lineTo(wx + ww, wy + wh)..close(), p);

    // ── Clock (top-right) ────────────────────────────────────────────────────
    final clx = sz.width * 0.88; final cly = sz.height * 0.11;
    p.color = const Color(0xFF1A2A3E);
    canvas.drawCircle(Offset(clx, cly), 18, p);
    p..color = const Color(0xFF2A3A52)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawCircle(Offset(clx, cly), 18, p);
    for (int i = 0; i < 12; i++) {
      final angle = i * pi / 6;
      final r1 = i % 3 == 0 ? 12.0 : 14.5;
      p..color = const Color(0xFF6688AA)..strokeWidth = i % 3 == 0 ? 1.5 : 0.8;
      canvas.drawLine(
          Offset(clx + cos(angle) * r1, cly + sin(angle) * r1),
          Offset(clx + cos(angle) * 16, cly + sin(angle) * 16), p);
    }
    p..color = const Color(0xFFCCDDEE)..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(clx, cly), Offset(clx + cos(-pi / 2) * 10, cly + sin(-pi / 2) * 10), p);
    p..color = AppRawColors.cyan.withOpacity(0.8)..strokeWidth = 1.2;
    canvas.drawLine(Offset(clx, cly), Offset(clx + cos(pi / 4) * 13, cly + sin(pi / 4) * 13), p);
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFFCCDDEE);
    canvas.drawCircle(Offset(clx, cly), 2, p);

    // ── Stress glow around character ─────────────────────────────────────────
    p.color = AppRawColors.cyan.withOpacity(0.020 + glow * 0.012);
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(Offset(sz.width * 0.62, sz.height * 0.40), 110, p);
    p.maskFilter = null;
  }

  @override
  bool shouldRepaint(covariant _BwRoomPainter old) => old.glow != glow;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESK SHELL PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _BwDeskPainter extends CustomPainter {
  final double sh;
  _BwDeskPainter({required this.sh});

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

    // Wood grain
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
// DESK PROPS PAINTER  (open file, notepad, coffee, clutter, sticky)
// ═══════════════════════════════════════════════════════════════════════════════

class _BwDeskPropsPainter extends CustomPainter {
  final double penPhase, paperPhase, pagePhase, coffeePhase;
  final double underlineP, stickyP, sweatP, glow, sh;

  _BwDeskPropsPainter({
    required this.penPhase, required this.paperPhase,
    required this.pagePhase, required this.coffeePhase,
    required this.underlineP, required this.stickyP,
    required this.sweatP, required this.glow, required this.sh,
  });

  double get _ty => sh * 0.60;

  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint()..isAntiAlias = true;
    final cx = sz.width / 2;

    _drawInboxClutter(canvas, p, sz, cx);
    _drawOpenFile(canvas, p, sz, cx);
    _drawNotepad(canvas, p, sz, cx);
    _drawCoffeeMug(canvas, p, sz, cx);
    _drawDeskLamp(canvas, p, sz, cx);
    _drawStickyNote(canvas, p, sz, cx);
    // _drawSweatDrop(canvas, p, sz, cx);
  }

  void _drawInboxClutter(Canvas canvas, Paint p, Size sz, double cx) {
    final ix = cx - sz.width * 0.30;
    final iy = _ty - 6;
    // Random scattered papers
    final rng = Random(42);
    final cols = [
      const Color(0xFF4488CC), const Color(0xFFCC4444), const Color(0xFF44AA66),
      const Color(0xFFF5F0E6), const Color(0xFFF2EDD8),
    ];
    for (int i = 4; i >= 0; i--) {
      canvas.save();
      canvas.translate(ix + i * 4.0, iy - i * 3.0);
      canvas.rotate(-0.08 + i * 0.04 + rng.nextDouble() * 0.06);
      p.color = cols[i % cols.length];
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 62, height: 44),
          const Radius.circular(2)), p);
      if (i < 3) {
        p..color = cols[i].withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 0.7;
        for (int l = 0; l < 3; l++) {
          canvas.drawLine(Offset(-25.0, -12.0 + l * 8), Offset(25.0, -12.0 + l * 8), p);
        }
        p.style = PaintingStyle.fill;
      }
      canvas.restore();
    }
    // Tray
    p.color = const Color(0xFF1A2A3E).withOpacity(0.70);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(ix - 36, iy + 8, 72, 8), const Radius.circular(2)), p);
  }

  void _drawOpenFile(Canvas canvas, Paint p, Size sz, double cx) {
    final fx = cx - 14;
    final fy = _ty - 16;

    // Determine file colour from pen cycle phase
    final col = penPhase < 0.45
        ? const Color(0xFF4488CC)
        : penPhase < 0.75
        ? const Color(0xFFCC4444)
        : const Color(0xFF44AA66);

    // Folder base
    p.color = col;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(fx, fy), width: 120, height: 84),
        const Radius.circular(3)), p);

    // Left page
    p.color = const Color(0xFFF5F0E6);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(fx - 58, fy - 40, 56, 78), const Radius.circular(2)), p);

    // Right page — flips with pagePhase
    canvas.save();
    canvas.translate(fx + 2, fy);
    canvas.scale(1.0 - sin(pagePhase * pi) * 0.85, 1.0);
    p.color = const Color(0xFFF8F4EA);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -40, 57, 78), const Radius.circular(2)), p);
    canvas.restore();

    // Scan highlight strip
    final scanY = fy - 32 + (penPhase * 60) % 60;
    p.color = const Color(0xFFFFFF55).withOpacity(0.14);
    canvas.drawRect(Rect.fromLTWH(fx - 57, scanY - 4, 55, 9), p);

    // Text lines left page
    p..color = const Color(0xFF505040).withOpacity(0.42)
      ..style = PaintingStyle.stroke..strokeWidth = 0.85;
    for (int l = 0; l < 8; l++) {
      final w = 44.0 - (l % 4) * 4;
      canvas.drawLine(Offset(fx - 54, fy - 34.0 + l * 9), Offset(fx - 54 + w, fy - 34.0 + l * 9), p);
    }
    // Urgent underline sweep
    if (underlineP > 0) {
      p..color = const Color(0xFFDD2222).withOpacity(underlineP * 0.85)
        ..strokeWidth = 2.2..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(fx - 54, fy - 16),
          Offset(fx - 54 + 48 * underlineP, fy - 16), p);
    }
    p.style = PaintingStyle.fill;
  }

  void _drawNotepad(Canvas canvas, Paint p, Size sz, double cx) {
    final nx = cx + sz.width * 0.18;
    final ny = _ty - 10;

    p.color = const Color(0xFFFFF8E8);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(nx - 40, ny - 56, 80, 62), const Radius.circular(2)), p);

    // Spiral
    p..color = const Color(0xFF888878)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for (int i = 0; i < 8; i++) {
      canvas.drawArc(
          Rect.fromCenter(center: Offset(nx - 40, ny - 52 + i * 7.0), width: 6, height: 6),
          0, pi, false, p);
    }

    // Ruled lines
    p..color = const Color(0xFFCCBBAA).withOpacity(0.45)..strokeWidth = 0.7;
    for (int l = 0; l < 7; l++) {
      canvas.drawLine(Offset(nx - 34, ny - 48.0 + l * 8), Offset(nx + 36, ny - 48.0 + l * 8), p);
    }
    p.style = PaintingStyle.fill;

    // Writing lines grow/animate with pen phase
    final isUrgent = penPhase > 0.30 && penPhase < 0.48;
    p..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (int l = 0; l < 6; l++) {
      final lp = ((penPhase * 6 - l) / 1.0).clamp(0.0, 1.0);
      if (lp <= 0) continue;
      final wob = isUrgent ? sin(l * 2.1 + penPhase * 30) * 0.8 : 0.0;
      p..color = const Color(0xFF222244).withOpacity(isUrgent ? 0.72 : 0.62)
        ..strokeWidth = isUrgent ? 1.0 : 1.2;
      canvas.drawLine(
          Offset(nx - 34, ny - 48.0 + l * 8),
          Offset(nx - 34 + (66 - l * 3) * lp, ny - 48.0 + l * 8 + wob), p);
    }
    // Red underline when urgent
    if (isUrgent) {
      p..color = const Color(0xFFDD2222).withOpacity(0.75)..strokeWidth = 1.8;
      canvas.drawLine(Offset(nx - 34, ny - 24), Offset(nx + 28, ny - 24), p);
    }
    p.style = PaintingStyle.fill;
  }

  void _drawCoffeeMug(Canvas canvas, Paint p, Size sz, double cx) {
    final mx = cx + sz.width * 0.34;
    final my = _ty - 4;

    p.color = const Color(0xFFDDD5C5);
    canvas.drawOval(Rect.fromCenter(center: Offset(mx, my + 14), width: 36, height: 9), p);

    p.shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFFF2EAD8), Color(0xFFD8CAB2)],
    ).createShader(Rect.fromLTWH(mx - 13, my, 26, 18));
    canvas.drawPath(Path()
      ..moveTo(mx - 12, my + 1)
      ..lineTo(mx - 10, my + 15)
      ..quadraticBezierTo(mx, my + 17, mx + 10, my + 15)
      ..lineTo(mx + 12, my + 1)
      ..close(), p);
    p.shader = null;

    p.color = const Color(0xFFEAE2D2);
    canvas.drawOval(Rect.fromCenter(center: Offset(mx, my + 2), width: 24, height: 5), p);
    p.color = const Color(0xFF3D2010).withOpacity(0.88);
    canvas.drawOval(Rect.fromCenter(center: Offset(mx, my + 3), width: 20, height: 4.5), p);
    p.color = const Color(0xFFC08040).withOpacity(0.55);
    canvas.drawOval(Rect.fromCenter(center: Offset(mx - 1, my + 3), width: 12, height: 3), p);

    p..color = const Color(0xFFD8CAB2)
      ..style = PaintingStyle.stroke..strokeWidth = 2.8..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCenter(center: Offset(mx + 13, my + 9), width: 11, height: 11),
        -pi / 3, pi * 1.4, false, p);
    p.style = PaintingStyle.fill;

    // Steam wisps
    for (int i = 0; i < 3; i++) {
      final phase = (glow + i * 0.33) % 1.0;
      final sy = my - 4 - phase * 20;
      final sx = mx + sin(phase * pi * 2 + i) * 3.5;
      final a  = sin(phase * pi) * 0.32;
      if (a < 0.02) continue;
      p..color = Colors.white.withOpacity(a)
        ..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round;
      canvas.drawPath(Path()
        ..moveTo(sx, sy + 10)..quadraticBezierTo(sx + 4, sy + 5, sx, sy), p);
      p.style = PaintingStyle.fill;
    }
  }

  void _drawDeskLamp(Canvas canvas, Paint p, Size sz, double cx) {
    final lx = cx + sz.width * 0.38;
    final ly = _ty - 4;

    p.color = const Color(0xFF1E2030);
    canvas.drawOval(Rect.fromCenter(center: Offset(lx, ly + 2), width: 22, height: 6), p);
    p..color = const Color(0xFF26263A)..style = PaintingStyle.stroke..strokeWidth = 4.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(lx, ly), Offset(lx + 5, ly - 52), p);
    canvas.drawLine(Offset(lx + 5, ly - 52), Offset(lx - 5, ly - 74), p);
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFFDDCC44);
    canvas.drawPath(Path()
      ..moveTo(lx - 18, ly - 74)
      ..lineTo(lx + 8,  ly - 74)
      ..lineTo(lx + 2,  ly - 60)
      ..lineTo(lx - 12, ly - 60)
      ..close(), p);
    p.color = const Color(0xFFFFEE88).withOpacity(0.07 + glow * 0.05);
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawPath(Path()
      ..moveTo(lx - 12, ly - 60)
      ..lineTo(lx + 2,  ly - 60)
      ..lineTo(lx + 28, ly + 2)
      ..lineTo(lx - 38, ly + 2)
      ..close(), p);
    p.maskFilter = null;
  }

  void _drawStickyNote(Canvas canvas, Paint p, Size sz, double cx) {
    if (stickyP <= 0) return;
    final sa  = stickyP.clamp(0.0, 1.0);
    final snx = cx - sz.width * 0.20;
    final sny = _ty - 56 - (1 - sa) * 18;

    canvas.save();
    canvas.translate(snx, sny);
    canvas.rotate(-0.10 * sa);

    p.color = const Color(0xFFFFEE88).withOpacity(sa);
    canvas.drawRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 46, 40), const Radius.circular(2)), p);
    p.color = const Color(0xFFEEDD66).withOpacity(sa * 0.8);
    canvas.drawPath(Path()..moveTo(36, 0)..lineTo(46, 0)..lineTo(46, 10)..close(), p);

    if (sa > 0.45) {
      final la = ((sa - 0.45) / 0.55).clamp(0.0, 1.0);
      p..color = const Color(0xFFCC3322).withOpacity(la * 0.6)
        ..style = PaintingStyle.stroke..strokeWidth = 0.9;
      for (int l = 0; l < 4; l++) {
        canvas.drawLine(Offset(5, 8.0 + l * 7), Offset(40, 8.0 + l * 7), p);
      }
      p.style = PaintingStyle.fill;
    }
    canvas.restore();
  }

  void _drawSweatDrop(Canvas canvas, Paint p, Size sz, double cx) {
    // Stress sweat bead — rises from beside character head, fades out quickly
    final phase = sweatP;
    // Anchor near character head: just right of where the character stands (cx + ~80)
    // and vertically just above the desk surface
    final baseY = _ty - 110;
    final sy = baseY - phase * 22;
    final a  = sin(phase * pi) * 0.50;
    if (a < 0.04) return;
    p.color = const Color(0xFF88DDFF).withOpacity(a);
    canvas.drawPath(Path()
      ..moveTo(cx + 80, sy)
      ..quadraticBezierTo(cx + 84, sy + 7, cx + 80, sy + 12)
      ..quadraticBezierTo(cx + 76, sy + 7, cx + 80, sy), p);
  }

  @override
  bool shouldRepaint(covariant _BwDeskPropsPainter old) => true;
}
