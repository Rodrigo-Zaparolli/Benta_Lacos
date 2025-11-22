// lib/pages/criar_conta_page.dart
import 'dart:convert';

import 'package:brasil_fields/brasil_fields.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:validatorless/validatorless.dart';

import '../secoes/cabecalho/cabecalho.dart';
import '../secoes/rodape/rodape.dart';
import '../widgets/background_fundo.dart';
import 'home_page.dart';

class CriarContaPage extends StatefulWidget {
  const CriarContaPage({super.key});

  @override
  State<CriarContaPage> createState() => _CriarContaPageState();
}

class _CriarContaPageState extends State<CriarContaPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // controllers
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmSenhaController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Buscar endereço via ViaCEP
  Future<void> _buscarCep() async {
    final cepOnly = UtilBrasilFields.removeCaracteres(_cepController.text);
    if (cepOnly.length != 8) return;

    setState(() => _loading = true);
    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cepOnly/json/');
      final resp = await http.get(url).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        if (data['erro'] == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('CEP não encontrado')));
        } else {
          _ruaController.text = data['logradouro'] ?? '';
          _bairroController.text = data['bairro'] ?? '';
          _cidadeController.text = data['localidade'] ?? '';
          _estadoController.text = data['uf'] ?? '';
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erro ao buscar CEP')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Função principal de criação de conta
  Future<void> _criarConta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final cpfOnly = UtilBrasilFields.removeCaracteres(_cpfController.text);
    final telefoneOnly = UtilBrasilFields.removeCaracteres(
      _telefoneController.text,
    );
    final cepOnly = UtilBrasilFields.removeCaracteres(_cepController.text);

    try {
      // cria usuário
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final uid = userCred.user!.uid;

      // salva no Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': nome,
        'email': email,
        'cpf': cpfOnly,
        'phone': telefoneOnly,
        'cep': cepOnly,
        'street': _ruaController.text.trim(),
        'number': _numeroController.text.trim(),
        'complement': _complementoController.text.trim(),
        'neighborhood': _bairroController.text.trim(),
        'city': _cidadeController.text.trim(),
        'state': _estadoController.text.trim(),
        'birthdate': _dataNascimentoController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // displayName
      await userCred.user!.updateDisplayName(nome);

      // verificação por e-mail
      if (!(userCred.user?.emailVerified ?? false)) {
        await userCred.user?.sendEmailVerification();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada! Verifique seu e-mail.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.0,
                        ), // totalmente transparente
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.brown.withOpacity(0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            spreadRadius: 2,
                            color: Colors.brown.withOpacity(0.15),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const Text(
                              'Criar nova conta',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // --------- CAMPOS ----------
                            _linha1(),
                            const SizedBox(height: 12),
                            _linha2(),
                            const SizedBox(height: 12),
                            _linha3(),
                            const SizedBox(height: 12),
                            _linha4(),
                            const SizedBox(height: 12),
                            _linha5(),
                            const SizedBox(height: 12),
                            _linha6(),
                            const SizedBox(height: 12),
                            _linha7(),
                            const SizedBox(height: 20),

                            _loading
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
                                        'Criar conta',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
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
    );
  }

  // ---------------- COMPONENTES DAS LINHAS ----------------

  Widget _linha1() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _nomeController,
            validator: Validatorless.required('Nome obrigatório'),
            decoration: _inputDeco('Nome completo *'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _dataNascimentoController,
            decoration: _inputDeco('Data nascimento'),
            keyboardType: TextInputType.datetime,
          ),
        ),
      ],
    );
  }

  Widget _linha2() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _emailController,
            validator: Validatorless.email('E-mail inválido'),
            decoration: _inputDeco('E-mail *'),
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _telefoneController,
            decoration: _inputDeco('Telefone'),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TelefoneInputFormatter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _linha3() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _cpfController,
            validator: Validatorless.required('CPF obrigatório'),
            decoration: _inputDeco('CPF *'),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CpfInputFormatter(),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _cepController,
            validator: Validatorless.required('CEP obrigatório'),
            decoration: _inputDeco('CEP *'),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CepInputFormatter(),
            ],
            onChanged: (v) {
              if (UtilBrasilFields.removeCaracteres(v).length == 8) {
                _buscarCep();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _linha4() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _ruaController,
            decoration: _inputDeco('Rua'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _numeroController,
            decoration: _inputDeco('Número'),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _linha5() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _bairroController,
            decoration: _inputDeco('Bairro'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _complementoController,
            decoration: _inputDeco('Complemento'),
          ),
        ),
      ],
    );
  }

  Widget _linha6() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _cidadeController,
            decoration: _inputDeco('Cidade'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _estadoController,
            decoration: _inputDeco('Estado'),
          ),
        ),
      ],
    );
  }

  Widget _linha7() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _senhaController,
            validator: Validatorless.min(6, 'Senha mínima 6 caracteres'),
            obscureText: true,
            decoration: _inputDeco('Senha *'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _confirmSenhaController,
            validator: Validatorless.compare(
              _senhaController,
              'Senhas diferentes',
            ),
            obscureText: true,
            decoration: _inputDeco('Confirmar senha *'),
          ),
        ),
      ],
    );
  }

  // ---------- Estilo padrão dos campos ----------
  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F5F2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
