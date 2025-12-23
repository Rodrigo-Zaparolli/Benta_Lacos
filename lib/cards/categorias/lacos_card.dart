import 'package:benta_lacos/models/product.dart';
import 'package:benta_lacos/produtos/laco.dart';
import 'package:benta_lacos/models/providers/cart_provider.dart';
import 'package:benta_lacos/tema/tema_site.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget buildProductImage(Product product, {double? width, double? height}) {
  if (product.imageBytes != null && product.imageBytes!.isNotEmpty) {
    return Image.memory(
      product.imageBytes!,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  } else if (product.imagePath != null && product.imagePath!.isNotEmpty) {
    if (product.imagePath!.startsWith('http')) {
      return Image.network(
        product.imagePath!,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else {
      return Image.asset(
        product.imagePath!,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }
  }
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
              if (hover) BoxShadow(color: Colors.black12, blurRadius: 10),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: buildProductImage(widget.product),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  widget.product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'R\$ ${widget.product.price.toStringAsFixed(2)}',
                style: TextStyle(color: TemaSite.corPrimaria, fontSize: 18),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaSite.corPrimaria,
                ),
                onPressed: () {
                  // 1. Adiciona o item
                  context.read<CartProvider>().addItem(widget.product, 1);

                  // 2. Abre a gaveta lateral para o usuário ver o item entrando
                  Scaffold.of(context).openEndDrawer();

                  // 3. Feedback rápido
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Adicionado ao carrinho!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Text(
                  'COMPRAR',
                  style: TextStyle(color: Colors.white),
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
