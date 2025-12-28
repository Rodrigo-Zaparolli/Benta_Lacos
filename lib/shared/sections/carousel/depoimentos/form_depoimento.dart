import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormDepoimento extends StatefulWidget {
  const FormDepoimento({super.key});

  @override
  State<FormDepoimento> createState() => _FormDepoimentoState();
}

class _FormDepoimentoState extends State<FormDepoimento> {
  final _formKey = GlobalKey<FormState>();
  final _textoController = TextEditingController();
  final _nomeController = TextEditingController();
  int _estrelas = 5;

  Future<void> _enviarDepoimento() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('depoimentos').add({
        'cliente': _nomeController.text,
        'texto': _textoController.text,
        'estrelas': _estrelas,
        'aprovado': false, // Começa como falso para você moderar
        'dataEnvio': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Obrigada! Seu depoimento foi enviado para análise. 🎀",
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Deixe seu Depoimento"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: "Seu Nome"),
              validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
            ),
            TextFormField(
              controller: _textoController,
              decoration: const InputDecoration(labelText: "Sua mensagem"),
              maxLines: 3,
              validator: (v) => v!.isEmpty ? "Conte-nos o que achou" : null,
            ),
            const SizedBox(height: 15),
            Row(
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(
                    index < _estrelas ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _estrelas = index + 1),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _enviarDepoimento,
          child: const Text("Enviar"),
        ),
      ],
    );
  }
}
