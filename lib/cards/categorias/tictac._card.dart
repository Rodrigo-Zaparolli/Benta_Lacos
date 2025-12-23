import 'package:benta_lacos/produtos/tictac.dart';
import 'package:flutter/material.dart';

class TicTacCard extends StatefulWidget {
  const TicTacCard({super.key});

  @override
  State<TicTacCard> createState() => _TicTacCarddState();
}

class _TicTacCarddState extends State<TicTacCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TicTacPage()),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 240,
          height: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              if (hover)
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/imagens/produtos/tictac/tictac.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'tictac Premium',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              const Text(
                'R\$ 29,90',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
