import '../../core/config/store_environment.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/product_model.dart';
import '../../domain/providers/cart_provider.dart';
import '../theme/tema_site.dart';
import '../utils/store_format.dart';

Widget buildProductImage(Product product, {double? width, double? height}) {
  final placeholder = Container(
    width: width,
    height: height,
    color: const Color(0xFFF5EEE8),
    child: const Center(
      child: Icon(
        Icons.image_outlined,
        color: TemaSite.corSecundaria,
        size: 40,
      ),
    ),
  );
  if (product.imageUrl == null || product.imageUrl!.isEmpty) return placeholder;
  return Image.network(
    product.imageUrl!,
    width: width,
    height: height,
    fit: BoxFit.contain,
    semanticLabel: product.name,
    loadingBuilder: (context, child, progress) => progress == null
        ? child
        : Container(
            width: width,
            height: height,
            color: const Color(0xFFF5EEE8),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
    errorBuilder: (_, __, ___) => placeholder,
  );
}

class LacoCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  const LacoCard({super.key, required this.product, this.onTap});
  @override
  Widget build(BuildContext context) {
    final available = StoreEnvironment.isTest || product.available;
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEEE5DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap:
                onTap ??
                () => Navigator.pushNamed(
                  context,
                  '/produto/${Uri.encodeComponent(product.id)}',
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: buildProductImage(
                      product,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: SizedBox(
                    height: 48,
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 20,
                  child:
                      product.oldPrice != null &&
                          product.oldPrice! > product.price
                      ? Text(
                          formatMoney(product.oldPrice!),
                          style: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
                Text(
                  formatMoney(product.price),
                  style: const TextStyle(
                    color: TemaSite.corPrimaria,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  available ? 'Feito à mão' : 'Indisponível no momento',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: available
                  ? () {
                      final cart = context.read<CartProvider>();
                      final existing = cart.items
                          .where((item) => item.product.id == product.id)
                          .fold(0, (int count, item) => count + item.quantity);
                      if (!StoreEnvironment.isTest &&
                          existing >= product.purchaseLimit) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Você já adicionou todas as unidades disponíveis.',
                            ),
                          ),
                        );
                        return;
                      }
                      cart.addItem(product);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${product.name} adicionado ao carrinho',
                          ),
                          action: SnackBarAction(
                            label: 'Ver carrinho',
                            onPressed: () =>
                                Navigator.pushNamed(context, '/carrinho'),
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
              ),
              child: Text(
                available ? 'Adicionar ao carrinho' : 'Indisponível',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
