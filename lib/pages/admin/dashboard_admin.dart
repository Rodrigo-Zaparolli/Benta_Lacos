// ---------------------------------------------
// DASHBOARD ADMINISTRATIVO
// Página exclusiva para administradores logados.
// ---------------------------------------------

import 'package:flutter/material.dart';
import '../../secoes/cabecalho/cabecalho_logado.dart';
import '../../secoes/rodape/rodape.dart';
import '../cliente/login_page.dart';
import '../../widgets/background_fundo.dart';
// Importações Necessárias para o Grid
import '../../models/product.dart';
import '../../repository/product_repository.dart'; // Assumindo que o repositório existe
import '../../cards/categorias/lacos_card.dart'; // Usamos o card para exibir o produto na grade
import '../../tema/tema_site.dart';

class DashboardAdminPage extends StatelessWidget {
  const DashboardAdminPage({super.key});

  // Simula a obtenção da lista de produtos (Substitua pela sua lógica real)
  List<Product> _getProducts() {
    // 🔥 Substitua o try-catch pela sua lógica real de obtenção de dados
    try {
      // Tenta obter a lista do repositório
      return ProductRepository.instance.products.cast<Product>();
    } catch (e) {
      // Se houver erro ou ProductRepository não estiver pronto, retorna lista vazia
      return [];
    }
  }

  // WIDGET DEDICADO À EXIBIÇÃO DA GRADE DE PRODUTOS
  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum produto cadastrado para exibir.',
          style: TextStyle(fontSize: 18, color: Colors.brown),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Todos os Produtos Cadastrados (${products.length} itens)',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: TemaSite.corSecundaria,
            ),
          ),
          const SizedBox(height: 20),

          // 🔥 GridView.builder com 3 Colunas
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // <--- CHAVE: 3 COLUNAS FIXAS
                crossAxisSpacing: 25, // Espaçamento horizontal entre os cards
                mainAxisSpacing: 25, // Espaçamento vertical entre os cards
                childAspectRatio:
                    0.65, // Proporção Altura/Largura do Card (ajuste conforme necessário)
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                // Utilizamos o LacoCard para exibir o produto na grade
                return LacoCard(
                  product: product,
                  // TODO: Adicionar lógica para o onTap que leva o Admin para a tela de Edição/Deleção
                  onTap: () {
                    // Exemplo de navegação para a edição
                    // Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductEditPage(product: product)));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _getProducts();

    return Scaffold(
      body: BackgroundFundo(
        child: Column(
          children: [
            // Cabeçalho
            CabecalhoLogado(
              email: "admin@benta.com",
              onLogout: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),

            // CONTEÚDO PRINCIPAL: GRADE DE PRODUTOS
            Expanded(
              child: Center(
                child: Container(
                  width:
                      1200, // Aumenta a largura máxima para dar mais espaço à grade
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  // Chama o novo widget de grade
                  child: _buildProductGrid(context, products),
                ),
              ),
            ),
            const Rodape(),
          ],
        ),
      ),
    );
  }

  // NOTE: O método '_adminCard' original foi removido, pois o grid
  // de produtos agora ocupa a área central do dashboard.
}
