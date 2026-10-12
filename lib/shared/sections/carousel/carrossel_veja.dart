import 'package:flutter/material.dart';
import '../../../domain/repository/product_repository.dart';
import '../../constants/card.dart';

class SuggestedProductsCarousel extends StatelessWidget {
  const SuggestedProductsCarousel({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ProductRepository.instance,
    builder: (context, _) {
      final products = ProductRepository.instance.products
          .where((p) => p.quantity > 0)
          .take(4)
          .toList();
      if (products.isEmpty) return const SizedBox.shrink();
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                const Text(
                  'Você também pode gostar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1000
                        ? 4
                        : constraints.maxWidth >= 650
                        ? 3
                        : constraints.maxWidth >= 340
                        ? 2
                        : 1;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 16) / columns;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 24,
                      children: products
                          .map(
                            (p) => SizedBox(
                              width: width,
                              child: LacoCard(product: p),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
