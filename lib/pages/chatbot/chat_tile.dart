import 'package:flutter/material.dart';

class ChatTile extends StatelessWidget {
  final List<Color> gradientColors;
  final BorderRadiusGeometry borderRadius;
  final Widget child;

  const ChatTile({
    Key? key,
    required this.gradientColors,
    this.borderRadius = const BorderRadius.all(Radius.circular(10.0)),
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}
