import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/tema_site.dart';

class DepoimentoForm extends StatefulWidget {
  const DepoimentoForm({super.key});

  @override
  State<DepoimentoForm> createState() => _DepoimentoFormState();
}

class _DepoimentoFormState extends State<DepoimentoForm> {
  final _formKey = GlobalKey<FormState>();
  final _textoController = TextEditingController();
  int _estrelas = 5;
  bool _enviando = false;
  String _nomeExibicao = "Carregando nome...";

  @override
  void initState() {
    super.initState();
    _obterNomeUsuario();
  }

  /// Tenta obter o nome do Auth, se não conseguir, busca no Firestore
  Future<void> _obterNomeUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Tenta pelo Firebase Auth
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      if (mounted) setState(() => _nomeExibicao = user.displayName!);
      return;
    }

    // 2. Plano B: Busca na sua coleção 'usuarios' do Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['nome'] != null) {
        if (mounted) setState(() => _nomeExibicao = doc.data()?['nome']);
      } else {
        if (mounted) setState(() => _nomeExibicao = "Cliente Benta Laços");
      }
    } catch (e) {
      if (mounted) setState(() => _nomeExibicao = "Cliente Benta Laços");
    }
  }

  Future<void> _enviarDepoimento() async {
    if (!_formKey.currentState!.validate()) return;
    if (_enviando) return;

    setState(() => _enviando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('depoimentos').add({
        'cliente': _nomeExibicao, // Usa o nome que encontramos
        'uid': user?.uid,
        'texto': _textoController.text,
        'estrelas': _estrelas,
        'aprovado': false,
        'dataEnvio': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Depoimento enviado para moderação!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao enviar: $e")));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Olá, $_nomeExibicao!",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TemaSite.corPrimaria,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Sua avaliação ajuda outras clientes.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 25),

              TextFormField(
                controller: _textoController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Escreva seu comentário...",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v!.isEmpty ? "O comentário não pode ficar vazio" : null,
              ),

              const SizedBox(height: 20),
              const Text(
                "Nota:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _estrelas ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 35,
                    ),
                    onPressed: () => setState(() => _estrelas = index + 1),
                  );
                }),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaSite.corPrimaria,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _enviando ? null : _enviarDepoimento,
                  child: _enviando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "ENVIAR AVALIAÇÃO",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
