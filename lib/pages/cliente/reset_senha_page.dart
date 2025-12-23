import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:validatorless/validatorless.dart';

import '../../secoes/cabecalho/cabecalho.dart';
import '../../secoes/rodape/rodape.dart'; // Mantido comentado, mas não usado.
import '../../widgets/background_fundo.dart';

class ResetSenhaPage extends StatefulWidget {
  const ResetSenhaPage({super.key});

  @override
  State<ResetSenhaPage> createState() => _ResetSenhaPageState();
}

class _ResetSenhaPageState extends State<ResetSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;

  Future<void> _resetSenha() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail enviado! Verifique sua caixa de entrada.'),
        ),
      );

      // Volta para a tela anterior (geralmente a de Login)
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao enviar e-mail';
      if (e.code == 'user-not-found') message = 'Usuário não encontrado';
      if (e.code == 'invalid-email') message = 'E-mail inválido';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Captura o tamanho da tela para garantir que o BackgroundFundo cubra toda a altura.
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      // MODIFICAÇÃO: Removemos o Expanded e o BackgroundFundo é o primeiro filho do Column
      // dentro do SingleChildScrollView. O SingleChildScrollView é o body, garantindo
      // que a rolagem seja possível se o conteúdo exceder a tela, mas o BackgroundFundo
      // será forçado a ter no mínimo a altura total da tela.
      body: SingleChildScrollView(
        // Garante que o conteúdo ocupe no mínimo a altura total da tela, permitindo que
        // o BackgroundFundo se estenda por toda a área.
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: mediaQuery.size.height),
          child: Column(
            // Alinhamento para que o BackgroundFundo cubra o máximo de espaço.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Cabecalho(),

              // MODIFICAÇÃO: BackgroundFundo agora envolve a área do formulário e se expande
              // junto com o ConstrainedBox para preencher o fundo da tela.
              BackgroundFundo(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(25),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Recuperar Senha',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Insira o e-mail cadastrado para receber as instruções de recuperação.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'E-mail',
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Color(0xFFF8F5F2),
                                  ),
                                  validator: Validatorless.multiple([
                                    Validatorless.required(
                                      'E-mail obrigatório',
                                    ),
                                    Validatorless.email('E-mail inválido'),
                                  ]),
                                ),

                                const SizedBox(height: 30),

                                _loading
                                    ? const CircularProgressIndicator()
                                    : SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _resetSenha,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.brown,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          child: const Text(
                                            'Enviar e-mail de recuperação',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),

                                const SizedBox(height: 15),

                                // MODIFICAÇÃO: Botão para voltar à tela anterior (Login)
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Voltar',
                                    style: TextStyle(
                                      color: Colors.brown,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Rodapé (mantido comentado conforme a solicitação anterior)
              const Rodape(),
            ],
          ),
        ),
      ),
    );
  }
}
