import 'package:benta_lacos/core/config/store_environment.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/utils/store_format.dart';
import '../widgets/admin_ui.dart';
import '../pedidos/gestao_pedidos_page.dart';

class AdminClients extends StatefulWidget {
  const AdminClients({super.key});
  @override
  State<AdminClients> createState() => _AdminClientsState();
}

class _AdminClientsState extends State<AdminClients> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  String _search = '';
  int _page = 0;
  @override
  void initState() {
    super.initState();
    _stream = StoreEnvironment.database
        .collection(StoreEnvironment.collectionName('usuarios'))
        .snapshots();
  }

  void _details(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) => showDialog<void>(
    useRootNavigator: false,
    context: context,
    builder: (c) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Cliente e pedidos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(c),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              ...['nome', 'email', 'telefone', 'endereco', 'cep']
                  .where((k) => doc.data()[k] != null)
                  .map(
                    (k) => Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SelectableText('$k: ${doc.data()[k]}'),
                      ),
                    ),
                  ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: StoreEnvironment.database
                      .collection(StoreEnvironment.collectionName('pedidos'))
                      .where('clienteId', isEqualTo: doc.id)
                      .snapshots(),
                  builder: (context, s) {
                    if (s.hasError)
                      return const AdminEmpty(
                        'Não foi possível carregar os pedidos deste cliente.',
                      );
                    if (!s.hasData)
                      return const Center(child: CircularProgressIndicator());
                    if (s.data!.docs.isEmpty)
                      return const AdminEmpty(
                        'Este cliente ainda não tem pedidos.',
                      );
                    return ListView(
                      children: s.data!.docs
                          .map(
                            (d) => ListTile(
                              title: Text('Pedido ${d.id}'),
                              subtitle: Text(
                                '${d.data()['status']} • ${formatMoney((d.data()['total'] as num? ?? 0).toDouble())}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => openOrderDetails(context, d.id),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const AdminHeading(
        'Clientes',
        'Consulte os contatos cadastrados e o histórico de pedidos.',
      ),
      TextField(
        decoration: const InputDecoration(
          labelText: 'Buscar por nome, e-mail ou telefone',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (v) => setState(() {
          _search = v;
          _page = 0;
        }),
      ),
      const SizedBox(height: 24),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, s) {
          if (s.hasError)
            return AdminEmpty(
              'Não foi possível carregar os clientes.',
              retry: () => setState(
                () => _stream = StoreEnvironment.database
                    .collection(StoreEnvironment.collectionName('usuarios'))
                    .snapshots(),
              ),
            );
          if (!s.hasData)
            return const Center(child: CircularProgressIndicator());
          final clients =
              s.data!.docs
                  .where(
                    (d) =>
                        d.data()['tipo'] != 'admin' &&
                        normalizeSearch(
                          '${d.data()['nome']} ${d.data()['email']} ${d.data()['telefone']}',
                        ).contains(normalizeSearch(_search)),
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      '${a.data()['nome']}'.compareTo('${b.data()['nome']}'),
                );
          if (clients.isEmpty)
            return const AdminEmpty('Nenhum cliente encontrado.');
          final pages = (clients.length / 20).ceil();
          final page = _page.clamp(0, pages - 1);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${clients.length} clientes encontrados',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AdminStyle.muted,
                    ),
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, c) {
                  final visible = clients.skip(page * 20).take(20).toList();
                  if (c.maxWidth >= 760)
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: c.maxWidth),
                          child: DataTable(
                            showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('CLIENTE')),
                              DataColumn(label: Text('E-MAIL')),
                              DataColumn(label: Text('TELEFONE')),
                              DataColumn(label: Text('')),
                            ],
                            rows: visible
                                .map(
                                  (d) => DataRow(
                                    onSelectChanged: (_) => _details(d),
                                    cells: [
                                      DataCell(
                                        SizedBox(
                                          width: 220,
                                          child: Row(
                                            children: [
                                              const CircleAvatar(
                                                radius: 17,
                                                backgroundColor: Color(
                                                  0xFFF5E6ED,
                                                ),
                                                child: Icon(
                                                  Icons.person_outline,
                                                  size: 17,
                                                  color: AdminStyle.rose,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  '${d.data()['nome'] ?? 'Cliente sem nome'}',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${d.data()['email'] ?? 'Não informado'}',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${d.data()['telefone'] ?? 'Não informado'}',
                                        ),
                                      ),
                                      const DataCell(
                                        Icon(
                                          Icons.arrow_forward,
                                          size: 16,
                                          color: AdminStyle.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    );
                  return Column(
                    children: visible
                        .map(
                          (d) => Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFF5E6ED),
                                child: Icon(
                                  Icons.person_outline,
                                  color: AdminStyle.rose,
                                ),
                              ),
                              title: Text(
                                '${d.data()['nome'] ?? 'Cliente sem nome'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${d.data()['email'] ?? ''}\n${d.data()['telefone'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AdminStyle.muted,
                                ),
                              ),
                              isThreeLine: true,
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 17,
                              ),
                              onTap: () => _details(d),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: page > 0
                        ? () => setState(() => _page = page - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('${clients.length} clientes • ${page + 1}/$pages'),
                  IconButton(
                    onPressed: page + 1 < pages
                        ? () => setState(() => _page = page + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ],
  );
}
