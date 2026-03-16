// lib/widgets/animations/cyber_file_delivery.dart
//
// ┌──────────────────────────────────────────────────────────────────────┐
// │  CyberFileDelivery  v2                                               │
// │                                                                      │
// │  Two modes:                                                          │
// │   • Auto mode  — plays once, calls onComplete, disappears           │
// │   • Loop mode  — loops at loopAtScene until controller.complete()   │
// │                  is called, then finishes and calls onComplete       │
// │                                                                      │
// │  Parameters:                                                         │
// │   • logoImage   — optional logo shown top-center                   │
// │   • chatText    — caption text override                             │
// │   • loopAtScene — 0..1 loop point (enables loop mode)              │
// │   • controller  — CyberFileDeliveryController                      │
// │                                                                      │
// │  Scenes:                                                             │
// │   0.00–0.12  Walk in from right carrying file stack                 │
// │   0.12–0.32  Present stack proudly                                  │
// │   0.32–0.52  Lean forward, set stack on desk with dust puff         │
// │   0.52–0.68  Bow + wink                                             │
// │   0.68–0.82  Side-profile turn                                      │
// │   0.82–1.00  Walk out right                                         │
// └──────────────────────────────────────────────────────────────────────┘

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import 'cyber_character.dart';

// ─── Controller ───────────────────────────────────────────────────────────────

class CyberFileDeliveryController {
  _CyberFileDeliveryState? _state;
  void _attach(_CyberFileDeliveryState s) => _state = s;
  void complete() => _state?._requestComplete();
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class CyberFileDelivery extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration duration;
  final double? loopAtScene;
  final CyberFileDeliveryController? controller;
  final ImageProvider? logoImage;
  final String? chatText;

  const CyberFileDelivery({
    super.key,
    this.onComplete,
    this.duration = const Duration(seconds: 6),
    this.loopAtScene,
    this.controller,
    this.logoImage,
    this.chatText,
  });

  bool get isLoopMode => loopAtScene != null;

  @override
  State<CyberFileDelivery> createState() => _CyberFileDeliveryState();
}

// ─── State ────────────────────────────────────────────────────────────────────

class _CyberFileDeliveryState extends State<CyberFileDelivery>
    with TickerProviderStateMixin {

  late final AnimationController _main;
  late final AnimationController _blink;
  late final AnimationController _float;
  late final AnimationController _glow;
  late final AnimationController _dust;
  late final AnimationController _walk;

  bool _completionRequested = false;

  // Scene boundaries
  static const double _sPresent  = 0.12;
  static const double _sSetDown  = 0.32;
  static const double _sBow      = 0.52;
  static const double _sTurn     = 0.68;
  static const double _sWalkOut  = 0.82;

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
    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
    _glow  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))
      ..repeat(reverse: true);
    _dust  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _walk  = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))
      ..repeat();

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

    if (!mounted) return;
    await _main.animateTo(1.0);
    if (mounted) widget.onComplete?.call();
  }

  void _startBlink() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 1800 + Random().nextInt(2400)));
      if (!mounted) break;
      await _blink.forward();
      await _blink.reverse();
    }
  }

  // Trigger dust puff when stack lands
  void _maybeFireDust() {
    if (_t >= _sSetDown - 0.01 && _t < _sSetDown + 0.04 && !_dust.isAnimating) {
      _dust.reset();
      _dust.forward();
    }
  }

  @override
  void dispose() {
    _main.dispose(); _blink.dispose(); _float.dispose();
    _glow.dispose(); _dust.dispose(); _walk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _maybeFireDust();

    return Scaffold(
      backgroundColor: const Color(0xFF060D18),
      body: AnimatedBuilder(
        animation: Listenable.merge([_main, _blink, _float, _glow, _dust, _walk]),
        builder: (ctx, _) {
          final size = MediaQuery.of(ctx).size;
          // Max desk width 520 px, centred
          final deskW    = size.width.clamp(0.0, 520.0);
          final deskOffX = (size.width - deskW) / 2;

          return Stack(children: [
            _buildBg(size),
            _buildCharacter(size),
            _buildDesk(size, deskW, deskOffX),
            _buildDeskPapers(size, deskW, deskOffX),
            _buildDust(size),
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
      CustomPaint(size: size, painter: _FdBgPainter(glow: _glow.value));

  // ── Desk ────────────────────────────────────────────────────────────────────

  Widget _buildDesk(Size size, double deskW, double offX) => Positioned(
    left: offX, top: 0, width: deskW, height: size.height,
    child: CustomPaint(painter: _FdDeskPainter(deskW: deskW, sh: size.height)),
  );

  // ── Papers that land on desk ─────────────────────────────────────────────────

  Widget _buildDeskPapers(Size size, double deskW, double offX) {
    // Only show after set-down
    if (_t < _sSetDown - 0.06) return const SizedBox.shrink();
    final landP = _e(_sSetDown - 0.06, _sSetDown + 0.08, c: Curves.easeOut);
    return Positioned(
      left: offX, top: 0, width: deskW, height: size.height,
      child: CustomPaint(
        painter: _FdPapersPainter(landP: landP, deskW: deskW, sh: size.height),
      ),
    );
  }

  // ── Dust puff ───────────────────────────────────────────────────────────────

  Widget _buildDust(Size size) {
    if (_dust.value <= 0) return const SizedBox.shrink();
    return CustomPaint(
      size: size,
      painter: _FdDustPainter(phase: _dust.value, size: size),
    );
  }

  // ── Logo ────────────────────────────────────────────────────────────────────

  Widget _buildLogo(Size size) => Positioned(
    top: size.height * 0.07,
    left: size.width / 2 - 44,
    child: Container(
      width: 88, height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: DecorationImage(image: widget.logoImage!, fit: BoxFit.contain),
        boxShadow: [BoxShadow(color: AppRawColors.cyan.withOpacity(0.18), blurRadius: 18)],
      ),
    ),
  );

  // ── Character ───────────────────────────────────────────────────────────────

  Widget _buildCharacter(Size size) {
    // X position — walk in from right, walk out to right
    final walkInP  = _e(0.0, _sPresent, c: Curves.easeOutCubic);
    final walkOutP = _t > _sWalkOut ? _e(_sWalkOut, 1.0, c: Curves.easeInCubic) : 0.0;

    double charX;
    if (_t < _sPresent) {
      charX = size.width * (1.10 - 0.52 * walkInP);
    } else if (_t > _sWalkOut) {
      charX = size.width * (0.58 + 0.55 * walkOutP);
    } else {
      charX = size.width * 0.58;
    }

    final carrying = _t < _sSetDown;
    final fadeOut  = _t > _sWalkOut ? (1.0 - walkOutP).clamp(0.0, 1.0) : 1.0;

    CyberPose pose;
    CyberExpr expr;
    if (_t < _sPresent) {
      pose = CyberPose.holdBothHands; expr = CyberExpr.happy;
    } else if (_t < _sSetDown) {
      pose = CyberPose.holdBothHands; expr = CyberExpr.satisfied;
    } else if (_t < _sBow) {
      pose = CyberPose.stand;         expr = CyberExpr.satisfied;
    } else if (_t < _sTurn) {
      pose = CyberPose.wave;          expr = CyberExpr.happy;
    } else {
      pose = CyberPose.wave;          expr = CyberExpr.happy;
    }

    return Positioned(
      left: charX - 170,
      top:  size.height * 0.24,
      child: Opacity(
        opacity: fadeOut,
        child: CustomPaint(
          size: const Size(340, 360),
          painter: CyberCharPainter(
            blink:         _blink.value,
            glow:          _glow.value,
            hairWave:      _float.value,
            pose:          pose,
            expr:          expr,
            carryingStack: carrying,
          ),
        ),
      ),
    );
  }

  // ── Caption ──────────────────────────────────────────────────────────────────

  Widget _buildCaption(Size size) {
    final text = widget.chatText ??
        (_t < _sPresent   ? '🚶 Dosyalarınızı getiriyorum!'
            : _t < _sSetDown   ? '📦 Buyrun, dosyalarınız!'
            : _t < _sBow       ? '✅ Teslim edildi~'
            : _t < _sTurn      ? '🙇 Rica ederim!'
            :                    '👋 İyi çalışmalar!');

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

class _FdBgPainter extends CustomPainter {
  final double glow;
  _FdBgPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint();

    // Wall
    p.shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF06101E), Color(0xFF0A1828)],
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
    p..color = const Color(0xFF1A2A40).withOpacity(0.7)
      ..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawLine(Offset(0, sz.height * 0.64), Offset(sz.width, sz.height * 0.64), p);
    p.style = PaintingStyle.fill;

    // Wall grid
    p..color = const Color(0xFF0C1C2E).withOpacity(0.40)
      ..style = PaintingStyle.stroke..strokeWidth = 0.5;
    for (double x = 0; x < sz.width; x += sz.width * 0.10) {
      canvas.drawLine(Offset(x, 0), Offset(x, sz.height * 0.64), p);
    }
    p.style = PaintingStyle.fill;

    // Door frame right
    final dx = sz.width * 0.84; final dy = sz.height * 0.14;
    final dw = sz.width * 0.14; final dh = sz.height * 0.50;
    p.color = AppRawColors.cyan.withOpacity(0.05 + glow * 0.03);
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawRect(Rect.fromLTWH(dx, dy, dw, dh), p);
    p.maskFilter = null;
    p..color = const Color(0xFF1E3050)..style = PaintingStyle.stroke..strokeWidth = 1.8;
    canvas.drawRect(Rect.fromLTWH(dx, dy, dw, dh), p);
    // door panel lines
    p..strokeWidth = 0.8..color = const Color(0xFF1A2A3C);
    canvas.drawRect(Rect.fromLTWH(dx + 5, dy + 5, dw - 10, dh * 0.44), p);
    canvas.drawRect(Rect.fromLTWH(dx + 5, dy + dh * 0.47, dw - 10, dh * 0.44), p);
    // door knob
    p.style = PaintingStyle.fill;
    p.color = AppRawColors.cyan.withOpacity(0.60 + glow * 0.25);
    canvas.drawCircle(Offset(dx + 7, dy + dh * 0.50), 3.5, p);
    p.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant _FdBgPainter old) => old.glow != glow;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESK PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _FdDeskPainter extends CustomPainter {
  final double deskW, sh;
  _FdDeskPainter({required this.deskW, required this.sh});

  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint()..isAntiAlias = true;
    final cx = sz.width / 2;
    final ty = sh * 0.63;
    final hw = sz.width * 0.43;

    // Surface
    p.shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF6B4422), Color(0xFF4A2E14)],
    ).createShader(Rect.fromLTWH(cx - hw, ty, hw * 2, 20));
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - hw, ty, hw * 2, 20), const Radius.circular(4)), p);
    p.shader = null;

    // Edge highlight
    p..color = const Color(0xFF9B6442).withOpacity(0.45)
      ..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawLine(Offset(cx - hw, ty), Offset(cx + hw, ty), p);
    p.style = PaintingStyle.fill;

    // Body
    p.color = const Color(0xFF3D2510);
    canvas.drawRect(Rect.fromLTWH(cx - hw + 18, ty + 20, (hw - 18) * 2, sh * 0.27), p);

    // Wood grain
    p..color = const Color(0xFF5A3818).withOpacity(0.22)
      ..style = PaintingStyle.stroke..strokeWidth = 0.6;
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
          Offset(cx - hw + 20, ty + 4 + i * 3.0),
          Offset(cx + hw - 20, ty + 4 + i * 2.8), p);
    }
    p.style = PaintingStyle.fill;

    // Legs
    p.color = const Color(0xFF2E1C0A);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - hw + 20, ty + 20, 14, sh * 0.30), const Radius.circular(3)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + hw - 34, ty + 20, 14, sh * 0.30), const Radius.circular(3)), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESK PAPERS PAINTER  (files landing on desk)
// ═══════════════════════════════════════════════════════════════════════════════

class _FdPapersPainter extends CustomPainter {
  final double landP, deskW, sh;
  _FdPapersPainter({required this.landP, required this.deskW, required this.sh});

  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint()..isAntiAlias = true;
    final cx = sz.width / 2;
    // Desk surface Y — papers sit ON TOP of the desk, not below
    final ty = sh * 0.61;

    // 5 items fan out as they land, stagger by index
    final items = [
      (cx - 18, ty - 2, -0.06, const Color(0xFF4488CC), true),   // blue folder
      (cx - 6,  ty - 5, -0.02, const Color(0xFFF0EBE0), false),  // paper
      (cx + 2,  ty - 8,  0.03, const Color(0xFFF5F0E8), false),  // paper
      (cx + 14, ty - 3,  0.07, const Color(0xFF44AA66), true),   // green folder
      (cx + 26, ty - 6,  0.10, const Color(0xFFF8F3E8), false),  // paper
    ];

    for (int i = 0; i < items.length; i++) {
      final stagger = ((landP - i * 0.12) / (1.0 - i * 0.12)).clamp(0.0, 1.0);
      if (stagger <= 0) continue;

      final (bx, by, rot, col, isFolder) = items[i];

      // Landing drop — items fall from above
      final dropY = by - (1 - stagger) * 35;

      canvas.save();
      canvas.translate(bx, dropY);
      canvas.rotate(rot * stagger);

      if (isFolder) {
        p.color = col;
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 70, height: 50),
            const Radius.circular(2)), p);
        p.color = col.withOpacity(0.75);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(-35, -28, 24, 8), const Radius.circular(2)), p);
        p..color = col.withOpacity(0.40)..style = PaintingStyle.stroke..strokeWidth = 0.8;
        for (int l = 0; l < 3; l++) {
          canvas.drawLine(Offset(-32.0, -12.0 + l * 9), Offset(30.0, -12.0 + l * 9), p);
        }
        p.style = PaintingStyle.fill;
      } else {
        p.color = col;
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 64, height: 48),
            const Radius.circular(2)), p);
        p..color = const Color(0xFF888070).withOpacity(0.28)
          ..style = PaintingStyle.stroke..strokeWidth = 0.8;
        for (int l = 0; l < 5; l++) {
          canvas.drawLine(Offset(-26.0, -18.0 + l * 8), Offset(26.0, -18.0 + l * 8), p);
        }
        p..color = const Color(0xFF333020).withOpacity(0.50)..strokeWidth = 2.0;
        canvas.drawLine(const Offset(-26, -22), const Offset(14, -22), p);
        p.style = PaintingStyle.fill;
      }
      canvas.restore();
    }

    // Sticky note
    if (landP > 0.65) {
      final a = ((landP - 0.65) / 0.35).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(cx + 5, ty - 4 - (1 - a) * 12);
      canvas.rotate(0.08 * a);
      p.color = const Color(0xFFFFEE88).withOpacity(a);
      canvas.drawRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 44, 38), const Radius.circular(2)), p);
      // fold corner
      p.color = const Color(0xFFEEDD66).withOpacity(a * 0.8);
      canvas.drawPath(Path()
        ..moveTo(34, 0)..lineTo(44, 0)..lineTo(44, 10)..close(), p);
      if (a > 0.5) {
        final la = (a - 0.5) * 2;
        p..color = const Color(0xFFCC4433).withOpacity(la * 0.6)
          ..style = PaintingStyle.stroke..strokeWidth = 0.9;
        for (int l = 0; l < 4; l++) {
          canvas.drawLine(Offset(5, 7.0 + l * 7), Offset(38, 7.0 + l * 7), p);
        }
        p.style = PaintingStyle.fill;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FdPapersPainter old) => old.landP != landP;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DUST PUFF PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _FdDustPainter extends CustomPainter {
  final double phase;
  final Size size;
  _FdDustPainter({required this.phase, required this.size});

  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint()..isAntiAlias = true;
    final cx = sz.width / 2 - 10;
    final cy = size.height * 0.62;
    final rng = Random(7);

    for (int i = 0; i < 16; i++) {
      final angle  = rng.nextDouble() * 2 * pi;
      final speed  = 0.5 + rng.nextDouble() * 0.5;
      final dist   = phase * speed * 36;
      final radius = (1.2 + rng.nextDouble() * 2.2) * (1 - phase);
      final alpha  = sin(phase * pi) * 0.32 * (rng.nextDouble() * 0.5 + 0.5);
      if (alpha < 0.01) continue;
      p.color = Color.fromRGBO(200, 185, 150, alpha);
      canvas.drawCircle(
          Offset(cx + cos(angle) * dist, cy + sin(angle) * dist * 0.5),
          radius.clamp(0.1, 10.0), p);
    }
  }

  @override
  bool shouldRepaint(covariant _FdDustPainter old) => old.phase != phase;
}