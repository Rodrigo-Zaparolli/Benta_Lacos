// lib/secoes/cabecalho/cabecalho.dart
// Cabeçalho principal do site. Detecta se o usuário está logado:
// - Se logado: exibe CabecalhoLogado com e-mail e logout
// - Se deslogado: exibe CabecalhoDeslogado

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../pages/home_page.dart';

// Versões separadas
import 'cabecalho_logado.dart';
import 'cabecalho_deslogado.dart';

class Cabecalho extends StatefulWidget {
  const Cabecalho({super.key});

  @override
  State<Cabecalho> createState() => _CabecalhoState();
}

class _CabecalhoState extends State<Cabecalho> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final User? user = auth.currentUser;

    return Column(
      children: [
        // ===== CABEÇALHO SUPERIOR =====
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                "assets/imagens/tela_fundo/background_cabecalho.png",
              ),
              fit: BoxFit.cover,
              repeat: ImageRepeat.repeat,
              opacity: 0.95,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Campo de pesquisa
              Expanded(
                flex: 4,
                child: Container(
                  height: 45,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.brown, size: 24),
                      SizedBox(width: 10),
                      Text(
                        "Pesquisar...",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 40),

              // Logo central
              const Expanded(flex: 3, child: _LogoLink()),

              const SizedBox(width: 40),

              // Login / Minha conta + carrinho
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Se usuário logado, exibe CabecalhoLogado
                    user == null
                        ? const CabecalhoDeslogado()
                        : CabecalhoLogado(
                            email: user.email ?? "Minha conta",
                            onLogout: () async {
                              await auth.signOut();
                              setState(() {}); // Atualiza o header
                            },
                          ),
                    const SizedBox(width: 20),
                    const CarrinhoIcon(quantidade: 0),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ===== MENU INFERIOR =====
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF3E5),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _MenuItem("Recém Nascidos"),
              _MenuItem("Enxoval"),
              _MenuItem("Menina"),
              _MenuItem("Menino"),
              _MenuItem("Acessórios"),
              _MenuItem("Sapatinhos"),
              _MenuItem("Coleção Verão"),
              _MenuItem("Importados"),
              _MenuItem("Ofertas"),
              _MenuItem("Personalizados"),
              _MenuItem("Boas Festas"),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------- Classes auxiliares -------------------

class _MenuItem extends StatelessWidget {
  final String title;
  const _MenuItem(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: 1,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.brown,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LogoLink extends StatefulWidget {
  const _LogoLink({super.key});

  @override
  State<_LogoLink> createState() => _LogoLinkState();
}

class _LogoLinkState extends State<_LogoLink> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isHovering ? 0.75 : 1.0,
          child: Column(
            children: [
              Image.asset(
                "assets/imagens/logo.png",
                height: 65,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontSize: 12,
                  color: isHovering ? Colors.brown.shade300 : Colors.brown,
                  fontWeight: FontWeight.w600,
                ),
                child: const Text("Roupas e Enxoval para Bebê"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CarrinhoIcon extends StatelessWidget {
  final int quantidade;
  final VoidCallback? onTap;

  const CarrinhoIcon({this.quantidade = 0, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Row(
        children: [
          const Icon(Icons.shopping_cart_outlined, color: Colors.brown),
          const SizedBox(width: 6),
          Text(
            quantidade.toString(),
            style: const TextStyle(color: Colors.brown),
          ),
        ],
      ),
    );
  }
}
