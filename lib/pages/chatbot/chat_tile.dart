import 'package:flutter/material.dart';
import 'package:mind_healer/const/colors.dart';

class ChatTile extends StatelessWidget {
  final Widget child;

  const ChatTile({
    Key? key,
    
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
                                  Colors.teal,
                                  primegreen,
                                ]
        ),
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      child: child,
    );
  }
}
