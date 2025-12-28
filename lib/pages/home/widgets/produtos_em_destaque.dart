import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/constants/card.dart';
import '../../../domain/catalog/lacos.dart';
import '../../../domain/repository/product_repository.dart';

class ProdutosEmDestaque extends StatefulWidget {
  const ProdutosEmDestaque({super.key});

  @override
  State<ProdutosEmDestaque> createState() => _ProdutosEmDestaqueState();
}

class _ProdutosEmDestaqueState extends State<ProdutosEmDestaque> {
  late PageController _pageController;
  Timer? _timer;
  double _paginaAtual = 0.0;

  @override
  void initState() {
    super.initState();
    // No Desktop (5 itens), 0.2 é o ideal para ficarem próximos
    _pageController = PageController(initialPage: 0, viewportFraction: 0.2);

    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _paginaAtual = _pageController.page!;
        });
      }
    });

    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      final products = ProductRepository.instance.products
          .where((p) => p.isFeatured)
          .toList();
      if (products.isEmpty) return;

      int proximaPagina = (_paginaAtual.round() + 1) % products.length;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          proximaPagina,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final larguraTotal = MediaQuery.of(context).size.width;
    final isMobile = larguraTotal < 800;
    final isTablet = larguraTotal >= 800 && larguraTotal < 1200;

    // Ajuste de colunas: Desktop 5, Tablet 3, Mobile 2
    double fraction = isMobile ? 0.5 : (isTablet ? 0.33 : 0.2);

    if (_pageController.viewportFraction != fraction) {
      _pageController = PageController(
        initialPage: _paginaAtual.round(),
        viewportFraction: fraction,
      );
    }

    return Padding(
      // 🔹 REDUZIDO: Espaçamento vertical da seção como um todo
      padding: const EdgeInsets.only(top: 20, bottom: 40),
      child: Column(
        children: [
          const Text(
            'Destaques da Benta',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),

          // 🔹 REDUZIDO: De 40 para 15 para aproximar o título das fotos
          const SizedBox(height: 15),

          SizedBox(
            // Altura total do carrossel (ajustada para o zoom não cortar)
            height: 400,
            child: ListenableBuilder(
              listenable: ProductRepository.instance,
              builder: (context, child) {
                final featuredProducts = ProductRepository.instance.products
                    .where((p) => p.isFeatured)
                    .toList();

                if (featuredProducts.isEmpty) {
                  return const Center(child: Text('Novidades chegando... 🎀'));
                }

                return PageView.builder(
                  controller: _pageController,
                  clipBehavior: Clip.none,
                  itemCount: featuredProducts.length,
                  itemBuilder: (context, index) {
                    double diferenca = (index - _paginaAtual).abs();
                    double escala = (1 - (diferenca * 0.15)).clamp(0.75, 1.0);
                    double opacidade = (1 - (diferenca * 0.25)).clamp(0.4, 1.0);

                    return Center(
                      child: Opacity(
                        opacity: opacidade,
                        child: Transform.scale(
                          scale: escala,
                          child: Container(
                            width:
                                250, // Card ligeiramente mais estreito para aproximar
                            margin: const EdgeInsets.symmetric(
                              horizontal: 2,
                            ), // Margem mínima
                            child: LacoCard(
                              product: featuredProducts[index],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LacoPage(
                                    product: featuredProducts[index],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
