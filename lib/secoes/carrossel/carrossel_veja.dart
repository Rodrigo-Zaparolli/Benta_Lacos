// carrossel_veja.dart

import 'package:flutter/material.dart';
import 'dart:async';

// Importações do seu projeto
import 'package:benta_lacos/tema/tema_site.dart';
import 'package:benta_lacos/repository/product_repository.dart';
import 'package:benta_lacos/cards/categorias/lacos_card.dart';
import 'package:benta_lacos/produtos/laco.dart'; // Para abrir a LacoPage

class SuggestedProductsCarousel extends StatefulWidget {
  const SuggestedProductsCarousel({super.key});

  @override
  State<SuggestedProductsCarousel> createState() =>
      _SuggestedProductsCarouselState();
}

class _SuggestedProductsCarouselState extends State<SuggestedProductsCarousel> {
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // Configuração do Controller: exibe 3 cards por vez
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 1 / 3,
    );

    _pageController.addListener(_onPageChanged);

    // Timer para passar os slides automaticamente
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final products = ProductRepository.instance.products;
      if (!_pageController.hasClients || products.isEmpty) return;

      final nextPage = _currentPage < products.length - 1
          ? _currentPage + 1
          : 0;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged() {
    if (!_pageController.hasClients || _pageController.page == null) return;
    setState(() {
      _currentPage = _pageController.page!.round();
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Bolinhas indicadoras
  Widget _buildDot(int index, int total) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _currentPage == index ? 12 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: _currentPage == index
            ? TemaSite.corPrimaria
            : TemaSite.corSecundaria.withOpacity(0.3),
      ),
    );
  }

  // Setas Laterais
  Widget _buildArrow({
    required IconData icon,
    required Alignment alignment,
    required VoidCallback onTap,
  }) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: TemaSite.corPrimaria, size: 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProductRepository.instance,
      builder: (context, child) {
        final products = ProductRepository.instance.products;

        if (products.isEmpty) return const SizedBox.shrink();

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                // Título da Seção
                Text(
                  'aproveite e LEVE TAMBÉM',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: TemaSite.fontePrincipal,
                    color: TemaSite.corSecundaria,
                  ),
                ),
                const SizedBox(height: 30),

                // Área do PageView
                SizedBox(
                  height: 480,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: LacoCard(
                              product: products[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        LacoPage(product: products[index]),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      // Botões de navegação
                      _buildArrow(
                        icon: Icons.arrow_back_ios_new,
                        alignment: Alignment.centerLeft,
                        onTap: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                      ),
                      _buildArrow(
                        icon: Icons.arrow_forward_ios,
                        alignment: Alignment.centerRight,
                        onTap: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Indicadores (Dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    products.length,
                    (i) => _buildDot(i, products.length),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
