// lib/secoes/cabecalho/cabecalho_logado.dart
// Este código deve ser usado no Cabecalho do site quando o usuário estiver logado.
// Exibe o e-mail do usuário e permite acessar "Minha Conta" ou realizar logout.

import 'package:flutter/material.dart';
import '../../pages/minha_conta.dart';

class CabecalhoLogado extends StatefulWidget {
  final String email;
  final VoidCallback onLogout;

  const CabecalhoLogado({
    super.key,
    required this.email,
    required this.onLogout,
  });

  @override
  State<CabecalhoLogado> createState() => _CabecalhoLogadoState();
}

class _CabecalhoLogadoState extends State<CabecalhoLogado> {
  bool _hoverConta = false;
  bool _hoverLogout = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // BOTÃO MINHA CONTA
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
                  Icons.person,
                  color: _hoverConta ? Colors.pinkAccent : Colors.brown,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.email,
                  style: TextStyle(
                    color: _hoverConta ? Colors.pinkAccent : Colors.brown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // BOTÃO LOGOUT
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hoverLogout = true),
          onExit: (_) => setState(() => _hoverLogout = false),
          child: GestureDetector(
            onTap: widget.onLogout,
            child: Icon(
              Icons.logout,
              color: _hoverLogout ? Colors.pinkAccent : Colors.brown,
            ),
          ),
        ),
      ],
    );
  }
}
