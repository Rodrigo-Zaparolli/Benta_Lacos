import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/services/admin_metrics.dart';
import '../../../shared/utils/store_format.dart';
import '../widgets/admin_ui.dart';

class AdminOrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final ValueChanged<String> onOpen;
  final bool compact;
  const AdminOrderList({
    super.key,
    required this.orders,
    required this.onOpen,
    this.compact = false,
  });
  String _id(Map<String, dynamic> o) => '${o['pedidoId'] ?? o['id'] ?? ''}';
  String _short(Map<String, dynamic> o) {
    final id = _id(o);
    return id.length > 10 ? id.substring(0, 10) : id;
  }

  String _date(Map<String, dynamic> o) {
    final d = recordDate(o['dataPedido'] ?? o['data'] ?? o['dataHora']);
    return d == null ? 'Sem data' : DateFormat('dd/MM/yy • HH:mm').format(d);
  }

  String _next(Map<String, dynamic> o) => switch (o['status']) {
    'Pendente' => 'Aceitar pedido',
    'Aceito' => 'Concluir fabricação',
    'Fabricado' =>
      o['metodoEnvio'] == 'Retirar na loja'
          ? 'Avisar retirada'
          : 'Registrar envio',
    'Pago' => 'Registrar envio',
    'Enviado' => 'Confirmar entrega',
    _ => 'Finalizado',
  };
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      if (orders.isEmpty)
        return const AdminEmpty('Nenhum pedido nesta seleção.');
      if (c.maxWidth < 760)
        return Column(
          children: orders
              .map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AdminStyle.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onOpen(_id(o)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${o['nomeCliente'] ?? 'Cliente'}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: AdminStyle.muted,
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '${o['pedidoTeste'] == true ? 'TESTE • ' : ''}#${_short(o)} • ${_date(o)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AdminStyle.muted,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () => onOpen(_id(o)),
                                  child: Tooltip(
                                    message: 'Abrir pedido para alterar status',
                                    child: AdminStatus(
                                      '${o['status'] ?? 'Pendente'}',
                                    ),
                                  ),
                                ),
                                Text(
                                  formatMoney(o['total'] as num? ?? 0),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (!compact) ...[
                              const SizedBox(height: 12),
                              Text(
                                _next(o),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AdminStyle.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth),
            child: DataTable(
              showCheckboxColumn: false,
              columns: [
                const DataColumn(label: Text('PEDIDO / CLIENTE')),
                const DataColumn(label: Text('DATA')),
                const DataColumn(label: Text('STATUS')),
                const DataColumn(label: Text('TOTAL')),
                if (!compact) const DataColumn(label: Text('PRÓXIMA AÇÃO')),
                const DataColumn(label: Text('')),
              ],
              rows: orders
                  .map(
                    (o) => DataRow(
                      onSelectChanged: (_) => onOpen(_id(o)),
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 190,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${o['nomeCliente'] ?? 'Cliente'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Tooltip(
                                  message: _id(o),
                                  child: Text(
                                    '${o['pedidoTeste'] == true ? 'TESTE • ' : ''}#${_short(o)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AdminStyle.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _date(o),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AdminStyle.muted,
                            ),
                          ),
                        ),
                        DataCell(
                          Tooltip(
                            message: 'Abrir pedido para alterar status',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AdminStatus('${o['status'] ?? 'Pendente'}'),
                                const SizedBox(width: 6),
                                const Icon(Icons.edit_outlined, size: 14),
                              ],
                            ),
                          ),
                          onTap: () => onOpen(_id(o)),
                        ),
                        DataCell(
                          Text(
                            formatMoney(o['total'] as num? ?? 0),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!compact)
                          DataCell(
                            Text(
                              _next(o),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AdminStyle.muted,
                              ),
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
    },
  );
}
