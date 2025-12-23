import 'package:flutter/material.dart';
import '../../produtos/tiara.dart'; // Página da Tiara

class TiaraCard extends StatefulWidget {
  const TiaraCard({super.key});

  @override
  State<TiaraCard> createState() => _TiaraCardState();
}

class _TiaraCardState extends State<TiaraCard> {
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
            MaterialPageRoute(builder: (context) => const TiaraPage()),
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
                    'assets/imagens/produtos/tiaras/tiaras.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tiara Premium',
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
