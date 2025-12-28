import 'package:flutter/material.dart';
import 'package:benta_lacos/pages/home/home_page.dart';
import 'package:benta_lacos/shared/sections/header/cabecalho.dart';
import 'package:benta_lacos/shared/sections/footer/rodape.dart';
import 'package:benta_lacos/shared/widgets/background_fundo.dart'; // Importa o widget reutilizável de fundo

class TiaraPage extends StatelessWidget {
  const TiaraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundFundo(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // =========================
              // CABEÇALHO
              // =========================
              const Cabecalho(),

              const SizedBox(height: 20),

              // =========================
              // BOTÃO VOLTAR PARA HOME
              // =========================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.brown),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // CONTEÚDO DO PRODUTO
              // =========================
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/imagens/produtos/tiaras/tiaras.png',
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tiara Premium',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'R\$ 29,90',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // adicionar ao carrinho
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Adicionar ao Carrinho'),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),

              // =========================
              // RODAPÉ
              // =========================
              const Rodape(),
            ],
          ),
        ),
      ),
    );
  }
}
