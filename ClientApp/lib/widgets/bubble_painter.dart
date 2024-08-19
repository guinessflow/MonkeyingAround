import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    path.moveTo(0, 0);
    path.lineTo(width, 0);
    path.lineTo(width, height - borderRadius);
    path.quadraticBezierTo(width, height, width - borderRadius, height);
    path.lineTo(borderRadius, height);
    path.quadraticBezierTo(0, height, 0, height - borderRadius);
    path.lineTo(0, 0);
    path.close();

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

class ContentBubblePainterWithoutTopRounded extends CustomPainter {
  static const double bubbleTailHeight = 20.0;
  final Color backgroundColor;
  final double borderRadius;

  ContentBubblePainterWithoutTopRounded({
    required this.backgroundColor,
    this.borderRadius = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    double width = size.width;
    double height = size.height - bubbleTailHeight;

    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(width, 0);
    path.lineTo(width, height - borderRadius);
    path.quadraticBezierTo(width, height, width - borderRadius, height);
    path.lineTo(borderRadius, height);
    path.quadraticBezierTo(0, height, 0, height - borderRadius);
    path.lineTo(0, 0);
    path.close();

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

class RoundedBottomCornersShape extends ShapeBorder {
  final double borderRadius;

  const RoundedBottomCornersShape({this.borderRadius = 16.0});

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  ShapeBorder scale(double t) => RoundedBottomCornersShape(borderRadius: borderRadius * t);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(RRect.fromRectAndCorners(
        rect,
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
      ));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // No need to implement this method for this custom ShapeBorder
  }
}
