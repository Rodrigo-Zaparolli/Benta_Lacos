// ========================================================
// DASHBOARD PAGE
// Página principal da área logada do cliente
// Mostra email logado, atalhos e acesso ao perfil
// Autor: Rodrigo
// ========================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text(
          "Área do Cliente",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Botão do Perfil
          IconButton(
            tooltip: "Meu Perfil",
            onPressed: () {
              Navigator.pushNamed(context, "/profile");
            },
            icon: const Icon(Icons.person, color: Colors.white),
          ),

          // Botão Logout
          IconButton(
            tooltip: "Sair",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),

      // ============================
      // Conteúdo principal
      // ============================
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        color: const Color(0xFFF8F5F2),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bem-vindo(a)!",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 10),

                // Card com informações do usuário
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 40, color: Colors.brown),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            user != null
                                ? "Logado como: ${user.email}"
                                : "Usuário não encontrado",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, "/profile"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Meu Perfil"),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // ============================
                // Seções / atalhos
                // ============================
                const Text(
                  "Minhas opções",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 15),

                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    // PERFIL DO USUÁRIO
                    _tile(
                      icon: Icons.person_pin,
                      label: "Meu Perfil",
                      onTap: () {
                        Navigator.pushNamed(context, "/profile");
                      },
                    ),

                    _tile(
                      icon: Icons.favorite,
                      label: "Favoritos",
                      onTap: () {},
                    ),
                    _tile(
                      icon: Icons.shopping_bag,
                      label: "Meus Pedidos",
                      onTap: () {},
                    ),
                    _tile(icon: Icons.discount, label: "Ofertas", onTap: () {}),
                    _tile(
                      icon: Icons.settings,
                      label: "Configurações",
                      onTap: () {},
                    ),
                    _tile(icon: Icons.support, label: "Ajuda", onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // Widget Tile (item de atalho do dashboard)
  // ========================================================
  Widget _tile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 180,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 7,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.brown),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
