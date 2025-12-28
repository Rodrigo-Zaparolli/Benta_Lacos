import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../pages/cliente/minha_conta.dart';

class CabecalhoLogado extends StatefulWidget {
  final VoidCallback onLogout;

  const CabecalhoLogado({super.key, required this.onLogout});

  @override
  State<CabecalhoLogado> createState() => _CabecalhoLogadoState();
}

class _CabecalhoLogadoState extends State<CabecalhoLogado> {
  bool _hoverConta = false;
  bool _hoverLogout = false;

  // Iniciamos com um texto de carregamento
  String _nomeExibicao = "Carregando...";

  @override
  void initState() {
    super.initState();
    _buscarNomeNoFirestore();
  }

  /// Função principal para buscar o nome do cliente logado
  Future<void> _buscarNomeNoFirestore() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Acessa a coleção 'usuarios' e o documento com o ID do usuário (UID)
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;

          if (mounted) {
            setState(() {
              // Tenta buscar por 'nome' ou 'name'. Se for nulo, usa 'Cliente'.
              _nomeExibicao = data['nome'] ?? data['name'] ?? "Cliente";
            });
          }
        } else {
          // Se o documento não existir, tenta usar o nome do perfil do Firebase Auth
          if (mounted) {
            setState(() {
              _nomeExibicao = user.displayName ?? "Cliente";
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar nome no cabeçalho: $e");
      if (mounted) {
        setState(() => _nomeExibicao = "Cliente");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ÁREA DA CONTA (NOME DO CLIENTE)
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hoverConta = true),
          onExit: (_) => setState(() => _hoverConta = false),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MinhaContaPage()),
              );
            },
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: _hoverConta ? Colors.pinkAccent : Colors.brown,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  "Olá, $_nomeExibicao",
                  style: TextStyle(
                    color: _hoverConta ? Colors.pinkAccent : Colors.brown,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 20),

        // BOTÃO DE LOGOUT
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hoverLogout = true),
          onExit: (_) => setState(() => _hoverLogout = false),
          child: GestureDetector(
            onTap: widget.onLogout,
            child: Row(
              children: [
                Icon(
                  Icons.logout,
                  color: _hoverLogout ? Colors.redAccent : Colors.brown,
                  size: 20,
                ),
                if (_hoverLogout) ...[
                  const SizedBox(width: 4),
                  const Text(
                    "Sair",
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
