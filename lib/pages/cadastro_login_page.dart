import 'package:flutter/material.dart';
import '../secoes/cabecalho/cabecalho.dart';
import '../secoes/rodape/rodape.dart';
import '../widgets/background_fundo.dart'; // usa o fundo padrão do site

class CadastroLoginPage extends StatelessWidget {
  const CadastroLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final senhaController = TextEditingController();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Cabecalho(),

            // ============================
            // CONTEÚDO COM O FUNDO GLOBAL
            // ============================
            BackgroundFundo(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Container(
                    width: 450,
                    padding: const EdgeInsets.all(24),

                    // ❌ NÃO TEM MAIS FUNDO BRANCO
                    // Removido BoxDecoration com cor branca
                    child: Column(
                      children: [
                        const Text(
                          "Entre ou Crie uma Conta",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.pinkAccent,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // CAMPO EMAIL
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: "E-mail",
                            filled: true,
                            fillColor:
                                Colors.white70, // leve fundo para leitura
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // CAMPO SENHA
                        TextField(
                          controller: senhaController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Senha",
                            filled: true,
                            fillColor:
                                Colors.white70, // leve fundo para leitura
                            border: OutlineInputBorder(),
                            // Adicionado um padding extra no conteúdo, apenas visualmente.
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // BOTÃO LOGIN
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Entrar",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Criar nova conta",
                            style: TextStyle(color: Colors.brown, fontSize: 16),
                          ),
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
      ),
    );
  }
}
