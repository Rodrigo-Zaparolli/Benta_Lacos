import 'package:benta_lacos/produtos/lacos.dart';
import 'package:flutter/material.dart';
import '../../repository/product_repository.dart';
import '../../cards/categorias/lacos_card.dart';
import '../../tema/tema_site.dart';
import '../../widgets/background_fundo.dart';
import '../../secoes/cabecalho/cabecalho.dart'; // Import do cabeçalho
import '../../secoes/rodape/rodape.dart'; // Import do rodapé
import '../../secoes/carrossel/carrossel_veja.dart'; // Import do veja também

class CategoriaPage extends StatelessWidget {
  final String categoriaNome;

  const CategoriaPage({super.key, required this.categoriaNome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removida a AppBar padrão do Scaffold para usar o seu Cabecalho customizado
      body: Column(
        children: [
          // 1. Cabeçalho (Ele já gerencia login/logout internamente)
          const Cabecalho(),

          // 2. Área de Conteúdo Rolável
          Expanded(
            child: BackgroundFundo(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Título da Categoria
                    Text(
                      categoriaNome.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 60,
                      height: 3,
                      color: TemaSite.corPrimaria,
                    ),
                    const SizedBox(height: 40),

                    // Grade de Produtos
                    ListenableBuilder(
                      listenable: ProductRepository.instance,
                      builder: (context, child) {
                        final produtosFiltrados = ProductRepository
                            .instance
                            .products
                            .where((p) => p.category == categoriaNome)
                            .toList();

                        if (produtosFiltrados.isEmpty) {
                          return Container(
                            height: 300,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 60,
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Em breve teremos novidades nesta categoria! 🎀",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 30,
                            runSpacing: 30,
                            alignment: WrapAlignment.center,
                            children: produtosFiltrados.map((product) {
                              return LacoCard(
                                product: product,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LacoPage(product: product),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 60),

                    // 4. Rodapé Final
                    const Rodape(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
