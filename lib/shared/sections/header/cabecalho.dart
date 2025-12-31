import 'dart:html' as html; // Necessário para Web (Chrome)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// Imports internos
import 'package:benta_lacos/domain/providers/cart_provider.dart';
import 'package:benta_lacos/pages/cliente/cart/cart_screen.dart';
import 'package:benta_lacos/pages/cliente/categoria_page.dart';
import 'package:benta_lacos/pages/home/home_page.dart';
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
  final TextEditingController _searchController = TextEditingController();

  void _abrirPainelAdmin() {
    if (kIsWeb) {
      // Abre o painel admin em uma nova aba no Chrome
      html.window.open('/admin', '_blank');
    } else {
      Navigator.pushNamed(context, '/admin');
    }
  }

  void _realizarBusca(String termo) {
    if (termo.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoriaPage(
          categoriaNome: termo.trim().toLowerCase(),
          isBusca: true,
        ),
      ),
    );
    _searchController.clear();
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        final User? user = snapshot.data;

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
                        if (user != null) _buildAdminLink(user.uid),
                        const SizedBox(width: 15),
                        user == null
                            ? const CabecalhoDeslogado()
                            : CabecalhoLogado(
                                onLogout: () async {
                                  final cart = Provider.of<CartProvider>(
                                    context,
                                    listen: false,
                                  );
                                  await cart.moverParaFavoritosELimpar();
                                  await _auth.signOut();
                                  if (mounted) {
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
      },
    );
  }

  Widget _buildAdminLink(String uid) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data['tipo'] == 'admin') {
            return TextButton.icon(
              onPressed: _abrirPainelAdmin,
              icon: const Icon(
                Icons.settings_suggest,
                color: Colors.brown,
                size: 20,
              ),
              label: const Text(
                "PAINEL ADMIN",
                style: TextStyle(
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
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
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: _realizarBusca,
          decoration: InputDecoration(
            hintText: 'Pesquisar laços...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.search,
                color: Color(0xFFE91E63),
              ), // Rosa Pink
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
      color: const Color(0xFFFFF3E5),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
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

// ... Mantendo os widgets de apoio (_MenuItem, _LogoLink, CarrinhoIcon) como estavam ...
class _MenuItem extends StatelessWidget {
  final String title;
  const _MenuItem({required this.title});

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoriaPage(categoriaNome: title, isBusca: false),
        ),
      ),
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

class _LogoLink extends StatelessWidget {
  const _LogoLink();

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/imagens/logo.png', height: 60),
          const Text(
            'Acessórios infantis',
            style: TextStyle(
              fontSize: 10,
              color: Colors.brown,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
