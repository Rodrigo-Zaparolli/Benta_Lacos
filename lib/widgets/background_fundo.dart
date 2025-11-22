import 'package:flutter/material.dart';

class BackgroundFundo extends StatelessWidget {
  final Widget child;

  const BackgroundFundo({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/imagens/tela_fundo/background.png"),
          fit: BoxFit.cover,
          repeat: ImageRepeat.repeat,
          opacity: 0.85,
        ),
      ),
      child: child,
    );
  }
}
