import 'package:flutter/material.dart';
import '../../../shared/constants/card.dart';
import '../../../shared/widgets/catalog_status.dart';
import '../../../domain/repository/product_repository.dart';

class ProdutosEmDestaque extends StatelessWidget {
  const ProdutosEmDestaque({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1240),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
        child: Column(
          children: [
            const Text(
              'Destaques da Benta',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pequenos detalhes para momentos especiais',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ListenableBuilder(
              listenable: ProductRepository.instance,
              builder: (context, _) {
                final repository = ProductRepository.instance;
                final products = repository.products
                    .where((p) => p.isFeatured)
                    .take(8)
                    .toList();
                if (repository.isLoading ||
                    repository.error != null ||
                    products.isEmpty)
                  return CatalogStatus(repository: repository);
                return LayoutBuilder(
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
                            (product) => SizedBox(
                              width: width,
                              child: LacoCard(product: product),
                            ),
                          )
                          .toList(),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/colecao'),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Ver toda a coleção'),
            ),
          ],
        ),
      ),
    ),
  );
}
