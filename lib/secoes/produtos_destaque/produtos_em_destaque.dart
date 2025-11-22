import 'package:benta_lacos/cards/laco_card.dart';
import 'package:benta_lacos/cards/tiara_card.dart';
import 'package:benta_lacos/cards/tictac._card.dart';
import 'package:flutter/material.dart';

class ProdutosEmDestaque extends StatelessWidget {
  const ProdutosEmDestaque({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          const Text(
            'Produtos em Destaque',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 40,
            runSpacing: 40,
            children: const [
              TiaraCard(),
              LacoCard(),
              TicTacCard(),
              // Adicione novos cards aqui facilmente
            ],
          ),
        ],
      ),
    );
  }
}
