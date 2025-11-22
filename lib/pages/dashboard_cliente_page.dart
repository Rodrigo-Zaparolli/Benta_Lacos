import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../secoes/cabecalho/cabecalho.dart';
import '../secoes/rodape/rodape.dart';
import '../widgets/background_fundo.dart';
import 'login_page.dart'; // Página de login

class DashboardClientePage extends StatefulWidget {
  const DashboardClientePage({super.key});

  @override
  State<DashboardClientePage> createState() => _DashboardClientePageState();
}

class _DashboardClientePageState extends State<DashboardClientePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;

    _checkLogin();
  }

  void _checkLogin() {
    if (user == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
    }
  }

  // Função de logout
  // ignore: unused_element
  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: BackgroundFundo(
        child: Column(
          children: [
            // Cabecalho agora recebe a função de logout
            Cabecalho(
              // Passa a função de logout para o CabecalhoLogado internamente
              // O Cabecalho vai decidir se mostra logado ou deslogado
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${user!.displayName ?? user!.email}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Bem-vindo(a) à sua área do cliente. Aqui você pode gerenciar suas informações, acompanhar pedidos e muito mais.',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              _DashboardCard(
                                title: 'Meus Pedidos',
                                icon: Icons.shopping_bag,
                              ),
                              _DashboardCard(
                                title: 'Meus Dados',
                                icon: Icons.person,
                              ),
                              _DashboardCard(
                                title: 'Favoritos',
                                icon: Icons.favorite,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;

  // ignore: unused_element_parameter
  const _DashboardCard({required this.title, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 150,
        height: 120,
        child: InkWell(
          onTap: () {
            // Aqui você pode adicionar a navegação para a funcionalidade
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.brown),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
