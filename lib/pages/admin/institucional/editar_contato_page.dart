import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:benta_lacos/shared/theme/tema_site.dart';

class EditarContatoPage extends StatefulWidget {
  const EditarContatoPage({super.key});

  @override
  State<EditarContatoPage> createState() => _EditarContatoPageState();
}

class _EditarContatoPageState extends State<EditarContatoPage> {
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _buscarDados();
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _buscarDados() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('institucional')
          .doc('contato')
          .get();
      if (doc.exists) {
        setState(() {
          _whatsappController.text = doc['whatsapp'] ?? '';
          _emailController.text = doc['email'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Erro ao buscar contatos: $e");
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _salvar() async {
    setState(() => _carregando = true);
    try {
      await FirebaseFirestore.instance
          .collection('institucional')
          .doc('contato')
          .set({
            'whatsapp': _whatsappController.text,
            'email': _emailController.text,
            'ultima_atualizacao': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Contatos atualizados com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Informações de Contato"),
        backgroundColor: TemaAdmin.corAdminEditor, // Acessando a cor estática
        foregroundColor: TemaAdmin.Primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Configurações de Contato",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "WhatsApp (Apenas números com DDD)",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "E-mail de Contato",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                "SALVAR CONTATOS",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    TemaAdmin.corAdminSalvar, // Acessando a cor estática
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
