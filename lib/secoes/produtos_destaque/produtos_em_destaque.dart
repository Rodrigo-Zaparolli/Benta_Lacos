import 'package:flutter/material.dart';
import 'package:benta_lacos/cards/categorias/lacos_card.dart';
import 'package:benta_lacos/produtos/lacos.dart';
import 'package:benta_lacos/repository/product_repository.dart';

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
          ListenableBuilder(
            listenable: ProductRepository.instance,
            builder: (context, child) {
              // 🔥 Filtra apenas os marcados pelo Admin
              final featuredProducts = ProductRepository.instance.products
                  .where((p) => p.isFeatured)
                  .toList();

              if (featuredProducts.isEmpty) {
                return const Text('Nenhum destaque no momento 🎀');
              }

              return Wrap(
                spacing: 40,
                runSpacing: 40,
                alignment: WrapAlignment.center,
                children: featuredProducts.map((product) {
                  return LacoCard(
                    product: product,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LacoPage(product: product),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
