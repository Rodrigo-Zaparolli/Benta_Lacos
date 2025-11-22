import 'package:flutter/material.dart';

// Estrutura de dados para um Depoimento
class Depoimento {
  final String texto;
  final String cliente;
  final int estrelas;
  final String fotoAsset;

  const Depoimento({
    required this.texto,
    required this.cliente,
    required this.estrelas,
    required this.fotoAsset,
  });
}

class CarrosselDepoimentos extends StatefulWidget {
  const CarrosselDepoimentos({super.key});

  @override
  State<CarrosselDepoimentos> createState() => _CarrosselDepoimentosState();
}

class _CarrosselDepoimentosState extends State<CarrosselDepoimentos> {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;

  final List<Depoimento> _depoimentos = const [
    Depoimento(
      texto:
          "Os laços são maravilhosos! Minha filha amou todos, e a qualidade é superior. Entrega super rápida!",
      cliente: "Ana P. de Oliveira",
      estrelas: 5,
      fotoAsset: 'assets/imagens/clientes/cliente1.png',
    ),
    Depoimento(
      texto:
          "Atendimento excelente! Precisava de um conjunto para um evento e fui prontamente atendida. Recomendo de olhos fechados.",
      cliente: "Carla R. Souza",
      estrelas: 4,
      fotoAsset: 'assets/imagens/clientes/cliente2.png',
    ),
    Depoimento(
      texto:
          "Sempre compro aqui. A variedade de tiaras é incrível, e o preço é justo pela durabilidade dos produtos.",
      cliente: "Beatriz M. Santos",
      estrelas: 5,
      fotoAsset: 'assets/imagens/clientes/cliente3.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _autoScroll();
  }

  void _autoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1 < _depoimentos.length
            ? _currentPage + 1
            : 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPage = nextPage;
        });
        _autoScroll();
      }
    });
  }

  Widget _buildStars(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Icon(
          index < count ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20.0,
        );
      }),
    );
  }

  Widget _buildDepoimentoCard(Depoimento depoimento, bool isActive) {
    return Transform.scale(
      scale: isActive ? 1.0 : 0.9,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Foto do cliente
            CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(depoimento.fotoAsset),
            ),
            const SizedBox(height: 10),
            _buildStars(depoimento.estrelas),
            const SizedBox(height: 15),
            Text(
              '"${depoimento.texto}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '- ${depoimento.cliente} -',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 8.0,
      height: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? Colors.pink : Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'O que Nossos Clientes Dizem',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 250, // <<--- A ALTURA DO CARROSSEL
          child: PageView.builder(
            controller: _pageController,
            itemCount: _depoimentos.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              bool isActive = index == _currentPage;
              return _buildDepoimentoCard(_depoimentos[index], isActive);
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _depoimentos.length,
            (index) => _buildDot(index),
          ),
        ),
      ],
    );
  }
}
