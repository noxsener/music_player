import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

class ScanLineLoader extends StatefulWidget {
  final double? width;
  final double? height;

  const ScanLineLoader({super.key, this.width, this.height});

  @override
  State<ScanLineLoader> createState() => _ScanLineLoaderState();
}

class _ScanLineLoaderState extends State<ScanLineLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        // SizedBox.expand fills parent when width/height are null
        size: widget.width != null && widget.height != null
            ? Size(widget.width!, widget.height!)
            : Size.infinite,
        // ← tells CustomPaint to use parent constraints
        painter: _ScanPainter(_ctrl.value),
      ),
    ),
  );
}

class _ScanPainter extends CustomPainter {
  final double progress;

  _ScanPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Performans Modu: Mobil cihazlarda (Android/iOS) daha az hesaplama yapması için
    final bool isLowPerf = (Platform.isAndroid || Platform.isIOS);

    // 1. Tarama Çizgisi Boyaları
    final linePaint = Paint()
      ..color = AppRawColors.cyan.withOpacity(0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = AppRawColors.cyan.withOpacity(0.15)
      ..strokeWidth =
          8.0 // Mobilde parlamayı biraz kıstık (Glow renderı yorar)
      ..style = PaintingStyle.stroke;

    // 2. Tarama Çizgisini Çiz (Glow + Keskin Çizgi)
    final y = size.height * progress;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), glowPaint);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    // 3. Arkaplan Izgara Noktaları (High-Performance Optimizasyonu)
    final dotPaint = Paint()
      ..color = AppRawColors.cyan.withOpacity(0.12)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    // Nokta aralığı: Mobilde 40px (daha seyrek), Desktop'ta 20px
    final double spacing = isLowPerf ? 40.0 : 20.0;

    // Tüm noktaları tek bir listede toplayıp tek seferde GPU'ya gönderiyoruz
    final List<Offset> points = [];

    for (double x = 0; x <= size.width; x += spacing) {
      for (double dy = 0; dy <= size.height; dy += spacing) {
        points.add(Offset(x, dy));
      }
    }

    // drawCircle yerine drawPoints kullanımı FPS'i ciddi oranda artırır
    canvas.drawPoints(PointMode.points, points, dotPaint);
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.progress != progress;
}
