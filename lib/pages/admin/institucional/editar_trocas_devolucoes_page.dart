import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/theme/tema_site.dart';

class EditarTrocasDevolucoesPage extends StatefulWidget {
  const EditarTrocasDevolucoesPage({super.key});

  @override
  State<EditarTrocasDevolucoesPage> createState() =>
      _EditarTrocasDevolucoesPageState();
}

class _EditarTrocasDevolucoesPageState
    extends State<EditarTrocasDevolucoesPage> {
  final _tituloController = TextEditingController();
  final _conteudoController = TextEditingController();
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _buscarDados();
  }

  void _buscarDados() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('institucional')
          .doc('trocas')
          .get();

      if (doc.exists) {
        _tituloController.text = doc.data()?['titulo'] ?? 'Trocas e Devoluções';
        _conteudoController.text = doc.data()?['conteudo'] ?? '';
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados de trocas: $e");
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _salvar() async {
    setState(() => _carregando = true);
    try {
      await FirebaseFirestore.instance
          .collection('institucional')
          .doc('trocas')
          .set({
            'titulo': _tituloController.text,
            'conteudo': _conteudoController.text,
            'ultima_atualizacao': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Página de Trocas atualizada com sucesso!"),
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
        title: const Text("Editar Trocas e Devoluções"),
        backgroundColor: TemaAdmin.corAdminEditor,
        foregroundColor: TemaAdmin.Primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _tituloController,
              textAlign: TextAlign.center, // 🟢 Centraliza o texto do título
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: const InputDecoration(
                labelText: "Título da Página",
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _conteudoController,
              maxLines: 15,
              textAlign: TextAlign.center, // 🟢 Centraliza o corpo do texto
              decoration: const InputDecoration(
                labelText: "Conteúdo (Texto das Regras de Troca)",
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.save, color: TemaAdmin.Primary),
              label: const Text(
                "SALVAR ALTERAÇÕES",
                style: TextStyle(
                  color: TemaAdmin.Primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaAdmin.corAdminSalvar,
                minimumSize: const Size(double.infinity, 55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
