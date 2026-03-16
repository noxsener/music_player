// lib/widgets/animations/cyber_character.dart
//
// ┌──────────────────────────────────────────────────────────────────────┐
// │  Shared WaifuCharacter CustomPainter                                 │
// │                                                                      │
// │  Draws the waifu in a hoodie outfit at correct proportions.         │
// │  Used by all waifu animation widgets.                                │
// │                                                                      │
// │  Proportions (matches cyber_ai_assistant.dart quality):             │
// │    0.00–0.16  hair top / crown                                       │
// │    0.14–0.65  face (jaw reaches height*0.65)                        │
// │    0.63–1.00  body / hoodie                                          │
// │                                                                      │
// │  Canvas size should be at least 160×340 for best results.           │
// └──────────────────────────────────────────────────────────────────────┘

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

// ─── Pose enum ────────────────────────────────────────────────────────────────
enum CyberPose {
  stand,          // upright, arms relaxed
  holdBothHands,  // both arms raised (carry stack)
  holdFileLeft,   // left arm raised holding file
  writeRight,     // right arm extends to write
  writeUrgent,    // right arm writes fast (wobble)
  penTap,         // right hand near chin/lip
  reach,          // right arm reaches to side
  bow,            // upper body leans forward
  wave,           // right arm raised in wave
  sip,            // left arm raised (coffee)
  stack,          // both arms move files
}

// ─── Expression enum ─────────────────────────────────────────────────────────
enum CyberExpr {
  neutral,
  happy,
  focused,
  curious,     // one brow up
  surprised,
  satisfied,
  tired,
}

// ═══════════════════════════════════════════════════════════════════════════════
// WAIFU CHARACTER PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class CyberCharPainter extends CustomPainter {
  // ── Required animation values ─────────────────────────────────────────────
  final double blink;       // 0..1 blink progress
  final double glow;        // 0..1 glow pulse
  final double hairWave;    // 0..1 hair wave
  final double penWobble;   // 0..1 pen/hand wobble
  final double eyeScan;     // 0..1 eye horizontal scan
  final double lean;        // lean angle in radians
  final double nodOffset;   // head nod Y offset in pixels
  final double glassesPush; // 0..3.5 glasses nudge up
  final double hairTuck;    // 0..1 hair tuck gesture

  // ── Pose / Expression ─────────────────────────────────────────────────────
  final CyberPose pose;
  final CyberExpr expr;
  final bool isReading;
  final bool isSideProfile; // for walk-away scenes
  final double sideProfileT; // 0..1 how much side profile

  // ── Optional extra paint data ─────────────────────────────────────────────
  final bool carryingStack;  // show file stack in hands

  const CyberCharPainter({
    required this.blink,
    required this.glow,
    this.hairWave    = 0.5,
    this.penWobble   = 0.0,
    this.eyeScan     = 0.5,
    this.lean        = 0.0,
    this.nodOffset   = 0.0,
    this.glassesPush = 0.0,
    this.hairTuck    = 0.0,
    this.pose        = CyberPose.stand,
    this.expr        = CyberExpr.neutral,
    this.isReading   = false,
    this.isSideProfile = false,
    this.sideProfileT  = 0.0,
    this.carryingStack = false,
  });

  // ── Derived colour ─────────────────────────────────────────────────────────
  Color get _accent => AppRawColors.cyan;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final cx = size.width / 2;

    // Walk-away: mirror horizontally — no squeeze/skew, just flip
    if (isSideProfile) {
      canvas.save();
      canvas.translate(cx, 0);
      canvas.scale(-1.0, 1.0);
      canvas.translate(-cx, 0);
    }

    _drawBackHair(canvas, p, size, cx);
    _drawBody(canvas, p, size, cx);
    _drawArms(canvas, p, size, cx);
    _drawLegs(canvas, p, size, cx);
    _drawFace(canvas, p, size, cx);
    _drawFrontHair(canvas, p, size, cx);

    if (isSideProfile) canvas.restore(); // mirror

    // Carried stack (always faces camera — drawn after mirror restore)
    if (carryingStack) _drawCarriedStack(canvas, p, size, cx);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BACK HAIR  (same technique as cyber_ai_assistant — long golden bob)
  // ════════════════════════════════════════════════════════════════════════════

  void _drawBackHair(Canvas canvas, Paint p, Size size, double cx) {
    final w = sin(hairWave * pi) * 5;

    // Dark shadow base
    p.color = const Color(0xFF1A0A00);
    canvas.drawPath(Path()
      ..moveTo(cx - 56, size.height * 0.14)
      ..cubicTo(cx - 88 + w * 0.5, size.height * 0.42,
          cx - 72 + w,       size.height * 0.82,
          cx - 28 + w * 0.4, size.height * 1.00)
      ..lineTo(cx + 28 - w * 0.4, size.height * 1.00)
      ..cubicTo(cx + 72 - w,       size.height * 0.82,
          cx + 88 - w * 0.5, size.height * 0.42,
          cx + 44,           size.height * 0.14)
      ..close(), p);

    // Golden main
    p.color = const Color(0xFFC8820A);
    canvas.drawPath(Path()
      ..moveTo(cx - 52, size.height * 0.14)
      ..cubicTo(cx - 82 + w * 0.4, size.height * 0.40,
          cx - 66 + w * 0.8, size.height * 0.80,
          cx - 24 + w * 0.3, size.height * 0.98)
      ..lineTo(cx + 24 - w * 0.3, size.height * 0.98)
      ..cubicTo(cx + 66 - w * 0.8, size.height * 0.80,
          cx + 82 - w * 0.4, size.height * 0.40,
          cx + 40,           size.height * 0.14)
      ..close(), p);

    // Highlight strand
    p..color = const Color(0xFFFFD060).withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()
      ..moveTo(cx - 28, size.height * 0.16)
      ..cubicTo(cx - 50 + w * 0.5, size.height * 0.42,
          cx - 38 + w * 0.8, size.height * 0.72,
          cx - 14,           size.height * 0.92), p);
    p.style = PaintingStyle.fill;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HOODIE BODY
  // ════════════════════════════════════════════════════════════════════════════

  void _drawBody(Canvas canvas, Paint p, Size size, double cx) {
    // ── Neck ──────────────────────────────────────────────────────────────────
    p.color = const Color(0xFFF5C99A);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, size.height * 0.695), width: 20, height: 26),
        const Radius.circular(5)), p);

    // ── Hoodie main body ──────────────────────────────────────────────────────
    // Dark navy hoodie
    const hoodieMain = Color(0xFF0E1D30);
    const hoodieRib  = Color(0xFF0A1622);
    const hoodieEdge = Color(0xFF162440);
    const hoodiePock = Color(0xFF0C1928);

    // Body silhouette — wider shoulder, tapers slightly to waist
    p.color = hoodieMain;
    canvas.drawPath(Path()
      ..moveTo(cx - 76, size.height)
      ..lineTo(cx - 62, size.height * 0.72)
      ..cubicTo(cx - 62, size.height * 0.72,
          cx - 46, size.height * 0.68,
          cx - 8,  size.height * 0.67)
      ..lineTo(cx + 8,  size.height * 0.67)
      ..cubicTo(cx + 46, size.height * 0.68,
          cx + 62, size.height * 0.72,
          cx + 62, size.height * 0.72)
      ..lineTo(cx + 76, size.height)
      ..close(), p);

    // ── Hood behind neck (hanging down) ───────────────────────────────────────
    // Hood back panel visible behind head, drapes down the back
    p.color = const Color(0xFF0C1A2C);
    canvas.drawPath(Path()
      ..moveTo(cx - 40, size.height * 0.68)
      ..cubicTo(cx - 52, size.height * 0.72,
          cx - 48, size.height * 0.80,
          cx - 36, size.height * 0.85)
      ..lineTo(cx + 36, size.height * 0.85)
      ..cubicTo(cx + 48, size.height * 0.80,
          cx + 52, size.height * 0.72,
          cx + 40, size.height * 0.68)
      ..close(), p);

    // Hood outer rim (visible from front — curved collar)
    p.color = hoodieEdge;
    canvas.drawPath(Path()
      ..moveTo(cx - 30, size.height * 0.67)
      ..cubicTo(cx - 22, size.height * 0.655,
          cx - 10, size.height * 0.650,
          cx,      size.height * 0.650)
      ..cubicTo(cx + 10, size.height * 0.650,
          cx + 22, size.height * 0.655,
          cx + 30, size.height * 0.67), p);
    p..color = hoodieEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()
      ..moveTo(cx - 30, size.height * 0.67)
      ..cubicTo(cx - 22, size.height * 0.655,
          cx - 10, size.height * 0.650,
          cx,      size.height * 0.650)
      ..cubicTo(cx + 10, size.height * 0.650,
          cx + 22, size.height * 0.655,
          cx + 30, size.height * 0.67), p);
    p.style = PaintingStyle.fill;

    // ── Hoodie strings (drawstrings) ──────────────────────────────────────────
    final strOff = sin(hairWave * pi) * 1.5; // slight sway
    p..color = const Color(0xFF1E3050)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    // left string
    canvas.drawPath(Path()
      ..moveTo(cx - 6, size.height * 0.655)
      ..quadraticBezierTo(cx - 10 + strOff, size.height * 0.72,
          cx - 8,  size.height * 0.78), p);
    // right string
    canvas.drawPath(Path()
      ..moveTo(cx + 6, size.height * 0.655)
      ..quadraticBezierTo(cx + 10 - strOff, size.height * 0.72,
          cx + 8,  size.height * 0.78), p);
    p.style = PaintingStyle.fill;
    // string tips (small cylinders)
    p.color = const Color(0xFF88AACC).withOpacity(0.75);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 8, size.height * 0.78 + 4), width: 4, height: 7),
        const Radius.circular(2)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 8, size.height * 0.78 + 4), width: 4, height: 7),
        const Radius.circular(2)), p);

    // ── Front zip / kangaroo pocket ───────────────────────────────────────────
    // Center zip line
    p..color = const Color(0xFF1A3050).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(cx, size.height * 0.68),
        Offset(cx, size.height * 0.88), p);

    // Zip pull tab
    p.style = PaintingStyle.fill;
    p.color = _accent.withOpacity(0.70 + glow * 0.20);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, size.height * 0.72), width: 6, height: 3),
        const Radius.circular(1.5)), p);

    // Kangaroo pocket outline
    p..color = hoodiePock
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final pocketRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 38, size.height * 0.80, 76, size.height * 0.12),
        const Radius.circular(6));
    p.style = PaintingStyle.fill;
    p.color = hoodiePock;
    canvas.drawRRect(pocketRect, p);
    p..color = hoodieEdge..style = PaintingStyle.stroke..strokeWidth = 1.0;
    canvas.drawRRect(pocketRect, p);
    // pocket center seam
    canvas.drawLine(Offset(cx, size.height * 0.80), Offset(cx, size.height * 0.92), p);
    p.style = PaintingStyle.fill;

    // ── Ribbed hem at bottom ──────────────────────────────────────────────────
    p.color = hoodieRib;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 56, size.height * 0.92, 112, size.height * 0.06),
        const Radius.circular(3)), p);
    p..color = hoodieEdge..style = PaintingStyle.stroke..strokeWidth = 0.7;
    for (int i = 1; i < 5; i++) {
      final ribY = size.height * 0.92 + i * size.height * 0.01;
      canvas.drawLine(Offset(cx - 44, ribY), Offset(cx + 44, ribY), p);
    }
    p.style = PaintingStyle.fill;

    // ── Cyan glow edge lines (tech accent) ────────────────────────────────────
    p..color = _accent.withOpacity(0.18 + glow * 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(cx - 28, size.height * 0.72), Offset(cx - 14, size.height * 0.82), p);
    canvas.drawLine(Offset(cx + 28, size.height * 0.72), Offset(cx + 14, size.height * 0.82), p);
    p.style = PaintingStyle.fill;

    // ── ID badge clipped to pocket ────────────────────────────────────────────
    final badge = Offset(cx + 24, size.height * 0.76);
    p.color = const Color(0xFFE8EEF8).withOpacity(0.88);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: badge, width: 18, height: 11), const Radius.circular(2)), p);
    p..color = _accent.withOpacity(0.55 + glow * 0.3)
      ..style = PaintingStyle.stroke..strokeWidth = 0.9;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: badge, width: 18, height: 11), const Radius.circular(2)), p);
    // badge text lines
    p..color = const Color(0xFF4488AA).withOpacity(0.6)..strokeWidth = 0.7;
    canvas.drawLine(badge.translate(-7, -2), badge.translate(2, -2), p);
    canvas.drawLine(badge.translate(-7,  1), badge.translate(4,  1), p);
    p.style = PaintingStyle.fill;
    // badge lanyard clip
    p.color = const Color(0xFF88AACC).withOpacity(0.55);
    canvas.drawRect(Rect.fromCenter(center: badge.translate(0, -7), width: 3, height: 4), p);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ARMS  (hoodie sleeves with ribbed cuffs)
  // ════════════════════════════════════════════════════════════════════════════

  void _drawArms(Canvas canvas, Paint p, Size size, double cx) {
    final shoulderY = size.height * 0.715;
    final armLen    = size.height * 0.23;
    const skin      = Color(0xFFF5C99A);
    const sleeve    = Color(0xFF0E1D30);
    const cuff      = Color(0xFF0A1622);

    // Derive arm angles from pose
    double lAngle, rAngle;
    switch (pose) {
      case CyberPose.stand:
        lAngle =  pi / 5.5; rAngle = -pi / 5.5;
        break;
      case CyberPose.holdBothHands:
        lAngle =  pi / 2.2; rAngle = -pi / 2.2;
        break;
      case CyberPose.holdFileLeft:
        lAngle =  pi / 2.2; rAngle = -pi / 5.5;
        break;
      case CyberPose.writeRight:
        lAngle = pi / 5;
        rAngle = -(pi / 3 + penWobble * 0.11);
        break;
      case CyberPose.writeUrgent:
        lAngle = pi / 5;
        rAngle = -(pi / 3.2 + penWobble * 0.18);
        break;
      case CyberPose.penTap:
        lAngle = pi / 5;
        rAngle = -(pi / 8);
        break;
      case CyberPose.reach:
        lAngle = pi / 5;
        rAngle = -(pi / 3.5);
        break;
      case CyberPose.bow:
        lAngle = pi / 4.5; rAngle = -pi / 4.5;
        break;
      case CyberPose.wave:
        lAngle = pi / 5;
        rAngle = -(pi / 4 + penWobble * 0.5);
        break;
      case CyberPose.sip:
        lAngle = pi / 2.1; rAngle = -pi / 5.5;
        break;
      case CyberPose.stack:
        lAngle =  pi / 3.2; rAngle = -pi / 3.2;
        break;
    }

    for (final side in [-1.0, 1.0]) {
      final angle = side < 0 ? lAngle : rAngle;
      final sx    = cx + side * 46;
      final ex    = sx + sin(angle) * armLen * side;
      final ey    = shoulderY + cos(angle) * armLen;

      // Sleeve (thick stroke)
      p..color = sleeve..style = PaintingStyle.stroke..strokeWidth = 16..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(sx, shoulderY), Offset(ex, ey), p);

      // Cuff ribbing at end of sleeve
      p.color = cuff; p.strokeWidth = 10;
      final cuffStart = 0.72;
      canvas.drawLine(
          Offset(sx + (ex - sx) * cuffStart, shoulderY + (ey - shoulderY) * cuffStart),
          Offset(ex, ey), p);

      // Cuff lines
      p..color = const Color(0xFF162440).withOpacity(0.6)..strokeWidth = 0.8;
      for (int r = 1; r <= 3; r++) {
        final t = cuffStart + r * (1.0 - cuffStart) / 4;
        final rx = sx + (ex - sx) * t;
        final ry = shoulderY + (ey - shoulderY) * t;
        // perpendicular cuff line
        final perpAngle = angle + pi / 2;
        canvas.drawLine(
            Offset(rx + cos(perpAngle) * 5, ry + sin(perpAngle) * 5),
            Offset(rx - cos(perpAngle) * 5, ry - sin(perpAngle) * 5), p);
      }

      // Skin forearm (peeking from cuff)
      p.color = skin; p.strokeWidth = 9;
      canvas.drawLine(
          Offset(sx + (ex - sx) * 0.88, shoulderY + (ey - shoulderY) * 0.88),
          Offset(ex, ey), p);

      // Hand
      p.style = PaintingStyle.fill;
      p.color = skin;
      canvas.drawCircle(Offset(ex, ey), 7.0, p);

      // Knuckle line
      p..color = const Color(0xFFE0A070).withOpacity(0.4)
        ..style = PaintingStyle.stroke..strokeWidth = 0.8;
      canvas.drawArc(Rect.fromCenter(center: Offset(ex, ey), width: 10, height: 10),
          angle - pi / 3, pi / 1.5, false, p);

      p.style = PaintingStyle.fill;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LEGS  (dark jogger/sweatpants + sneakers — or skirt for seated)
  // ════════════════════════════════════════════════════════════════════════════

  void _drawLegs(Canvas canvas, Paint p, Size size, double cx) {
    // Standing legs (jogger style matching hoodie)
    const pants  = Color(0xFF0E1D30);
    const cuff   = Color(0xFF0A1622);
    const shoe   = Color(0xFF0A0A18);
    const sole   = Color(0xFF1A1A2E);
    const lace   = Color(0xFF88AACC);

    // Left leg
    p.color = pants;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 32, size.height * 0.95, 26, size.height * 0.18),
        const Radius.circular(5)), p);
    // Right leg
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 6, size.height * 0.95, 26, size.height * 0.18),
        const Radius.circular(5)), p);

    // Ankle cuffs
    p.color = cuff;
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 33, size.height * 1.10, 28, size.height * 0.026),
        const Radius.circular(2)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 5,  size.height * 1.10, 28, size.height * 0.026),
        const Radius.circular(2)), p);

    // Sneakers
    for (final s in [-1.0, 1.0]) {
      final bx = cx + s * 19 - 17;
      final by = size.height * 1.12;

      // Sole
      p.color = sole;
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(bx - 2, by + 12, 38, 6), const Radius.circular(3)), p);

      // Upper
      p.color = shoe;
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, 34, 14), const Radius.circular(4)), p);

      // Toe cap
      p.color = const Color(0xFF141424);
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, 10, 14), const Radius.circular(4)), p);

      // Laces
      p..color = lace.withOpacity(0.55)
        ..style = PaintingStyle.stroke..strokeWidth = 0.8;
      for (int i = 0; i < 3; i++) {
        canvas.drawLine(
            Offset(bx + 12 + i * 4.0, by + 3),
            Offset(bx + 12 + i * 4.0, by + 10), p);
      }
      canvas.drawLine(Offset(bx + 12, by + 6), Offset(bx + 28, by + 6), p);
      p.style = PaintingStyle.fill;

      // Stripe detail
      p.color = _accent.withOpacity(0.18 + glow * 0.12);
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(bx + 2, by + 8, 28, 3), const Radius.circular(1)), p);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FACE  (same quality as cyber_ai_assistant — taller proportions)
  // ════════════════════════════════════════════════════════════════════════════

  void _drawFace(Canvas canvas, Paint p, Size size, double cx) {
    // Face occupies height * 0.18 → 0.65 (same as cyber_ai_assistant)
    final faceTop = size.height * 0.14;

    // Jaw shadow
    p.color = const Color(0xFFE0A070);
    canvas.drawPath(Path()
      ..moveTo(cx - 33, faceTop)
      ..quadraticBezierTo(cx - 36, faceTop + size.height * 0.37, cx, faceTop + size.height * 0.47)
      ..quadraticBezierTo(cx + 36, faceTop + size.height * 0.37, cx + 33, faceTop)
      ..close(), p);

    // Face base
    p.color = const Color(0xFFFAD0A0);
    canvas.drawPath(Path()
      ..moveTo(cx - 31, faceTop)
      ..quadraticBezierTo(cx - 34, faceTop + size.height * 0.34, cx, faceTop + size.height * 0.44)
      ..quadraticBezierTo(cx + 34, faceTop + size.height * 0.34, cx + 31, faceTop)
      ..close(), p);

    // Ears
    for (final side in [-1.0, 1.0]) {
      final earCy = faceTop + size.height * 0.20;
      p.color = const Color(0xFFF5C58A);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + side * 33, earCy), width: 9, height: 13), p);
      p.color = const Color(0xFFE8A070).withOpacity(0.6);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + side * 33, earCy), width: 5, height: 8), p);
    }

    // Blush
    final blushA = expr == CyberExpr.curious || expr == CyberExpr.surprised ? 0.42
        : expr == CyberExpr.happy || expr == CyberExpr.satisfied ? 0.38
        : 0.24;
    final blushY = faceTop + size.height * 0.27;
    p.color = const Color(0xFFFF9999).withOpacity(blushA);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 20, blushY), width: 22, height: 9), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 20, blushY), width: 22, height: 9), p);

    // ── Eyes ──────────────────────────────────────────────────────────────────
    final eyeY = faceTop + size.height * 0.20;
    final eyeL = Offset(cx - 14, eyeY);
    final eyeR = Offset(cx + 14, eyeY);

    final baseH = expr == CyberExpr.surprised ? 22.0
        : expr == CyberExpr.tired ? 13.0 : 18.0;
    final openH = baseH * (1 - blink);

    // Eye scan for reading
    final scan = isReading ? (eyeScan - 0.5) * 4.0 : 0.0;

    if (openH > 2.5) {
      p.color = Colors.white;
      canvas.drawOval(Rect.fromCenter(center: eyeL, width: 21, height: openH), p);
      canvas.drawOval(Rect.fromCenter(center: eyeR, width: 21, height: openH), p);

      final irisR = 7.5 * (1 - blink * 0.4);
      p.color = const Color(0xFF8B4513);
      canvas.drawCircle(eyeL.translate(scan, 0), irisR, p);
      canvas.drawCircle(eyeR.translate(scan, 0), irisR, p);
      p.color = const Color(0xFFBB6622).withOpacity(0.7);
      canvas.drawCircle(eyeL.translate(scan, 0), irisR * 0.6, p);
      canvas.drawCircle(eyeR.translate(scan, 0), irisR * 0.6, p);
      p.color = Colors.black.withOpacity(0.9);
      canvas.drawCircle(eyeL.translate(scan, 0), irisR * 0.45, p);
      canvas.drawCircle(eyeR.translate(scan, 0), irisR * 0.45, p);

      // Accent ring
      p..color = _accent.withOpacity(0.32 + glow * 0.20)
        ..style = PaintingStyle.stroke..strokeWidth = 1.0;
      canvas.drawCircle(eyeL.translate(scan, 0), irisR, p);
      canvas.drawCircle(eyeR.translate(scan, 0), irisR, p);
      p.style = PaintingStyle.fill;

      // Catchlights
      p.color = Colors.white.withOpacity(0.95);
      canvas.drawCircle(eyeL.translate(scan + 2.2, -2.2), 2.2, p);
      canvas.drawCircle(eyeR.translate(scan + 2.2, -2.2), 2.2, p);
      canvas.drawCircle(eyeL.translate(scan - 2.8, 2.5), 1.1, p);
      canvas.drawCircle(eyeR.translate(scan - 2.8, 2.5), 1.1, p);

      // Eyelashes
      final lashLen = 4.5 * (1 - blink);
      if (lashLen > 0.5) {
        p..color = const Color(0xFF2C1005)
          ..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round;
        for (final eye in [eyeL, eyeR]) {
          for (int i = 0; i < 6; i++) {
            final t = i / 5.0;
            final lx = eye.dx - 10 + t * 20;
            final by = eye.dy - openH / 2 + 1;
            canvas.drawLine(Offset(lx, by), Offset(lx, by - lashLen - sin(t * pi) * 2.0), p);
          }
        }
        p.style = PaintingStyle.fill;
      }
    } else {
      p..color = const Color(0xFF2C1005)
        ..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round;
      for (final eye in [eyeL, eyeR]) {
        canvas.drawPath(Path()
          ..moveTo(eye.dx - 9, eye.dy)
          ..quadraticBezierTo(eye.dx, eye.dy - 4.5, eye.dx + 9, eye.dy), p);
      }
      // Satisfied sparkle
      if (expr == CyberExpr.satisfied || expr == CyberExpr.happy) {
        p.style = PaintingStyle.fill;
        p.color = const Color(0xFFFFDD44).withOpacity(0.88);
        canvas.drawCircle(eyeL.translate(0, -7), 1.8, p);
        canvas.drawCircle(eyeR.translate(0, -7), 1.8, p);
      }
      p.style = PaintingStyle.fill;
    }

    // ── Eyebrows ──────────────────────────────────────────────────────────────
    final browY = eyeY - size.height * 0.065;
    p..color = const Color(0xFF7A4010)
      ..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round;
    switch (expr) {
      case CyberExpr.curious:
        canvas.drawLine(Offset(cx - 24, browY + 2), Offset(cx - 8, browY - 6), p);
        canvas.drawLine(Offset(cx + 8,  browY),     Offset(cx + 24, browY + 4), p);
        break;
      case CyberExpr.surprised:
        canvas.drawLine(Offset(cx - 24, browY - 6), Offset(cx - 8, browY - 4), p);
        canvas.drawLine(Offset(cx + 8,  browY - 4), Offset(cx + 24, browY - 6), p);
        break;
      case CyberExpr.tired:
        canvas.drawLine(Offset(cx - 24, browY + 4), Offset(cx - 8, browY + 3), p);
        canvas.drawLine(Offset(cx + 8,  browY + 3), Offset(cx + 24, browY + 4), p);
        break;
      case CyberExpr.happy:
      case CyberExpr.satisfied:
        canvas.drawLine(Offset(cx - 24, browY),     Offset(cx - 8, browY - 8), p);
        canvas.drawLine(Offset(cx + 8,  browY - 8), Offset(cx + 24, browY),    p);
        break;
      default: // neutral, focused
        canvas.drawLine(Offset(cx - 24, browY + 2), Offset(cx - 8, browY - 3), p);
        canvas.drawLine(Offset(cx + 8,  browY - 3), Offset(cx + 24, browY + 2), p);
    }
    // Focused forehead crease
    if (expr == CyberExpr.focused) {
      p..color = const Color(0xFFE0A070).withOpacity(0.40)..strokeWidth = 0.9;
      canvas.drawLine(Offset(cx - 5, browY - 6), Offset(cx + 5, browY - 6), p);
    }
    p.style = PaintingStyle.fill;

    // ── Glasses ───────────────────────────────────────────────────────────────
    final gOff    = -glassesPush;
    final gEyeL   = eyeL.translate(0, gOff);
    final gEyeR   = eyeR.translate(0, gOff);
    final glassL  = RRect.fromRectAndRadius(Rect.fromCenter(center: gEyeL, width: 24, height: 18), const Radius.circular(5));
    final glassR  = RRect.fromRectAndRadius(Rect.fromCenter(center: gEyeR, width: 24, height: 18), const Radius.circular(5));

    p..color = _accent.withOpacity(0.48 + glow * 0.18)
      ..style = PaintingStyle.stroke..strokeWidth = 1.7;
    canvas.drawRRect(glassL, p);
    canvas.drawRRect(glassR, p);
    canvas.drawLine(Offset(gEyeL.dx + 12, gEyeL.dy), Offset(gEyeR.dx - 12, gEyeR.dy), p);
    canvas.drawLine(Offset(gEyeL.dx - 12, gEyeL.dy), Offset(gEyeL.dx - 21, gEyeL.dy - 2), p);
    canvas.drawLine(Offset(gEyeR.dx + 12, gEyeR.dy), Offset(gEyeR.dx + 21, gEyeR.dy - 2), p);

    // Glasses push gleam
    if (glassesPush > 2.0) {
      p.style = PaintingStyle.fill;
      p.color = Colors.white.withOpacity(glassesPush / 3.5 * 0.50);
      canvas.drawOval(Rect.fromCenter(center: gEyeL.translate(-5, -4), width: 9, height: 4), p);
      canvas.drawOval(Rect.fromCenter(center: gEyeR.translate(-5, -4), width: 9, height: 4), p);
    }

    // Tint fill
    p..color = _accent.withOpacity(0.055)..style = PaintingStyle.fill;
    canvas.drawRRect(glassL, p);
    canvas.drawRRect(glassR, p);

    // ── Nose ──────────────────────────────────────────────────────────────────
    final noseY = faceTop + size.height * 0.32;
    p..color = const Color(0xFFCC8050).withOpacity(0.50)
      ..style = PaintingStyle.stroke..strokeWidth = 1.0..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()
      ..moveTo(cx, noseY)
      ..quadraticBezierTo(cx - 4, noseY + size.height * 0.025, cx - 4, noseY + size.height * 0.032)
      ..moveTo(cx - 4, noseY + size.height * 0.032)
      ..quadraticBezierTo(cx, noseY + size.height * 0.038, cx + 4, noseY + size.height * 0.032), p);
    p.style = PaintingStyle.fill;

    // ── Mouth ─────────────────────────────────────────────────────────────────
    final mc = Offset(cx, faceTop + size.height * 0.38);
    p..color = const Color(0xFFE07070)
      ..style = PaintingStyle.stroke..strokeWidth = 1.9..strokeCap = StrokeCap.round;

    switch (expr) {
      case CyberExpr.happy:
      case CyberExpr.satisfied:
        final smile = Path()
          ..moveTo(mc.dx - 8, mc.dy - 1)
          ..quadraticBezierTo(mc.dx, mc.dy + 7, mc.dx + 8, mc.dy - 1);
        canvas.drawPath(smile, p);
        p..style = PaintingStyle.fill..color = Colors.white.withOpacity(0.85);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: mc.translate(0, 2.5), width: 10, height: 3),
            const Radius.circular(1.5)), p);
        p..style = PaintingStyle.stroke..color = const Color(0xFFE07070);
        canvas.drawPath(smile, p);
        break;
      case CyberExpr.curious:
        canvas.drawLine(Offset(mc.dx - 5, mc.dy), Offset(mc.dx + 5, mc.dy), p);
        p..style = PaintingStyle.fill..color = const Color(0xFFE07070).withOpacity(0.5);
        canvas.drawCircle(mc.translate(0, -5), 1.2, p);
        p.style = PaintingStyle.stroke;
        break;
      case CyberExpr.surprised:
        p.style = PaintingStyle.fill;
        p.color = const Color(0xFF7A1010);
        canvas.drawOval(Rect.fromCenter(center: mc, width: 12, height: 14), p);
        p.color = Colors.white.withOpacity(0.7);
        canvas.drawOval(Rect.fromCenter(center: mc.translate(0, -1), width: 8, height: 5), p);
        break;
      case CyberExpr.tired:
        p.color = const Color(0xFFE07070).withOpacity(0.65);
        canvas.drawPath(Path()
          ..moveTo(mc.dx - 6, mc.dy)
          ..quadraticBezierTo(mc.dx, mc.dy + 3, mc.dx + 6, mc.dy), p);
        break;
      case CyberExpr.focused:
        canvas.drawLine(Offset(mc.dx - 5, mc.dy), Offset(mc.dx + 5, mc.dy), p);
        p..style = PaintingStyle.fill..color = Colors.white.withOpacity(0.55);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: mc.translate(0, 0.5), width: 8, height: 2.5), const Radius.circular(1)), p);
        p.style = PaintingStyle.stroke;
        canvas.drawLine(Offset(mc.dx - 5, mc.dy), Offset(mc.dx + 5, mc.dy), p);
        break;
      default: // neutral
        canvas.drawPath(Path()
          ..moveTo(mc.dx - 6, mc.dy)
          ..quadraticBezierTo(mc.dx, mc.dy + 3, mc.dx + 6, mc.dy), p);
    }
    p.style = PaintingStyle.fill;

    // ── Hair tuck gesture ─────────────────────────────────────────────────────
    if (hairTuck > 0) {
      p.color = const Color(0xFFDAA020).withOpacity(hairTuck * 0.55);
      canvas.drawPath(Path()
        ..moveTo(cx + 30, faceTop + size.height * 0.06)
        ..quadraticBezierTo(cx + 40, faceTop + size.height * 0.02,
            cx + 36, faceTop - size.height * 0.01)
        ..quadraticBezierTo(cx + 28, faceTop + size.height * 0.03,
            cx + 26, faceTop + size.height * 0.07), p);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FRONT HAIR  (same as cyber_ai_assistant — bangs + clip)
  // ════════════════════════════════════════════════════════════════════════════

  void _drawFrontHair(Canvas canvas, Paint p, Size size, double cx) {
    // ── Maid headband ─────────────────────────────────────────────────────────
    p.color = const Color(0xFFF5F0E8);
    canvas.drawPath(Path()
      ..moveTo(cx - 52, size.height * 0.145)
      ..quadraticBezierTo(cx, size.height * 0.110, cx + 52, size.height * 0.145)
      ..lineTo(cx + 52, size.height * 0.163)
      ..quadraticBezierTo(cx, size.height * 0.128, cx - 52, size.height * 0.163)
      ..close(), p);

    // Headband bow (right side)
    for (final sw in [1.0, 1.3]) {
      p.color = const Color(0xFFEEEAE2);
      canvas.drawPath(Path()
        ..moveTo(cx + 26, size.height * 0.143)
        ..quadraticBezierTo(cx + 26 + 11 * sw, size.height * 0.122,
            cx + 26 + 6 * sw,  size.height * 0.152)
        ..quadraticBezierTo(cx + 26, size.height * 0.160,
            cx + 26, size.height * 0.143)
        ..close(), p);
    }

    // Dark outline of bangs
    p.color = const Color(0xFF1A0A00);
    canvas.drawPath(Path()
      ..moveTo(cx - 54, size.height * 0.175)
      ..lineTo(cx - 32, size.height * 0.285)
      ..lineTo(cx - 22, size.height * 0.210)
      ..lineTo(cx - 11, size.height * 0.300)
      ..lineTo(cx - 3,  size.height * 0.195)
      ..lineTo(cx + 3,  size.height * 0.275)
      ..lineTo(cx + 11, size.height * 0.185)
      ..lineTo(cx + 22, size.height * 0.265)
      ..lineTo(cx + 36, size.height * 0.178)
      ..lineTo(cx + 54 + hairTuck * 6, size.height * (0.175 - hairTuck * 0.02))
      ..quadraticBezierTo(cx + 56, -4, cx, -7)
      ..quadraticBezierTo(cx - 56, -4, cx - 54, size.height * 0.175)
      ..close(), p);

    // Golden bangs
    p.color = const Color(0xFFDAA020);
    canvas.drawPath(Path()
      ..moveTo(cx - 52, size.height * 0.175)
      ..lineTo(cx - 30, size.height * 0.280)
      ..lineTo(cx - 21, size.height * 0.208)
      ..lineTo(cx - 10, size.height * 0.295)
      ..lineTo(cx - 2,  size.height * 0.192)
      ..lineTo(cx + 2,  size.height * 0.270)
      ..lineTo(cx + 10, size.height * 0.182)
      ..lineTo(cx + 21, size.height * 0.258)
      ..lineTo(cx + 35, size.height * 0.175)
      ..lineTo(cx + 52 + hairTuck * 5, size.height * (0.175 - hairTuck * 0.018))
      ..quadraticBezierTo(cx + 54, -3, cx, -6)
      ..quadraticBezierTo(cx - 54, -3, cx - 52, size.height * 0.175)
      ..close(), p);

    // Specular highlight
    p.color = const Color(0xFFFFF0A0).withOpacity(0.55);
    canvas.drawPath(Path()
      ..moveTo(cx - 14, size.height * 0.025)
      ..quadraticBezierTo(cx, size.height * 0.005, cx + 14, size.height * 0.025)
      ..lineTo(cx + 10, size.height * 0.100)
      ..quadraticBezierTo(cx, size.height * 0.075, cx - 10, size.height * 0.100)
      ..close(), p);

    // Hair clip (accent colour, glows)
    final clip = Offset(cx + 23, size.height * 0.148);
    p.color = _accent.withOpacity(0.85 + glow * 0.10);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: clip, width: 10, height: 5), const Radius.circular(2)), p);
    p.color = Colors.white.withOpacity(0.40);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: clip.translate(-1, -0.5), width: 5, height: 2), const Radius.circular(1)), p);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CARRIED STACK  (files/papers held in front)
  // ════════════════════════════════════════════════════════════════════════════

  void _drawCarriedStack(Canvas canvas, Paint p, Size sz, double cx) {
    // Position at arm height
    final stackCx = cx;
    final stackY  = sz.height * 0.72;

    canvas.save();
    canvas.translate(stackCx, stackY);

    final files = [
      (-3.0, -4.0,  0.04, const Color(0xFF4488CC), 'folder'),
      ( 4.0, -2.0, -0.03, const Color(0xFFF5F0E6), 'paper'),
      (-2.0,  0.0,  0.01, const Color(0xFFF2EDD8), 'paper'),
      ( 2.0,  2.0, -0.02, const Color(0xFF44AA66), 'folder'),
      ( 0.0,  4.0,  0.00, const Color(0xFFF8F3E8), 'paper'),
    ];

    for (final (ox, oy, rot, col, type) in files) {
      canvas.save();
      canvas.translate(ox, oy);
      canvas.rotate(rot);

      if (type == 'folder') {
        p.color = col.withOpacity(1.0);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 78, height: 55),
            const Radius.circular(2)), p);
        p.color = col.withOpacity(0.7);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(-39, -30, 28, 8), const Radius.circular(2)), p);
        p..color = col.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 0.8;
        canvas.drawLine(const Offset(-35, -10), const Offset(35, -10), p);
        canvas.drawLine(const Offset(-35, -4), const Offset(20, -4), p);
        p.style = PaintingStyle.fill;
      } else {
        p.color = col;
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 70, height: 52),
            const Radius.circular(2)), p);
        p..color = const Color(0xFF888070).withOpacity(0.30)
          ..style = PaintingStyle.stroke..strokeWidth = 0.8;
        for (int l = 0; l < 4; l++) {
          canvas.drawLine(Offset(-28.0, -16.0 + l * 9), Offset(28.0, -16.0 + l * 9), p);
        }
        p..color = const Color(0xFF444030).withOpacity(0.45)..strokeWidth = 2;
        canvas.drawLine(const Offset(-28, -20), const Offset(18, -20), p);
        p.style = PaintingStyle.fill;
      }
      canvas.restore();
    }

    // Rubber band
    p..color = const Color(0xFFCC4444).withOpacity(0.70)
      ..style = PaintingStyle.stroke..strokeWidth = 1.8;
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 82, height: 58), p);
    p.style = PaintingStyle.fill;

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CyberCharPainter old) => true;
}