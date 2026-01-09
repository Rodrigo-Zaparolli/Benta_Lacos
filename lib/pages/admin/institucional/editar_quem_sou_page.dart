import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/theme/tema_site.dart';

class EditarQuemSouPage extends StatefulWidget {
  const EditarQuemSouPage({super.key});

  @override
  State<EditarQuemSouPage> createState() => _EditarQuemSouPageState();
}

class _EditarQuemSouPageState extends State<EditarQuemSouPage> {
  final _tituloController = TextEditingController();
  final _conteudoController = TextEditingController();
  final _urlImagemController = TextEditingController();
  final _larguraImagemController = TextEditingController();
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
    _urlImagemController.dispose();
    _larguraImagemController.dispose();
    super.dispose();
  }

  void _buscarDados() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('institucional')
          .doc('quem_sou')
          .get();

      if (doc.exists) {
        _tituloController.text = doc['titulo'] ?? '';
        _conteudoController.text = doc['conteudo'] ?? '';
        _urlImagemController.text = doc['urlImagem'] ?? '';
        _larguraImagemController.text = (doc['larguraImagem'] ?? '350')
            .toString();
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _salvar() async {
    setState(() => _carregando = true);
    try {
      await FirebaseFirestore.instance
          .collection('institucional')
          .doc('quem_sou')
          .set({
            'titulo': _tituloController.text,
            'conteudo': _conteudoController.text,
            'urlImagem': _urlImagemController.text,
            'larguraImagem':
                double.tryParse(_larguraImagemController.text) ?? 350.0,
            'ultima_atualizacao': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Conteúdo 'Quem Sou' atualizado com sucesso!"),
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
        title: const Text("Ajustar Quem Sou"),
        backgroundColor: TemaAdmin.corAdminEditor,
        foregroundColor: TemaAdmin.Primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: "Título da Página",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _urlImagemController,
              decoration: const InputDecoration(
                labelText: "URL da Foto/Imagem",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _larguraImagemController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Largura da Imagem (Ex: 350)",
                helperText: "Valor em pixels para telas de computador",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _conteudoController,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: "Biografia / Quem Sou",
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
