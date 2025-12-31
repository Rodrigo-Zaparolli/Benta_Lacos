import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/sections/header/cabecalho.dart';
import '../../shared/sections/footer/rodape.dart';
import 'login_page.dart';

class MinhaContaPage extends StatefulWidget {
  const MinhaContaPage({super.key});

  @override
  State<MinhaContaPage> createState() => _MinhaContaPageState();
}

class _MinhaContaPageState extends State<MinhaContaPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers para todos os campos
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _sobrenomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _nascimentoController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _ufController = TextEditingController();

  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosCompletos();
  }

  Future<void> _carregarDadosCompletos() async {
    final user = _auth.currentUser;
    if (user == null) {
      _redirecionarLogin();
      return;
    }

    try {
      DocumentSnapshot doc = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        Map<String, dynamic> d = doc.data() as Map<String, dynamic>;
        setState(() {
          _nomeController.text = d['nome'] ?? '';
          _sobrenomeController.text = d['sobrenome'] ?? '';
          _telefoneController.text = d['telefone'] ?? '';
          _nascimentoController.text = d['nascimento'] ?? '';
          _cepController.text = d['cep'] ?? '';
          _bairroController.text = d['bairro'] ?? '';
          _ruaController.text = d['rua'] ?? '';
          _numeroController.text = d['numero'] ?? '';
          _complementoController.text = d['complemento'] ?? '';
          _cidadeController.text = d['cidade'] ?? '';
          _ufController.text = d['uf'] ?? '';
          _carregando = false;
        });
      } else {
        setState(() => _carregando = false);
      }
    } catch (e) {
      debugPrint("Erro ao carregar: $e");
      setState(() => _carregando = false);
    }
  }

  // FUNÇÃO ATUALIZADA COM REDIRECIONAMENTO PARA HOME
  Future<void> _salvarAlteracoes() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('usuarios').doc(user.uid).update({
        'nome': _nomeController.text,
        'sobrenome': _sobrenomeController.text,
        'telefone': _telefoneController.text,
        'nascimento': _nascimentoController.text,
        'cep': _cepController.text,
        'bairro': _bairroController.text,
        'rua': _ruaController.text,
        'numero': _numeroController.text,
        'complemento': _complementoController.text,
        'cidade': _cidadeController.text,
        'uf': _ufController.text,
      });

      if (!mounted) return;

      // Exibe mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso! Redirecionando...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Aguarda o SnackBar aparecer e redireciona para a Home
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushNamed(context, '/home');
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _redirecionarLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Cabecalho(),
            _carregando
                ? const Padding(
                    padding: EdgeInsets.all(100),
                    child: CircularProgressIndicator(color: Colors.brown),
                  )
                : Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 40,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'MEU PERFIL',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildField('Nome', _nomeController),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: _buildField(
                                      'Sobrenome',
                                      _sobrenomeController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildField(
                                      'Telefone',
                                      _telefoneController,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: _buildField(
                                      'Nascimento',
                                      _nascimentoController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              _buildField(
                                'E-mail (Não editável)',
                                null,
                                isEmail: true,
                                initialValue: _auth.currentUser?.email ?? '',
                              ),

                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 25),
                                child: Divider(),
                              ),
                              const Text(
                                'ENDEREÇO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                              const SizedBox(height: 15),

                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildField('CEP', _cepController),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    flex: 3,
                                    child: _buildField(
                                      'Bairro',
                                      _bairroController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: _buildField(
                                      'Rua/Avenida',
                                      _ruaController,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    flex: 1,
                                    child: _buildField('Nº', _numeroController),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              _buildField(
                                'Complemento',
                                _complementoController,
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: _buildField(
                                      'Cidade',
                                      _cidadeController,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    flex: 1,
                                    child: _buildField('UF', _ufController),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _salvarAlteracoes,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'SALVAR ALTERAÇÕES',
                                    style: TextStyle(
                                      color: Colors.white,
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
            const Rodape(),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController? controller, {
    bool isEmail = false,
    String? initialValue,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      readOnly: isEmail,
      decoration: InputDecoration(
        labelText: label,
        filled: isEmail,
        fillColor: isEmail ? Colors.grey[200] : Colors.transparent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
      ),
    );
  }
}
