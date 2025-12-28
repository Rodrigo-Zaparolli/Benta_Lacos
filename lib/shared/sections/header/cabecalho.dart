import 'package:benta_lacos/pages/admin/login/admin_page.dart';
import 'package:benta_lacos/pages/cliente/cart/cart_screen.dart';
import 'package:benta_lacos/pages/cliente/categoria_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:benta_lacos/domain/providers/cart_provider.dart';
import '../../../pages/home/home_page.dart';
import '../../theme/tema_site.dart';
import 'cabecalho_logado.dart';
import 'cabecalho_deslogado.dart';

class Cabecalho extends StatefulWidget {
  const Cabecalho({super.key});

  @override
  State<Cabecalho> createState() => _CabecalhoState();
}

class _CabecalhoState extends State<Cabecalho> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 Controlador para capturar o que o usuário digita
  final TextEditingController _searchController = TextEditingController();

  // 🔥 Função para executar a busca de produtos
  void _realizarBusca(String termo) {
    if (termo.trim().isEmpty) return;

    // Redireciona para a CategoriaPage enviando o termo de pesquisa
    // Usamos toLowerCase() para garantir compatibilidade com a busca case-insensitive no Firestore
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoriaPage(
          categoriaNome: termo.trim().toLowerCase(),
          isBusca: true, // Parâmetro para indicar que é uma pesquisa por nome
        ),
      ),
    );

    _searchController.clear(); // Limpa o campo após a busca
  }

  void _abrirCarrinhoLateral(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Carrinho',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            child: Container(
              width: MediaQuery.of(context).size.width > 600
                  ? 450
                  : MediaQuery.of(context).size.width * 0.85,
              height: double.infinity,
              color: Colors.white,
              child: const CartScreen(),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose(); // Importante para evitar vazamento de memória
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                'assets/imagens/tela_fundo/background_cabecalho.png',
              ),
              fit: BoxFit.cover,
              opacity: 0.95,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSearchField(),
              const SizedBox(width: 40),
              const Expanded(flex: 3, child: _LogoLink()),
              const SizedBox(width: 40),
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    user == null
                        ? const CabecalhoDeslogado()
                        : CabecalhoLogado(
                            onLogout: () async {
                              await _auth.signOut();
                              if (mounted) {
                                setState(() {});
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomePage(),
                                  ),
                                );
                              }
                            },
                          ),
                    const SizedBox(width: 20),
                    Consumer<CartProvider>(
                      builder: (_, cart, __) {
                        return CarrinhoIcon(
                          quantidade: cart.items.length,
                          onTap: () => _abrirCarrinhoLateral(context),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildBottomMenu(),
      ],
    );
  }

  Widget _buildSearchField() {
    return Expanded(
      flex: 4,
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: _realizarBusca, // Busca ao apertar "Enter"
          decoration: InputDecoration(
            hintText: 'Pesquisar laços...',
            border: InputBorder.none,
            // Botão de lupa clicável
            suffixIcon: IconButton(
              icon: const Icon(Icons.search, color: TemaSite.corPrimaria),
              onPressed: () => _realizarBusca(_searchController.text),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomMenu() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF3E5),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _MenuItem(title: 'Laços'),
          _MenuItem(title: 'Tiaras'),
          _MenuItem(title: 'Presilhas'),
          _MenuItem(title: 'Kits'),
          _MenuItem(title: 'Faixas'),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  const _MenuItem({required this.title});

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoriaPage(
              categoriaNome: title,
              isBusca: false, // Indica que é um filtro por categoria fixa
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.brown,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class _LogoLink extends StatefulWidget {
  const _LogoLink();
  @override
  State<_LogoLink> createState() => _LogoLinkState();
}

class _LogoLinkState extends State<_LogoLink> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _hover ? 0.75 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/imagens/logo.png', height: 60),
            const Text(
              'Roupas e Enxoval para Bebê',
              style: TextStyle(
                fontSize: 10,
                color: Colors.brown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CarrinhoIcon extends StatelessWidget {
  final int quantidade;
  final VoidCallback? onTap;
  const CarrinhoIcon({super.key, this.quantidade = 0, this.onTap});
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.shopping_cart_outlined, color: Colors.brown),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.brown,
              shape: BoxShape.circle,
            ),
            child: Text(
              quantidade.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
