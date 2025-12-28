import 'package:benta_lacos/domain/catalog/lacos.dart';
import 'package:flutter/material.dart';
import '../../domain/repository/product_repository.dart';
import '../../shared/constants/card.dart';
import '../../shared/theme/tema_site.dart';
import '../../shared/widgets/background_fundo.dart';
import '../../shared/sections/header/cabecalho.dart';
import '../../shared/sections/footer/rodape.dart';

class CategoriaPage extends StatelessWidget {
  final String categoriaNome;
  final bool isBusca;

  const CategoriaPage({
    super.key,
    required this.categoriaNome,
    this.isBusca = false, // ✅ valor padrão evita erros
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Cabeçalho
          const Cabecalho(),

          // Conteúdo
          Expanded(
            child: BackgroundFundo(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Título
                    Text(
                      isBusca
                          ? 'RESULTADO DA BUSCA'
                          : categoriaNome.toUpperCase(),
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

                    // Lista de produtos
                    ListenableBuilder(
                      listenable: ProductRepository.instance,
                      builder: (context, child) {
                        final produtos = _filtrarProdutos();

                        if (produtos.isEmpty) {
                          return _estadoVazio();
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 30,
                            runSpacing: 30,
                            alignment: WrapAlignment.center,
                            children: produtos.map((product) {
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

                    // Rodapé
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

  // ===============================
  // MÉTODOS AUXILIARES
  // ===============================

  List _filtrarProdutos() {
    final produtos = ProductRepository.instance.products;

    if (isBusca) {
      final termo = categoriaNome.toLowerCase();
      return produtos.where((p) {
        return p.name.toLowerCase().contains(termo);
      }).toList();
    }

    return produtos.where((p) => p.category == categoriaNome).toList();
  }

  Widget _estadoVazio() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            isBusca
                ? 'Nenhum produto encontrado 😕'
                : 'Em breve teremos novidades nesta categoria! 🎀',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
