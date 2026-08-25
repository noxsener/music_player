import 'package:flutter/material.dart';

import '../config/app_theme.dart';

const _kFont = 'Inter';

/// Compact speaker icon used in the header bar.
class SpeakerIcon extends StatelessWidget {
  final double size;
  final double glow;
  const SpeakerIcon({super.key, this.size = 26, this.glow = 0.0});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _SpeakerPainter(AppRawColors.cyan, glow: glow)),
      );
}

/// Full logo for the About dialog — icon + name stacked.
class CodenfastLogo extends StatelessWidget {
  final double iconSize;
  const CodenfastLogo({super.key, this.iconSize = 100});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CustomPaint(painter: _SpeakerPainter(AppRawColors.cyan, glow: 0.5)),
          ),
          const SizedBox(height: 14),
          const Text(
            'CODENFAST PLAYER',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppRawColors.cyan,
              letterSpacing: 2.5,
            ),
          ),
        ],
      );
}

/// Draws a front-view speaker with sound-wave arcs on the right side.
class _SpeakerPainter extends CustomPainter {
  final Color primary;
  final double glow;
  const _SpeakerPainter(this.primary, {this.glow = 0.0});

  @override
  void paint(Canvas canvas, Size sz) {
    final w = sz.width;
    final h = sz.height;
    // Speaker sits left-of-centre so waves have room on the right.
    final sc = Offset(w * 0.40, h * 0.50);
    final sr = h * 0.38;

    // Ambient glow
    if (glow > 0) {
      canvas.drawCircle(
        sc,
        sr * 1.5,
        Paint()
          ..color = primary.withOpacity(glow * 0.20)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sr * 0.9),
      );
    }

    // Outer frame (filled ring)
    canvas.drawCircle(sc, sr,
        Paint()..color = primary.withOpacity(0.10)..style = PaintingStyle.fill);
    canvas.drawCircle(
      sc,
      sr,
      Paint()
        ..color = primary.withOpacity(0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sr * 0.07,
    );

    // Surround (rubber ring)
    canvas.drawCircle(
      sc,
      sr * 0.72,
      Paint()
        ..color = primary.withOpacity(0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sr * 0.11,
    );

    // Cone (radial gradient fill)
    final coneR = sr * 0.52;
    canvas.drawCircle(
      sc,
      coneR,
      Paint()
        ..shader = RadialGradient(
          colors: [primary.withOpacity(0.52), primary.withOpacity(0.08)],
        ).createShader(Rect.fromCircle(center: sc, radius: coneR)),
    );

    // Dust cap
    canvas.drawCircle(sc, sr * 0.14, Paint()..color = primary.withOpacity(0.88));

    // Sound-wave arcs (3 arcs right of speaker)
    for (int i = 1; i <= 3; i++) {
      final wr = sr + i * sr * 0.42;
      final alpha = (0.64 - (i - 1) * 0.18).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: sc, radius: wr),
        -0.58, // ~-33° from 3-o'clock
        1.16,  // ~66° sweep
        false,
        Paint()
          ..color = primary.withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sz.width * 0.038
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_SpeakerPainter old) =>
      old.glow != glow || old.primary != primary;
}
