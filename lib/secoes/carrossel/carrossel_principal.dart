import 'package:flutter/material.dart';
import 'dart:async';

class CarrosselPrincipal extends StatefulWidget {
  const CarrosselPrincipal({super.key});

  @override
  State<CarrosselPrincipal> createState() => _CarrosselPrincipalState();
}

class _CarrosselPrincipalState extends State<CarrosselPrincipal> {
  final List<String> _imageAssets = const [
    'assets/imagens/carousel/banner1.png',
    'assets/imagens/carousel/banner2.png',
    'assets/imagens/carousel/banner3.png',
    'assets/imagens/carousel/banner4.png',
    'assets/imagens/carousel/banner5.png',
  ];

  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);

    // Ouve as mudanças de página feitas pelo usuário (arrastar)
    _pageController.addListener(_onPageChanged);

    // Configuração do Timer para avanço automático
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        if (_currentPage < _imageAssets.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn,
        );
      }
    });
  }

  // Método para atualizar o _currentPage quando o usuário desliza
  void _onPageChanged() {
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

  // --- Widgets de Navegação e Indicadores ---

  // Constrói um ponto (indicador)
  Widget _buildDot(int index) {
    return Container(
      width: 8.0,
      height: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? Colors
                  .white // Cor para o ponto ativo
            : Colors.white.withOpacity(0.4), // Cor para os pontos inativos
      ),
    );
  }

  // Constrói o botão de seta
  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24.0),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400, // <<--- A ALTURA DO CARROSSEL
      width: double.infinity,
      // Stack permite empilhar widgets (PageView, setas, indicadores)
      child: Stack(
        children: <Widget>[
          // 1. O PageView que exibe as imagens
          PageView.builder(
            controller: _pageController,
            itemCount: _imageAssets.length,
            itemBuilder: (context, index) {
              return Image.asset(_imageAssets[index], fit: BoxFit.cover);
            },
          ),

          // 2. Setas de Navegação (Posicionadas nas Laterais)
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Seta Esquerda
                  _buildArrowButton(
                    icon: Icons.arrow_back_ios,
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                  // Seta Direita
                  _buildArrowButton(
                    icon: Icons.arrow_forward_ios,
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Indicadores de Página (Posicionados no Rodapé)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _imageAssets.length,
                  (index) => _buildDot(index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
