import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:validatorless/validatorless.dart';
import 'package:brasil_fields/brasil_fields.dart';
import '../../widgets/background_fundo.dart';
import '../../secoes/cabecalho/cabecalho.dart';
import '../../secoes/rodape/rodape.dart';
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

  // Novos Controllers solicitados
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _nascimentoController = TextEditingController();

  bool _loading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    _numeroController.dispose();
    _bairroController.dispose();
    _complementoController.dispose();
    _telefoneController.dispose();
    _nascimentoController.dispose();
    super.dispose();
  }

  Future<void> _buscarCEP() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return;

    try {
      final url = Uri.parse("https://viacep.com.br/ws/$cep/json/");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('erro')) return;

        if (!mounted) return;
        setState(() {
          _enderecoController.text = data['logradouro'] ?? '';
          _bairroController.text = data['bairro'] ?? '';
          _cidadeController.text = data['localidade'] ?? '';
          _estadoController.text = data['uf'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Erro ao buscar CEP: $e");
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

      final String uid = userCred.user!.uid;

      await _firestore.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nome': _nomeController.text.trim(),
        'sobrenome': _sobrenomeController.text.trim(),
        'email': _emailController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'dataNascimento': _nascimentoController.text.trim(),
        'cep': _cepController.text.trim(),
        'endereco': _enderecoController.text.trim(),
        'numero': _numeroController.text.trim(),
        'bairro': _bairroController.text.trim(),
        'complemento': _complementoController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'uf': _estadoController.text.trim(),
        'tipo': 'cliente',
        'dataCriacao': FieldValue.serverTimestamp(),
      });

      await userCred.user?.sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso! Verifique seu e-mail.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Erro ao criar conta';
      if (e.code == 'email-already-in-use') errorMsg = 'E-mail já está em uso';
      if (e.code == 'weak-password') errorMsg = 'Senha muito fraca';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro interno ao salvar dados.')),
      );
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
      labelStyle: const TextStyle(color: Colors.brown, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: BackgroundFundo(
          child: Column(
            children: [
              const Cabecalho(),
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
                            children: [
                              const Text(
                                'Criar Conta',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Nome e Sobrenome
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nomeController,
                                      decoration: _inputDeco('Nome *'),
                                      validator: Validatorless.required(
                                        'Obrigatório',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _sobrenomeController,
                                      decoration: _inputDeco('Sobrenome *'),
                                      validator: Validatorless.required(
                                        'Obrigatório',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              // Telefone e Nascimento
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _telefoneController,
                                      decoration: _inputDeco('Telefone *'),
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        TelefoneInputFormatter(),
                                      ],
                                      validator: Validatorless.required(
                                        'Obrigatório',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _nascimentoController,
                                      decoration: _inputDeco('Nascimento *'),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        DataInputFormatter(),
                                      ],
                                      validator: Validatorless.multiple([
                                        Validatorless.required('Obrigatório'),
                                        Validatorless.min(10, 'Data inválida'),
                                      ]),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              TextFormField(
                                controller: _emailController,
                                decoration: _inputDeco('E-mail *'),
                                keyboardType: TextInputType.emailAddress,
                                validator: Validatorless.multiple([
                                  Validatorless.required('Obrigatório'),
                                  Validatorless.email('Inválido'),
                                ]),
                              ),
                              const SizedBox(height: 15),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _senhaController,
                                      decoration: _inputDeco('Senha *'),
                                      obscureText: true,
                                      validator: Validatorless.multiple([
                                        Validatorless.required('Obrigatório'),
                                        Validatorless.min(
                                          6,
                                          'Mínimo 6 caracteres',
                                        ),
                                      ]),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _confirmarSenhaController,
                                      decoration: _inputDeco('Confirmar *'),
                                      obscureText: true,
                                      validator: Validatorless.multiple([
                                        Validatorless.required('Obrigatório'),
                                        Validatorless.compare(
                                          _senhaController,
                                          'Diferente',
                                        ),
                                      ]),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              const Divider(),
                              const SizedBox(height: 10),
                              const Text(
                                "Endereço",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                              const SizedBox(height: 15),

                              // CEP e Bairro
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _cepController,
                                      decoration: _inputDeco('CEP'),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        CepInputFormatter(),
                                      ],
                                      onChanged: (value) {
                                        if (value.length == 10) _buscarCEP();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _bairroController,
                                      decoration: _inputDeco('Bairro'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              // Endereço (Logradouro) e Número
                              Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: TextFormField(
                                      controller: _enderecoController,
                                      decoration: _inputDeco('Rua/Avenida'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _numeroController,
                                      decoration: _inputDeco('Nº'),
                                      keyboardType: TextInputType.text,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              TextFormField(
                                controller: _complementoController,
                                decoration: _inputDeco(
                                  'Complemento (Apto, Bloco, etc.)',
                                ),
                              ),
                              const SizedBox(height: 15),

                              // Cidade e UF
                              Row(
                                children: [
                                  Expanded(
                                    flex: 4,
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
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(2),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),

                              _loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.brown,
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _criarConta,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.brown,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'CRIAR CONTA',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Voltar para Login',
                                  style: TextStyle(color: Colors.brown),
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
