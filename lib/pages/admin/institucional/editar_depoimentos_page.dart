import 'package:benta_lacos/core/config/store_environment.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/services/admin_audit.dart';
import '../widgets/admin_ui.dart';
import '../widgets/admin_actions.dart';

class GestaoDepoimentosPage extends StatefulWidget {
  const GestaoDepoimentosPage({super.key});
  @override
  State<GestaoDepoimentosPage> createState() => _GestaoDepoimentosPageState();
}

class _GestaoDepoimentosPageState extends State<GestaoDepoimentosPage> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  String _filter = 'Pendentes';
  final _busy = <String>{};
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() =>
      _stream = StoreEnvironment.database.collection('depoimentos').snapshots();
  Future<void> _change(String id, {bool? approved, bool? archived}) async {
    if (_busy.contains(id)) return;
    if (archived == true &&
        !await adminConfirm(
          context,
          'Arquivar depoimento?',
          'O depoimento sairá do site e poderá ser restaurado.',
        ))
      return;
    setState(() => _busy.add(id));
    try {
      final ref = StoreEnvironment.database.collection('depoimentos').doc(id);
      await StoreEnvironment.database.runTransaction((t) async {
        final doc = await t.get(ref);
        if (!doc.exists) throw StateError('Depoimento não encontrado.');
        t.update(ref, {
          if (approved != null) 'aprovado': approved,
          if (archived != null) 'arquivado': archived,
          if (archived == true) 'aprovado': false,
          'updatedAt': FieldValue.serverTimestamp(),
          'historico': FieldValue.arrayUnion([
            auditEntry(
              archived == true
                  ? 'Depoimento arquivado'
                  : archived == false
                  ? 'Depoimento restaurado'
                  : approved == true
                  ? 'Depoimento aprovado'
                  : 'Aprovação retirada',
            ),
          ]),
        });
      });
      if (mounted) adminMessage(context, 'Depoimento atualizado.');
    } catch (_) {
      if (mounted)
        adminMessage(
          context,
          'Não foi possível atualizar o depoimento. Tente novamente.',
        );
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Depoimentos')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['Pendentes', 'Aprovados', 'Arquivados']
              .map(
                (v) => ChoiceChip(
                  label: Text(v),
                  selected: _filter == v,
                  onSelected: (_) => setState(() => _filter = v),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _stream,
          builder: (context, s) {
            if (s.hasError)
              return AdminEmpty(
                'Não foi possível carregar os depoimentos.',
                retry: () => setState(_reload),
              );
            if (!s.hasData)
              return const Center(child: CircularProgressIndicator());
            final docs = s.data!.docs.where((d) {
              final o = d.data();
              return _filter == 'Arquivados'
                  ? o['arquivado'] == true
                  : o['arquivado'] != true &&
                        (o['aprovado'] == true) == (_filter == 'Aprovados');
            }).toList();
            if (docs.isEmpty)
              return const AdminEmpty('Nenhum depoimento nesta seleção.');
            return Column(
              children: docs.map((d) {
                final o = d.data();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${o['cliente'] ?? 'Cliente'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('${o['texto'] ?? ''}'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('${o['estrelas'] ?? 0}/5 estrelas'),
                            if (_busy.contains(d.id))
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            if (_filter == 'Arquivados')
                              OutlinedButton(
                                onPressed: _busy.contains(d.id)
                                    ? null
                                    : () => _change(d.id, archived: false),
                                child: const Text('Restaurar como pendente'),
                              )
                            else ...[
                              OutlinedButton(
                                onPressed: _busy.contains(d.id)
                                    ? null
                                    : () => _change(
                                        d.id,
                                        approved: o['aprovado'] != true,
                                      ),
                                child: Text(
                                  o['aprovado'] == true
                                      ? 'Retirar aprovação'
                                      : 'Aprovar',
                                ),
                              ),
                              TextButton(
                                onPressed: _busy.contains(d.id)
                                    ? null
                                    : () => _change(d.id, archived: true),
                                child: const Text('Arquivar'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );
}
