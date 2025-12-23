import 'package:flutter/material.dart';
import 'package:benta_lacos/cards/categorias/lacos_card.dart';
import 'package:benta_lacos/produtos/laco.dart';
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
              final products = ProductRepository.instance.products;
              // Pega os 3 primeiros produtos como destaque
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
                alignment: WrapAlignment.center,
                children: featuredProducts.map((product) {
                  return LacoCard(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LacoPage(product: product),
                        ),
                      );
                    },
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
