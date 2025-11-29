import 'package:benta_lacos/cards/laco_card.dart';
import 'package:benta_lacos/repository/product_repository.dart';
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

          // Usa ListenableBuilder para obter e atualizar a lista de produtos
          ListenableBuilder(
            listenable: ProductRepository.instance,
            builder: (context, child) {
              final products = ProductRepository.instance.products;

              // Seleciona os primeiros 3 produtos para o destaque
              final featuredProducts = products.take(3).toList();

              if (featuredProducts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    'Nenhum produto em destaque no momento.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return Wrap(
                spacing: 40,
                runSpacing: 40,
                children: featuredProducts.map((product) {
                  // Mapeia cada produto para um LacoCard dinâmico
                  return LacoCard(product: product);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Nota: Os imports de TiaraCard e TicTacCard foram removidos pois
// a lógica agora usa o LacoCard dinâmico para todos os produtos em destaque.
