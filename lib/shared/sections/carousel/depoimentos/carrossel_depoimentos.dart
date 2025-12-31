import 'dart:async';
import 'package:benta_lacos/shared/sections/carousel/depoimentos/depoimento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CarrosselDepoimentos extends StatefulWidget {
  const CarrosselDepoimentos({super.key});

  @override
  State<CarrosselDepoimentos> createState() => _CarrosselDepoimentosState();
}

class _CarrosselDepoimentosState extends State<CarrosselDepoimentos> {
  late final PageController _pageController;
  Timer? _timer;

  int _indiceAtual = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();

    final largura =
        WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .physicalSize
            .width /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    final isMobile = largura < 800;

    _pageController = PageController(viewportFraction: isMobile ? 0.7 : 0.4);
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (_total <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      _indiceAtual = (_indiceAtual + 1) % _total;
      _pageController.animateToPage(
        _indiceAtual,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('depoimentos')
          .where('aprovado', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final depoimentos = snapshot.data!.docs
            .map((doc) => Depoimento.fromFirestore(doc))
            .toList();

        if (_total != depoimentos.length) {
          _total = depoimentos.length;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _startAutoScroll(),
          );
        }

        return Column(
          children: [
            const Text(
              'O que Nossos Clientes Dizem',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ============================================================
            // ONDE MUDA A ALTURA (1): O SizedBox abaixo controla a altura
            // total do carrossel. Se você quer o card menor, diminua este valor.
            // ============================================================
            SizedBox(
              height: 155, // <--- Altere aqui para diminuir ou aumentar o card
              child: PageView.builder(
                controller: _pageController,
                itemCount: depoimentos.length,
                onPageChanged: (index) {
                  setState(() {
                    _indiceAtual = index;
                  });
                  _startAutoScroll();
                },
                itemBuilder: (context, index) {
                  final diferenca = (index - _indiceAtual).abs();
                  final escala = (1 - diferenca * 0.12).clamp(0.85, 1.0);
                  final opacidade = (1 - diferenca * 0.3).clamp(0.5, 1.0);

                  return Center(
                    child: Opacity(
                      opacity: opacidade,
                      child: Transform.scale(
                        scale: escala,
                        child: _cardDepoimento(
                          depoimentos[index],
                          index == _indiceAtual,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _dots(depoimentos.length),
          ],
        );
      },
    );
  }

  Widget _cardDepoimento(Depoimento dep, bool ativo) {
    return Container(
      width: 400,

      // ============================================================
      // ONDE MUDA A ALTURA (2): O padding interno também afeta o tamanho
      // percebido. Quanto menor o vertical, mais "achatado" o card fica.
      // ============================================================
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),

      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (ativo)
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Espaçamentos internos (SizedBox) menores ajudam a reduzir a altura
          CircleAvatar(
            backgroundColor: const Color(0xFFFFE4E1),
            radius: 20,
            child: const Icon(Icons.format_quote, color: Colors.pink, size: 24),
          ),
          const SizedBox(height: 8), // <--- Espaço interno reduzido
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Icon(
                i < dep.estrelas ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"${dep.texto}"',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            dep.cliente.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.pink,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final ativo = _indiceAtual == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: ativo ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: ativo ? Colors.pink : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}
