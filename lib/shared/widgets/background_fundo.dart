import 'package:flutter/material.dart';

class BackgroundFundo extends StatelessWidget {
  final Widget child;

  const BackgroundFundo({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFFFFCF9), child: child);
  }
}
