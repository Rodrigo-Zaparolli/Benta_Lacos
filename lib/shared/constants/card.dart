import 'package:benta_lacos/domain/models/product.dart';
import 'package:benta_lacos/domain/catalog/lacos.dart';
import 'package:benta_lacos/domain/providers/cart_provider.dart';
import 'package:benta_lacos/shared/theme/tema_site.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Função de imagem corrigida para usar apenas a imageUrl do novo modelo
Widget buildProductImage(Product product, {double? width, double? height}) {
  if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
    return Image.network(
      product.imageUrl!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      // Caso o link esteja quebrado, mostra um ícone de erro
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  // Se não houver link nenhum, mostra o placeholder
  return Container(
    width: width,
    height: height,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_not_supported, color: Colors.grey),
  );
}

class LacoCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;

  const LacoCard({super.key, required this.product, this.onTap});

  @override
  State<LacoCard> createState() => _LacoCardState();
}

class _LacoCardState extends State<LacoCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap:
            widget.onTap ??
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LacoPage(product: widget.product),
              ),
            ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 240,
          height: 380,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (hover) const BoxShadow(color: Colors.black12, blurRadius: 10),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: buildProductImage(
                    widget.product,
                    width: double.infinity,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  widget.product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'R\$ ${widget.product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: TemaSite.corPrimaria,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaSite.corPrimaria,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // 1. Adiciona o item ao carrinho
                  context.read<CartProvider>().addItem(widget.product);

                  // 2. Tenta abrir a gaveta (se existir no Scaffold pai)
                  try {
                    Scaffold.of(context).openEndDrawer();
                  } catch (e) {
                    // Se não houver drawer, apenas segue
                  }

                  // 3. Feedback visual
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.product.name} adicionado! 🎀'),
                      backgroundColor: TemaSite.corPrimaria,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: const Text(
                  'COMPRAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
