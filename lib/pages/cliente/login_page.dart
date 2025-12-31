import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:validatorless/validatorless.dart';
import 'package:provider/provider.dart';

// Imports do seu projeto
import '../../shared/sections/header/cabecalho.dart';
import '../../shared/sections/footer/rodape.dart'; // 👈 Importando o rodapé
import '../../shared/widgets/background_fundo.dart';
import '../../shared/theme/tema_site.dart';
import '../../domain/providers/cart_provider.dart';
import 'criar_conta_page.dart';
import 'reset_senha_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _loading = false;
  bool _obscureSenha = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _senhaController.text,
          );

      final uid = userCredential.user?.uid;
      if (uid == null) return;

      if (!mounted) return;

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.sincronizarDoFirestore(uid);

      if (!mounted) return;

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      final tipo = doc.data()?['tipo'] ?? 'cliente';
      final nome = doc.data()?['nome'] ?? 'Cliente';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bem-vindo(a), $nome!'),
          backgroundColor: Colors.green,
        ),
      );

      if (tipo == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String erroMsg = 'E-mail ou senha incorretos.';
      if (e.code == 'user-not-found') erroMsg = 'Usuário não encontrado.';
      if (e.code == 'wrong-password') erroMsg = 'Senha incorreta.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erroMsg), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao realizar login. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundFundo(
        child: SingleChildScrollView(
          // 👈 Alterado para permitir que o rodapé flua naturalmente
          child: Column(
            children: [
              const Cabecalho(),

              // Conteúdo do Login
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 60,
                  horizontal: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Bem-vindo de volta!',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: TemaSite.corSecundaria,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Acesse à sua conta para continuar',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 32),

                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'E-mail',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: Validatorless.multiple([
                                  Validatorless.required('Campo obrigatório'),
                                  Validatorless.email('E-mail inválido'),
                                ]),
                              ),
                              const SizedBox(height: 20),

                              TextFormField(
                                controller: _senhaController,
                                obscureText: _obscureSenha,
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureSenha
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureSenha = !_obscureSenha,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: Validatorless.required(
                                  'Campo obrigatório',
                                ),
                                onFieldSubmitted: (_) => _login(),
                              ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ResetSenhaPage(),
                                    ),
                                  ),
                                  child: const Text('Esqueceu a senha?'),
                                ),
                              ),
                              const SizedBox(height: 24),

                              _loading
                                  ? const CircularProgressIndicator()
                                  : SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: ElevatedButton(
                                        onPressed: _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: TemaSite.corPrimaria,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'ENTRAR',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Ainda não tem conta?'),
                                  TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CriarContaPage(),
                                      ),
                                    ),
                                    child: const Text(
                                      'Crie uma agora',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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

              const Rodape(), // 👈 Adicionado aqui no final da coluna
            ],
          ),
        ),
      ),
    );
  }
}
