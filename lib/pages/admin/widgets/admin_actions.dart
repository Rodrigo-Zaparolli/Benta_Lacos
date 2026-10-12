import 'package:benta_lacos/core/config/store_environment.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../domain/services/admin_metrics.dart';

Future<bool> adminConfirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ??
    false;

void adminMessage(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

class AdminHistory extends StatelessWidget {
  final List<dynamic> entries;
  const AdminHistory(this.entries, {super.key});
  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty)
      return const Text(
        'Não há alterações registradas. O histórico começa com as novas operações.',
      );
    final sorted = entries.whereType<Map>().toList()
      ..sort(
        (a, b) => (recordDate(b['data']) ?? DateTime(1970)).compareTo(
          recordDate(a['data']) ?? DateTime(1970),
        ),
      );
    return Column(
      children: sorted.map((e) {
        final date = recordDate(e['data']);
        final details = e['detalhes'] as Map?;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history),
          title: Text('${e['acao'] ?? 'Alteração'}'),
          subtitle: Text(
            '${date == null ? '' : DateFormat('dd/MM/yyyy HH:mm').format(date)} • ${e['autor'] ?? 'Administrador'}${details == null ? '' : '\n${details.entries.map((v) => '${v.key}: ${v.value}').join(' • ')}'}',
          ),
        );
      }).toList(),
    );
  }
}

Future<void> showProductHistory(
  BuildContext context,
  String id,
) => showDialog<void>(
  useRootNavigator: false,
  context: context,
  builder: (c) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650, maxHeight: 600),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Histórico do produto',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(c),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: StoreEnvironment.database
                      .collection('produtos')
                      .doc(id)
                      .snapshots(),
                  builder: (context, s) => s.hasError
                      ? const Text('Não foi possível carregar o histórico.')
                      : !s.hasData
                      ? const CircularProgressIndicator()
                      : AdminHistory(
                          s.data!.data()?['historico'] as List? ?? [],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
