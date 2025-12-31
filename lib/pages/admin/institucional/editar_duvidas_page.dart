import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/theme/tema_site.dart';

class EditarDuvidasPage extends StatefulWidget {
  const EditarDuvidasPage({super.key});

  @override
  State<EditarDuvidasPage> createState() => _EditarDuvidasPageState();
}

class _EditarDuvidasPageState extends State<EditarDuvidasPage> {
  final _tituloController = TextEditingController();
  final _conteudoController = TextEditingController();
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _buscarDados();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _conteudoController.dispose();
    super.dispose();
  }

  void _buscarDados() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('institucional')
          .doc('duvidas')
          .get();

      if (doc.exists) {
        _tituloController.text = doc.data()?['titulo'] ?? 'Dúvidas Frequentes';
        _conteudoController.text = doc.data()?['conteudo'] ?? '';
      } else {
        _tituloController.text = 'Dúvidas Frequentes';
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados de dúvidas: $e");
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _salvar() async {
    setState(() => _carregando = true);
    try {
      await FirebaseFirestore.instance
          .collection('institucional')
          .doc('duvidas')
          .set({
            'titulo': _tituloController.text,
            'conteudo': _conteudoController.text,
            'ultima_atualizacao': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Página de Dúvidas atualizada!"),
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
        title: const Text("Editar Dúvidas (FAQ)"),
        backgroundColor: TemaAdmin.corAdminEditor,
        foregroundColor: TemaAdmin.Primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Título da página (centralizado como no envio)
            TextField(
              controller: _tituloController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: "Título",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // Conteúdo principal (onde você adicionará as perguntas e respostas)
            TextField(
              controller: _conteudoController,
              maxLines: 20, // Espaço amplo para o texto
              textAlign: TextAlign.start,
              decoration: const InputDecoration(
                labelText: "Perguntas e Respostas",
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                hintText:
                    "Digite aqui suas dúvidas no formato:\n\nP: Qual o prazo?\nR: O prazo é...",
              ),
            ),
            const SizedBox(height: 25),
            // Botão Salvar (estilo verde como solicitado)
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
