// login_page.dart
// Tela de login com Firebase Authentication
// Funcionalidades: login, reset de senha, criar nova conta, verificação de e-mail e redirecionamento para Dashboard
// Autor: Rodrigo

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:validatorless/validatorless.dart';
import '../secoes/cabecalho/cabecalho.dart';
import '../widgets/background_fundo.dart';
import 'criar_conta_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ============================
  // Controllers e variáveis de estado
  // ============================
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _loading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================
  // Função de login com verificação + redirecionamento
  // ============================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // Tentativa de login
      final userCred = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text,
      );

      // Verifica se o email foi validado
      if (!userCred.user!.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifique seu e-mail antes de entrar.'),
          ),
        );
        await _auth.signOut();
        return;
      }

      // Login ok → redireciona para o Dashboard
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao fazer login';

      if (e.code == 'user-not-found') message = 'Usuário não encontrado';
      if (e.code == 'wrong-password') message = 'Senha incorreta';
      if (e.code == 'invalid-email') message = 'E-mail inválido';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ============================
  // Função para resetar senha
  // ============================
  Future<void> _resetSenha() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite seu e-mail para resetar a senha')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail de recuperação enviado!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar e-mail: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundFundo(
        child: Column(
          children: [
            const Cabecalho(), // Cabeçalho principal
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Campo de e-mail
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Color(0xFFF8F5F2),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: Validatorless.multiple([
                                  Validatorless.required('E-mail obrigatório'),
                                  Validatorless.email('E-mail inválido'),
                                ]),
                              ),
                              const SizedBox(height: 12),

                              // Campo de senha
                              TextFormField(
                                controller: _senhaController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Senha',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Color(0xFFF8F5F2),
                                ),
                                validator: Validatorless.required(
                                  'Senha obrigatória',
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Botão login
                              _loading
                                  ? const CircularProgressIndicator()
                                  : SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.brown,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        child: const Text(
                                          'Entrar',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                              const SizedBox(height: 12),

                              // Links criar conta / esqueci a senha
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CriarContaPage(),
                                        ),
                                      );
                                    },
                                    child: const Text('Criar nova conta'),
                                  ),
                                  TextButton(
                                    onPressed: _resetSenha,
                                    child: const Text('Esqueci a senha'),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
