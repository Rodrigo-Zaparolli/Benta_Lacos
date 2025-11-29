import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:validatorless/validatorless.dart';
import '../widgets/background_fundo.dart';
import '../secoes/cabecalho/cabecalho.dart';
import '../secoes/rodape/rodape.dart'; // Importando o Rodape
import 'login_page.dart';

class CriarContaPage extends StatefulWidget {
  const CriarContaPage({super.key});

  @override
  State<CriarContaPage> createState() => _CriarContaPageState();
}

class _CriarContaPageState extends State<CriarContaPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _cepController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  bool _loading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _buscarCEP() async {
    if (_cepController.text.isEmpty) return;

    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cep.length != 8) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CEP inválido')));
      return;
    }

    try {
      final url = Uri.parse("https://viacep.com.br/ws/$cep/json/");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          _enderecoController.text = "${data['logradouro']}, ${data['bairro']}";
          _cidadeController.text = data['localidade'];
          _estadoController.text = data['uf'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao buscar CEP')));
    }
  }

  Future<void> _criarConta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      if (!(userCred.user?.emailVerified ?? false)) {
        await userCred.user?.sendEmailVerification();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada! Verifique seu e-mail.')),
      );

      // ✔️ Correto → Volta para LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Erro ao criar conta';
      if (e.code == 'email-already-in-use') errorMsg = 'E-mail já está em uso';
      if (e.code == 'weak-password') errorMsg = 'Senha muito fraca';
      if (e.code == 'invalid-email') errorMsg = 'E-mail inválido';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F5F2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // ROLAGEM APLICADA AQUI
        child: BackgroundFundo(
          child: Column(
            children: [
              const Cabecalho(),

              // CONTEÚDO DO FORMULÁRIO (removido Expanded e Center externo)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'Criar Conta',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nomeController,
                                      decoration: _inputDeco('Nome *'),
                                      validator: Validatorless.required(
                                        'Nome obrigatório',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _sobrenomeController,
                                      decoration: _inputDeco('Sobrenome *'),
                                      validator: Validatorless.required(
                                        'Sobrenome obrigatório',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              TextFormField(
                                controller: _emailController,
                                decoration: _inputDeco('E-mail *'),
                                keyboardType: TextInputType.emailAddress,
                                validator: Validatorless.multiple([
                                  Validatorless.required('E-mail obrigatório'),
                                  Validatorless.email('E-mail inválido'),
                                ]),
                              ),
                              const SizedBox(height: 20),

                              TextFormField(
                                controller: _senhaController,
                                decoration: _inputDeco('Senha *'),
                                obscureText: true,
                                validator: Validatorless.multiple([
                                  Validatorless.required('Senha obrigatória'),
                                  Validatorless.min(
                                    6,
                                    'A senha deve ter no mínimo 6 caracteres',
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 20),

                              TextFormField(
                                controller: _confirmarSenhaController,
                                decoration: _inputDeco('Confirmar Senha *'),
                                obscureText: true,
                                validator: Validatorless.multiple([
                                  Validatorless.required(
                                    'Confirmação obrigatória',
                                  ),
                                  Validatorless.compare(
                                    _senhaController,
                                    'As senhas não coincidem',
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 20),

                              TextFormField(
                                controller: _cepController,
                                decoration: _inputDeco('CEP'),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  if (value.length == 8) _buscarCEP();
                                },
                              ),
                              const SizedBox(height: 20),

                              TextFormField(
                                controller: _enderecoController,
                                decoration: _inputDeco('Endereço'),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cidadeController,
                                      decoration: _inputDeco('Cidade'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 80,
                                    child: TextFormField(
                                      controller: _estadoController,
                                      decoration: _inputDeco('UF'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),

                              Center(
                                child: _loading
                                    ? const CircularProgressIndicator()
                                    : SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _criarConta,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.brown,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          child: const Text(
                                            'Criar Conta',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),

                              const SizedBox(height: 10),

                              // Botão para voltar para a tela de Login
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Voltar',
                                    style: TextStyle(
                                      color: Colors.brown,
                                      fontSize: 16,
                                    ),
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

              const Rodape(),
            ],
          ),
        ),
      ),
    );
  }
}
