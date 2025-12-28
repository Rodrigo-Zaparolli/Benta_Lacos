// ---------------------------------------------
// DASHBOARD ADMINISTRATIVO
// Página exclusiva para administradores logados.
// ---------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../secoes/cabecalho/cabecalho_logado.dart';
import '../../secoes/rodape/rodape.dart';
import '../cliente/login_page.dart';
import '../../widgets/background_fundo.dart';
import '../../models/product.dart';
import '../../repository/product_repository.dart';
import '../../cards/categorias/lacos_card.dart';
import '../../tema/tema_site.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verificarAuth();
    // Escuta mudanças no repositório para atualizar a grade automaticamente
    ProductRepository.instance.addListener(_atualizarTela);
  }

  @override
  void dispose() {
    ProductRepository.instance.removeListener(_atualizarTela);
    super.dispose();
  }

  void _atualizarTela() => setState(() {});

  // Apenas verifica se há um usuário para parar o loading inicial
  void _verificarAuth() {
    if (_auth.currentUser != null) {
      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
    }
  }

  // Obtém a lista real de produtos do repositório
  List<Product> _getProducts() {
    return ProductRepository.instance.products;
  }

  @override
  Widget build(BuildContext context) {
    final products = _getProducts();

    return Scaffold(
      body: BackgroundFundo(
        child: Column(
          children: [
            // CABEÇALHO AJUSTADO: Removido o parâmetro 'nome' que causava o erro.
            // O componente agora busca o nome sozinho no Firestore.
            CabecalhoLogado(
              onLogout: () async {
                await _auth.signOut();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                }
              },
            ),

            // CONTEÚDO PRINCIPAL: GRADE DE PRODUTOS
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: TemaSite.corPrimaria,
                      ),
                    )
                  : Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
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

  // WIDGET DEDICADO À EXIBIÇÃO DA GRADE DE PRODUTOS
  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 15),
            Text(
              'Nenhum produto cadastrado.',
              style: TextStyle(fontSize: 18, color: Colors.brown),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Painel de Produtos (${products.length} itens)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: TemaSite.corSecundaria,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Abrir formulário de novo produto
              },
              icon: const Icon(Icons.add),
              label: const Text("Novo Produto"),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaSite.corPrimaria,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),

        // GridView com 3 Colunas
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 30,
              mainAxisSpacing: 30,
              childAspectRatio: 0.7,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Stack(
                children: [
                  LacoCard(
                    product: product,
                    onTap: () {
                      // Lógica de edição
                    },
                  ),
                  // Ícones de ação rápida para o Admin
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      children: [
                        _buildActionIcon(Icons.edit, Colors.blue, () {
                          // Lógica editar
                        }),
                        const SizedBox(width: 5),
                        _buildActionIcon(Icons.delete, Colors.red, () {
                          // Lógica deletar
                        }),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
      ),
    );
  }
}
