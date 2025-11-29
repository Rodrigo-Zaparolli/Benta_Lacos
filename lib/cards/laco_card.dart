import 'package:benta_lacos/models/product.dart';
import 'package:benta_lacos/produtos/laco.dart';
import 'package:benta_lacos/tema/tema_site.dart';
import 'package:flutter/material.dart';

class LacoCard extends StatefulWidget {
  final Product product;
  // 🔥 NOVO: Adiciona o parâmetro opcional onTap
  final VoidCallback? onTap;

  const LacoCard({
    super.key,
    required this.product,
    this.onTap, // 🔥 Inclui no construtor
  });

  @override
  State<LacoCard> createState() => _LacoCardState();
}

class _LacoCardState extends State<LacoCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final double price = product.price;
    final double? oldPrice = product.oldPrice;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        // 🔥 MODIFICADO: Usa widget.onTap se ele existir, senão usa a navegação padrão
        onTap:
            widget.onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LacoPage(product: product)),
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
            border: Border.all(
              color: TemaSite.produto.thumbnailBordaCor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: _buildProductImage(product),
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  product.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TemaSite.produto.tituloCor,
                  ),
                ),
              ),

              const SizedBox(height: 5),

              if (oldPrice != null && oldPrice > 0)
                Text(
                  'R\$ ${oldPrice.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),

              Text(
                'R\$ ${price.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: TemaSite.produto.precoCor,
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

  /// ----------------------------------------------------------
  /// TRATAMENTO COMPLETO DE IMAGENS
  /// ----------------------------------------------------------
  Widget _buildProductImage(Product product) {
    if (product.imageBytes != null) {
      return Image.memory(
        product.imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      if (product.imagePath!.startsWith('http')) {
        return Image.network(
          product.imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } else {
        return Image.asset(
          product.imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
      ),
    );
  }
}
