import 'package:benta_lacos/core/config/store_environment.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/services/admin_audit.dart';
import '../../../shared/utils/store_format.dart';
import '../widgets/admin_ui.dart';
import '../widgets/admin_actions.dart';

class EditarContatoPage extends StatefulWidget {
  const EditarContatoPage({super.key});
  @override
  State<EditarContatoPage> createState() => _EditarContatoPageState();
}

class _EditarContatoPageState extends State<EditarContatoPage> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController(), _email = TextEditingController();
  bool _loading = true, _saving = false, _loaded = false;
  String? _error;
  Map<String, dynamic> _original = {};
  DocumentReference<Map<String, dynamic>> get _ref =>
      StoreEnvironment.database.collection('institucional').doc('contato');
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
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
      _phone.text = '${_original['whatsapp'] ?? ''}';
      _email.text = '${_original['email'] ?? ''}';
      _loaded = true;
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Não foi possível carregar o contato.');
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
      final proposed = {
        'whatsapp': whatsappPhone(_phone.text),
        'email': _email.text.trim(),
      };
      final patch = {
        for (final e in proposed.entries)
          if (e.value != _original[e.key]) e.key: e.value,
      };
      if (patch.isNotEmpty)
        await StoreEnvironment.database.runTransaction((t) async {
          final current = await t.get(_ref);
          for (final key in patch.keys) {
            if (current.data()?[key] != _original[key])
              throw StateError(
                'O contato mudou em outra sessão. Reabra esta página antes de salvar.',
              );
          }
          t.set(_ref, {
            ...patch,
            'ultima_atualizacao': FieldValue.serverTimestamp(),
            'historico': FieldValue.arrayUnion([
              auditEntry(
                'Contato atualizado',
                details: {'campos': patch.keys.toList()},
              ),
            ]),
          }, SetOptions(merge: true));
        });
      if (mounted) {
        setState(() => _saving = false);
        adminMessage(context, 'Contato atualizado.');
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
      appBar: AppBar(title: const Text('Contato da loja')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_loaded
          ? Center(
              child: AdminEmpty(
                _error ?? 'Contato indisponível.',
                retry: _load,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Estes dados são usados no rodapé e no atendimento dos pedidos.',
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _phone,
                            enabled: !_saving,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp com DDD',
                            ),
                            validator: (v) =>
                                RegExp(
                                  r'^55\d{10,11}$',
                                ).hasMatch(whatsappPhone(v ?? ''))
                                ? null
                                : 'Informe um telefone brasileiro válido com DDD.',
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _email,
                            enabled: !_saving,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-mail comercial',
                            ),
                            validator: (v) =>
                                RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                ).hasMatch((v ?? '').trim())
                                ? null
                                : 'Informe um e-mail válido.',
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
                              _saving ? 'Salvando...' : 'Salvar contato',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}
