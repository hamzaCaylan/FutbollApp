import 'package:flutter/material.dart';

/// Yeşil sahayı, orta çizgiyi, orta yuvarlağı ve ceza sahalarını çizen painter.
class PitchPainter extends CustomPainter {
  final Color grassColor;
  final Color lineColor;

  PitchPainter({
    this.grassColor = const Color(0xFF2E7D32),
    this.lineColor = Colors.white70,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = grassColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Hafif çizgili şerit efekti (yatay bantlar)
    final stripePaint = Paint()..color = Colors.black.withOpacity(0.04);
    const stripeCount = 10;
    final stripeHeight = size.height / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      if (i.isOdd) {
        canvas.drawRect(
          Rect.fromLTWH(0, stripeHeight * i, size.width, stripeHeight),
          stripePaint,
        );
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Dış çerçeve
    canvas.drawRect(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      linePaint,
    );

    // Orta çizgi
    canvas.drawLine(
      Offset(8, size.height / 2),
      Offset(size.width - 8, size.height / 2),
      linePaint,
    );

    // Orta yuvarlak
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.11,
      linePaint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      3,
      linePaint..style = PaintingStyle.fill,
    );

    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Üst ceza sahası
    final penaltyWidth = size.width * 0.5;
    final penaltyHeight = size.height * 0.16;
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        8,
        penaltyWidth,
        penaltyHeight,
      ),
      strokePaint,
    );

    // Alt ceza sahası
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - penaltyWidth) / 2,
        size.height - 8 - penaltyHeight,
        penaltyWidth,
        penaltyHeight,
      ),
      strokePaint,
    );

    // Üst kale alanı (küçük)
    final goalAreaWidth = size.width * 0.24;
    final goalAreaHeight = size.height * 0.07;
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - goalAreaWidth) / 2,
        8,
        goalAreaWidth,
        goalAreaHeight,
      ),
      strokePaint,
    );

    // Alt kale alanı (küçük)
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - goalAreaWidth) / 2,
        size.height - 8 - goalAreaHeight,
        goalAreaWidth,
        goalAreaHeight,
      ),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant PitchPainter oldDelegate) => false;
}
