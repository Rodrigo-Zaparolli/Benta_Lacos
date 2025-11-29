// carrossel_veja.dart

import 'package:flutter/material.dart';
import 'dart:async';

// Paleta e fontes centralizadas no TemaSite
import 'package:benta_lacos/tema/tema_site.dart';

// Repositório de produtos
import 'package:benta_lacos/repository/product_repository.dart';

// ===============================================================
//   CARROSSEL DE PRODUTOS SUGERIDOS
// ===============================================================
class SuggestedProductsCarousel extends StatefulWidget {
  const SuggestedProductsCarousel({super.key});

  @override
  State<SuggestedProductsCarousel> createState() =>
      _SuggestedProductsCarouselState();
}

class _SuggestedProductsCarouselState extends State<SuggestedProductsCarousel> {
  late final List<dynamic> _suggestedProducts;

  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _suggestedProducts = ProductRepository.instance.products.take(4).toList();

    // 1. ATUALIZAÇÃO CHAVE: viewportFraction para exibir 3 cards
    _pageController = PageController(
      initialPage: _currentPage,
      // Cada 'página' ocupa 1/3 da largura total, mostrando 3 cards.
      viewportFraction: 1 / 3,
    );

    _pageController.addListener(_onPageChanged);

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_pageController.hasClients || _suggestedProducts.isEmpty) return;

      final nextPage = _currentPage < _suggestedProducts.length - 1
          ? _currentPage + 1
          : 0;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged() {
    if (!_pageController.hasClients || _pageController.page == null) return;

    setState(() {
      _currentPage = _pageController.page!.round().clamp(
        0,
        _suggestedProducts.length - 1,
      );
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Indicadores (bolinhas)
  // ---------------------------------------------------------------
  Widget _buildDot(int index) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? TemaSite
                  .corPrimaria // bolinha ativa
            : TemaSite.corSecundaria.withOpacity(0.3), // inativa
      ),
    );
  }

  // ---------------------------------------------------------------
  // Botões das setas
  // ---------------------------------------------------------------
  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    // Retorna um widget vazio se houver apenas um card para evitar setas desnecessárias
    if (_suggestedProducts.length <= 1) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: TemaSite.corSecundaria.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: TemaSite.corPrimaria, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_suggestedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: const EdgeInsets.symmetric(vertical: 25),
        child: Column(
          children: [
            // -------------------------------------------------
            // TÍTULO
            // -------------------------------------------------
            Text(
              'aproveite e LEVE TAMBÉM',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: TemaSite.fontePrincipal,
                color: TemaSite.corSecundaria,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 400,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // -------------------------------------------------
                  // PageView com os cards
                  // -------------------------------------------------
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _suggestedProducts.length,
                    itemBuilder: (_, index) {
                      // Simplificado: Retorna o card diretamente para ocupar o viewportFraction (1/3)
                      return ProductSuggestionCard(
                        product: _suggestedProducts[index],
                      );
                    },
                  ),

                  // -------------------------------------------------
                  // Setas
                  // -------------------------------------------------
                  Positioned(
                    left: 10, // Adicionado padding para afastar da borda
                    child: _buildArrowButton(
                      icon: Icons.arrow_back_ios_new,
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    right: 10, // Adicionado padding para afastar da borda
                    child: _buildArrowButton(
                      icon: Icons.arrow_forward_ios,
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // -------------------------------------------------
            // Bolinhas indicadoras
            // -------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _suggestedProducts.length,
                (i) => _buildDot(i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================================
// CARD DE PRODUTO (Ajustado para espaçamento)
// ===============================================================
class ProductSuggestionCard extends StatelessWidget {
  final dynamic product;
  const ProductSuggestionCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 2. ATUALIZAÇÃO CHAVE: Removida a largura fixa e adicionado margin
      margin: const EdgeInsets.symmetric(horizontal: 10),
      // width: 280, // <-- REMOVIDO para que o card se adapte ao 1/3 do PageView
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: TemaSite.corPrimaria.withOpacity(0.4),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: TemaSite.corSecundaria.withOpacity(0.15),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // IMAGEM
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: Image.asset(
                product.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.broken_image, color: TemaSite.corPrimaria),
              ),
            ),
          ),

          // DADOS DO PRODUTO
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: TemaSite.fontePrincipal,
                    color: TemaSite.corSecundaria,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),

                // Preço antigo (se houver)
                if (product.oldPrice > product.price)
                  Text(
                    'R\$ ${product.oldPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      color: TemaSite.corSecundaria.withOpacity(0.6),
                    ),
                  ),

                // Preço normal
                Text(
                  'R\$ ${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: TemaSite.corPrimaria,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                // Preço com Pix
                Row(
                  children: [
                    Icon(Icons.payments, size: 14, color: TemaSite.corDestaque),
                    const SizedBox(width: 4),
                    Text(
                      'R\$ ${(product.price * 0.95).toStringAsFixed(2)} no Pix',
                      style: TextStyle(
                        color: TemaSite.corDestaque,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // BOTÃO
                Center(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: TemaSite.corSecundaria),
                      foregroundColor: TemaSite.corSecundaria,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'COMPRAR',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
