import 'package:flutter/material.dart';
import '../../domain/repository/product_repository.dart';

class CatalogStatus extends StatelessWidget {
  final ProductRepository repository;
  final String emptyMessage;
  const CatalogStatus({
    super.key,
    required this.repository,
    this.emptyMessage = 'Novidades chegando. Volte em breve!',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (repository.isLoading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Carregando produtos...'),
          ] else if (repository.error != null) ...[
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 16),
            const Text(
              'Não foi possível carregar os produtos.',
              textAlign: TextAlign.center,
            ),
            TextButton.icon(
              onPressed: repository.reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ] else ...[
            const Icon(Icons.search_off_outlined, size: 40),
            const SizedBox(height: 16),
            Text(emptyMessage, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
