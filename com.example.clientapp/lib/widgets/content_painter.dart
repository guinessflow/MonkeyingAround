import 'package:flutter/material.dart';

class ContentBubblePainter extends CustomPainter {
  static const double bubbleTailHeight = 20.0;
  final Color backgroundColor;
  final double borderRadius;
  final double actionIconsPanelHeight;

  ContentBubblePainter({
    required this.backgroundColor,
    this.borderRadius = 8,
    this.actionIconsPanelHeight = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    double width = size.width;
    double height = size.height - bubbleTailHeight - actionIconsPanelHeight;

    Path path = Path();
    path.moveTo(0, borderRadius);
    path.quadraticBezierTo(0, 0, borderRadius, 0);
    path.lineTo(width - borderRadius, 0);
    path.quadraticBezierTo(width, 0, width, borderRadius);
    path.lineTo(width, height - borderRadius);
    path.quadraticBezierTo(width, height, width - borderRadius, height);
    path.lineTo(borderRadius, height);
    path.quadraticBezierTo(0, height, 0, height - borderRadius);

    // Drawing bubble tail
    path.moveTo(width / 2 - bubbleTailHeight, height);
    path.lineTo(width / 2, height + bubbleTailHeight);
    path.lineTo(width / 2 + bubbleTailHeight, height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
