import '../../core/config/store_environment.dart';
import '../../shared/utils/store_format.dart';
// lib/produtos/laco.dart
import 'package:benta_lacos/domain/models/product_model.dart';
import 'package:benta_lacos/domain/providers/cart_provider.dart';
import 'package:benta_lacos/shared/sections/carousel/carrossel_veja.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/tema_site.dart';
import '../../shared/sections/header/cabecalho.dart';
import '../../shared/sections/footer/rodape.dart';
import '../../shared/widgets/background_fundo.dart';

// ======================================================
// PÁGINA PRINCIPAL DO PRODUTO
// ======================================================
class LacoPage extends StatefulWidget {
  final Product product;
  const LacoPage({super.key, required this.product});

  @override
  State<LacoPage> createState() => _LacoPageState();
}

class _LacoPageState extends State<LacoPage> {
  int _selectedIndex = 0;
  int _quantidade = 1;

  void _showZoomImage(List<String> imagens) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 900),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imagens[_selectedIndex],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _adicionarAoCarrinho(CartProvider cart) {
    final existing = cart.items
        .where((i) => i.product.id == widget.product.id)
        .fold(0, (int sum, i) => sum + i.quantity);
    if (!StoreEnvironment.isTest &&
        _quantidade + existing > widget.product.purchaseLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantidade maior que o estoque disponível.'),
        ),
      );
      return;
    }
    cart.addItem(widget.product, _quantidade);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${widget.product.name} adicionado ao carrinho ($_quantidade unidades)!",
        ),
        backgroundColor: TemaSite.corPrimaria,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final config = TemaSite.produto;
    final cart = Provider.of<CartProvider>(context, listen: false);

    List<String> imagens = [
      if (widget.product.imageUrl != null) widget.product.imageUrl!,
      ...?widget.product.galleryUrls,
    ];

    return Scaffold(
      body: BackgroundFundo(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Cabecalho(),
              const SizedBox(height: 30),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMiniaturasColuna(imagens),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 3,
                              child: _buildImagemPrincipal(imagens),
                            ),
                            const SizedBox(width: 50),
                            Expanded(
                              flex: 2,
                              child: _buildInfoCompra(config, cart),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildImagemPrincipal(imagens),
                            const SizedBox(height: 15),
                            _buildMiniaturasLinha(imagens),
                            const SizedBox(height: 30),
                            _buildInfoCompra(config, cart),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 50),
              _buildDetalhesSection(config),
              const SuggestedProductsCarousel(),
              const Rodape(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniaturasColuna(List<String> imagens) {
    return SizedBox(
      width: 80,
      child: Column(
        children: List.generate(
          imagens.length,
          (index) => _itemMiniatura(imagens, index),
        ),
      ),
    );
  }

  Widget _buildMiniaturasLinha(List<String> imagens) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imagens.length,
        itemBuilder: (context, index) => _itemMiniatura(imagens, index),
      ),
    );
  }

  Widget _itemMiniatura(List<String> imagens, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.only(bottom: 10, right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedIndex == index
                ? TemaSite.corPrimaria
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imagens[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined),
          ),
        ),
      ),
    );
  }

  Widget _buildImagemPrincipal(List<String> imagens) {
    return GestureDetector(
      onTap: imagens.isEmpty ? null : () => _showZoomImage(imagens),
      child: Container(
        height: MediaQuery.of(context).size.width < 600 ? 320 : 500,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: imagens.isNotEmpty
              ? Image.network(
                  imagens[_selectedIndex.clamp(0, imagens.length - 1)],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_outlined, size: 80),
                )
              : const Icon(Icons.image_not_supported, size: 100),
        ),
      ),
    );
  }

  Widget _buildInfoCompra(ConfigProduto config, CartProvider cart) {
    double percentualDesconto = widget.product.discountPix ?? 0;
    double precoPix = widget.product.price * (1 - (percentualDesconto / 100));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: config.tituloCor,
          ),
        ),

        const SizedBox(height: 10),

        if (widget.product.oldPrice != null)
          Text(
            "De ${formatMoney(widget.product.oldPrice!)}",
            style: const TextStyle(
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
              fontSize: 16,
            ),
          ),

        Text(
          "${formatMoney(widget.product.price)}",
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: config.precoCor,
          ),
        ),

        if (percentualDesconto > 0)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${formatMoney(precoPix)} no PIX ($percentualDesconto% de desconto)",
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        const SizedBox(height: 20),

        if (widget.product.madeToOrder)
          Text(
            'Sob encomenda • Fabricação em até ${widget.product.productionDays} dias corridos após aceitação.',
          ),
        const Text(
          "Quantidade:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildQtdSelector(),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: StoreEnvironment.isTest || widget.product.available
                ? () => _adicionarAoCarrinho(cart)
                : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text(
              "Adicionar ao carrinho",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaSite.corPrimaria,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetalhesSection(ConfigProduto config) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100),
        margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: config.abasAtivaCor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes do Produto:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: config.tituloCor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.product.description,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            if (widget.product.composition.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Composição:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: config.tituloCor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.product.composition,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQtdSelector() {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () =>
                setState(() => _quantidade > 1 ? _quantidade-- : null),
            icon: const Icon(Icons.remove),
          ),
          Text(
            "$_quantidade",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed:
                StoreEnvironment.isTest ||
                    _quantidade < widget.product.purchaseLimit
                ? () => setState(() => _quantidade++)
                : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
