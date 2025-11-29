import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:validatorless/validatorless.dart';
import '../secoes/cabecalho/cabecalho.dart';
import '../widgets/background_fundo.dart';

// Páginas chamadas por navegação direta
import 'criar_conta_page.dart';
import 'reset_senha_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _loading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _senha.text,
      );

      // Usuário existe, mas e-mail não verificado
      if (!cred.user!.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifique seu e-mail antes de entrar.'),
          ),
        );
        await _auth.signOut();
        return;
      }

      if (!mounted) return;

      // OBS: NÃO navegamos manualmente para dashboard.
      // O RootDecider detecta login e redireciona.
      Navigator.pushReplacementNamed(context, '/');
    } on FirebaseAuthException catch (e) {
      String msg = 'Erro ao fazer login';

      if (e.code == 'user-not-found') msg = 'Usuário não encontrado';
      if (e.code == 'wrong-password') msg = 'Senha incorreta';
      if (e.code == 'invalid-email') msg = 'E-mail inválido';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundFundo(
        child: Column(
          children: [
            const Cabecalho(),

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

                              TextFormField(
                                controller: _email,
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Color(0xFFF8F5F2),
                                ),
                                validator: Validatorless.multiple([
                                  Validatorless.required('E-mail obrigatório'),
                                  Validatorless.email('E-mail inválido'),
                                ]),
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _senha,
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
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ResetSenhaPage(),
                                        ),
                                      );
                                    },
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
