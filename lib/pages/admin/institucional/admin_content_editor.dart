import 'package:benta_lacos/core/config/store_environment.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/services/admin_audit.dart';
import '../widgets/admin_ui.dart';
import '../widgets/admin_actions.dart';

class AdminContentEditor extends StatefulWidget {
  final String documentId, title;
  final bool imageSettings;
  const AdminContentEditor({
    super.key,
    required this.documentId,
    required this.title,
    this.imageSettings = false,
  });
  @override
  State<AdminContentEditor> createState() => _AdminContentEditorState();
}

class _AdminContentEditorState extends State<AdminContentEditor> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _body = TextEditingController(),
      _image = TextEditingController(),
      _width = TextEditingController();
  Map<String, dynamic> _original = {};
  bool _loading = true, _saving = false, _loaded = false;
  String? _error;
  DocumentReference<Map<String, dynamic>> get _ref => StoreEnvironment.database
      .collection('institucional')
      .doc(widget.documentId);
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_title, _body, _image, _width]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await _ref.get();
      if (!mounted) return;
      _original = doc.data() ?? {};
      _title.text = '${_original['titulo'] ?? widget.title}';
      _body.text = '${_original['conteudo'] ?? ''}';
      _image.text = '${_original['urlImagem'] ?? ''}';
      _loaded = true;
      _width.text = '${_original['larguraImagem'] ?? 350}';
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Não foi possível carregar o conteúdo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final proposed = <String, dynamic>{
        'titulo': _title.text.trim(),
        'conteudo': _body.text.trim(),
        if (widget.imageSettings) 'urlImagem': _image.text.trim(),
        if (widget.imageSettings)
          'larguraImagem': double.parse(_width.text.replaceAll(',', '.')),
      };
      final patch = <String, dynamic>{
        for (final e in proposed.entries)
          if (e.value != _original[e.key]) e.key: e.value,
      };
      if (patch.isNotEmpty)
        await StoreEnvironment.database.runTransaction((t) async {
          final current = await t.get(_ref);
          for (final key in patch.keys) {
            if (current.data()?[key] != _original[key])
              throw StateError(
                'O conteúdo mudou em outra sessão. Volte e reabra esta página antes de salvar.',
              );
          }
          t.set(_ref, {
            ...patch,
            'ultima_atualizacao': FieldValue.serverTimestamp(),
            'historico': FieldValue.arrayUnion([
              auditEntry(
                'Conteúdo atualizado',
                details: {
                  'pagina': widget.documentId,
                  'campos': patch.keys.toList(),
                },
              ),
            ]),
          }, SetOptions(merge: true));
        });
      if (mounted) {
        setState(() => _saving = false);
        adminMessage(context, 'Conteúdo salvo.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is StateError
              ? e.message
              : 'Não foi possível salvar. Verifique sua conexão e tente novamente.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_loaded
          ? Center(
              child: AdminEmpty(
                _error ?? 'Conteúdo indisponível.',
                retry: _load,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _title,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                            labelText: 'Título da página',
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Informe o título.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        if (widget.imageSettings) ...[
                          TextFormField(
                            controller: _image,
                            enabled: !_saving,
                            decoration: const InputDecoration(
                              labelText: 'URL da imagem (opcional)',
                            ),
                            validator: (v) {
                              if ((v ?? '').trim().isEmpty) return null;
                              final uri = Uri.tryParse(v!.trim());
                              return uri != null &&
                                      ['https', 'http'].contains(uri.scheme) &&
                                      uri.host.isNotEmpty
                                  ? null
                                  : 'Informe uma URL válida.';
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _width,
                            enabled: !_saving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Largura da imagem em pixels',
                            ),
                            validator: (v) {
                              final n = double.tryParse(
                                (v ?? '').replaceAll(',', '.'),
                              );
                              return n == null || !n.isFinite || n <= 0
                                  ? 'Informe uma largura positiva.'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                        TextFormField(
                          controller: _body,
                          enabled: !_saving,
                          minLines: 12,
                          maxLines: 24,
                          decoration: const InputDecoration(
                            labelText: 'Conteúdo',
                            alignLabelWithHint: true,
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Informe o conteúdo da página.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(
                            _saving ? 'Salvando...' : 'Salvar conteúdo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    ),
  );
}
