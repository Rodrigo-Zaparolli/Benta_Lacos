import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/theme/tema_site.dart';

class EditarPoliticaPage extends StatefulWidget {
  const EditarPoliticaPage({super.key});

  @override
  State<EditarPoliticaPage> createState() => _EditarPoliticaPageState();
}

class _EditarPoliticaPageState extends State<EditarPoliticaPage> {
  // Controladores básicos de texto, seguindo o padrão da EditarHistoriaPage
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
          .doc('politica')
          .get();

      if (doc.exists) {
        // Mapeando os campos conforme a estrutura da coleção institucional
        _tituloController.text =
            doc.data()?['titulo'] ?? 'Política de Privacidade';
        _conteudoController.text = doc.data()?['conteudo'] ?? '';
      }
    } catch (e) {
      debugPrint("Erro ao carregar política: $e");
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _salvar() async {
    setState(() => _carregando = true);
    try {
      // Salvando como texto simples (String), eliminando o JSON do Quill
      await FirebaseFirestore.instance
          .collection('institucional')
          .doc('politica')
          .set({
            'titulo': _tituloController.text,
            'conteudo': _conteudoController.text,
            'ultima_atualizacao': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Política de Privacidade salva com sucesso!"),
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
        title: const Text("Ajustar Política de Privacidade"),
        backgroundColor: TemaAdmin.corAdminEditor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Campo de Título padrão
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: "Título da Página",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Campo de Conteúdo em texto puro (estilo Nossa História)
            TextField(
              controller: _conteudoController,
              maxLines:
                  20, // Aumentado para facilitar textos longos de política
              decoration: const InputDecoration(
                labelText: "Texto da Política",
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            // Botão de salvar no padrão visual da EditarHistoriaPage
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
