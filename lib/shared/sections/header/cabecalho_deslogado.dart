import 'package:benta_lacos/pages/cliente/login_page.dart';
import 'package:flutter/material.dart';

class CabecalhoDeslogado extends StatelessWidget {
  const CabecalhoDeslogado({super.key});

  @override
  Widget build(BuildContext context) {
    // O widget retorna diretamente o Row, permitindo que o fundo do widget Pai (Cabecalho) seja visível.
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.end, // Ajustado para ficar na direita
      mainAxisSize: MainAxisSize.min, // Ajustado para ocupar o mínimo de espaço
      children: [
        // LOGIN — ícone + texto SEM FUNDO
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Row(
                children: [
                  Icon(Icons.person, color: Colors.brown),
                  SizedBox(width: 6),
                  Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
