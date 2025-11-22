// ---------------------------------------------
// DASHBOARD ADMINISTRATIVO
// Página exclusiva para administradores logados.
// ---------------------------------------------

import 'package:flutter/material.dart';
import '../secoes/cabecalho/cabecalho_logado.dart';
import '../secoes/rodape/rodape.dart';
import 'login_page.dart';
import '../widgets/background_fundo.dart';

class DashboardAdminPage extends StatelessWidget {
  const DashboardAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundFundo(
        child: Column(
          children: [
            // Cabeçalho já usando email fictício
            CabecalhoLogado(
              email: "admin@benta.com",
              onLogout: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),

            Expanded(
              child: Center(
                child: Container(
                  width: 900,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Painel Administrativo",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Cards do Dashboard
                      Wrap(
                        spacing: 25,
                        runSpacing: 25,
                        children: [
                          _adminCard(Icons.shopping_bag, "Produtos", () {}),
                          _adminCard(Icons.local_offer, "Promoções", () {}),
                          _adminCard(Icons.people, "Clientes", () {}),
                          _adminCard(Icons.receipt_long, "Pedidos", () {}),
                          _adminCard(Icons.settings, "Configurações", () {}),
                          _adminCard(
                            Icons.dashboard_customize,
                            "Conteúdo",
                            () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Rodape(),
          ],
        ),
      ),
    );
  }

  /// ---- CARD BASE PARA O DASHBOARD ----
  static Widget _adminCard(IconData icon, String title, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 260,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.brown.shade200),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: Colors.brown),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
