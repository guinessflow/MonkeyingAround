import 'package:flutter/material.dart';

class FlipBoardEffect extends StatefulWidget {
  final Widget child;

  const FlipBoardEffect({required this.child, Key? key}) : super(key: key);

  @override
  FlipBoardEffectState createState() => FlipBoardEffectState();
}

class FlipBoardEffectState extends State<FlipBoardEffect> {
  double _rotationAngle = 0.0;

  void updateRotation(double angle) {
    setState(() {
      _rotationAngle = angle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(_rotationAngle),
      alignment: Alignment.center,
      child: widget.child,
    );
  }
}
