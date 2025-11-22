// minha_conta.dart
// Tela da área do cliente (Dashboard)
// Restringe acesso para usuários não logados ou com e-mail não verificado
// Autor: Rodrigo

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../secoes/cabecalho/cabecalho.dart';
import '../secoes/rodape/rodape.dart';
import 'login_page.dart';

class MinhaContaPage extends StatefulWidget {
  const MinhaContaPage({super.key});

  @override
  State<MinhaContaPage> createState() => _MinhaContaPageState();
}

class _MinhaContaPageState extends State<MinhaContaPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  // Verifica se o usuário está logado e se o e-mail está verificado
  void _checkUserStatus() {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) {
      // Redireciona para login se não estiver autorizado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
    }
  }

  // Função de logout
  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      body: Column(
        children: [
          const Cabecalho(),
          Expanded(
            child: Center(
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Área do Cliente',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Bem-vindo(a), ${user?.email ?? "Usuário"}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Rodape(),
        ],
      ),
    );
  }
}
