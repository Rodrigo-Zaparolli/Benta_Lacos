import 'package:benta_lacos/core/config/store_environment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/pdf/admin_report_pdf.dart';
import '../../../domain/services/admin_metrics.dart';
import '../../../shared/utils/store_format.dart';
import '../widgets/admin_ui.dart';
import '../login/admin_page.dart';

class RelatoriosPage extends StatefulWidget {
  final bool embedded;
  const RelatoriosPage({super.key, this.embedded = false});
  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  DateTimeRange? _range;
  bool _exporting = false;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  @override
  void initState() {
    super.initState();
    _resetStream();
    final now = DateTime.now();
    _range = DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
  }

  void _resetStream() => _stream = StoreEnvironment.database
      .collection(StoreEnvironment.collectionName('pedidos'))
      .snapshots();
  String get _period => _range == null
      ? 'Todo o período'
      : '${DateFormat('dd/MM/yyyy').format(_range!.start)} a ${DateFormat('dd/MM/yyyy').format(_range!.end)}';
  Future<void> _pick() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (range != null && mounted) setState(() => _range = range);
  }

  Future<void> _export(List<Map<String, dynamic>> orders) async {
    setState(() => _exporting = true);
    try {
      await AdminReportPdf.export(orders, period: _period);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível gerar o PDF. Tente novamente.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _panel(String title, Widget child) =>
      AdminPanel(title: title, child: child);
  Widget _distribution(Map<String, num> values, String empty) => values.isEmpty
      ? AdminEmpty(empty)
      : Column(
          children: values.entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.key)),
                      const SizedBox(width: 12),
                      Text(
                        e.value is int
                            ? '${e.value} pedidos'
                            : formatMoney(e.value),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
  Widget _chart(AdminMetrics metrics) {
    final recordedDays = metrics.daily.keys.toList()..sort();
    if (recordedDays.isEmpty)
      return const AdminEmpty('Nenhuma venda confirmada no período.');
    final days = <DateTime>[];
    for (
      var day = recordedDays.first;
      !day.isAfter(recordedDays.last);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      days.add(day);
    }
    if (days.length == 1)
      return ListTile(
        title: Text(DateFormat('dd/MM/yyyy').format(days.first)),
        trailing: Text(formatMoney(metrics.daily[days.first]!)),
      );
    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minY: 0,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(drawVerticalLine: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 50),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (days.length / 4).ceilToDouble().clamp(1, 999),
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    value.toInt() >= 0 && value.toInt() < days.length
                        ? DateFormat('dd/MM').format(days[value.toInt()])
                        : '',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                days.length,
                (i) => FlSpot(i.toDouble(), metrics.daily[days[i]] ?? 0),
              ),
              isCurved: false,
              color: const Color(0xFFB73564),
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0x18B73564),
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.embedded) return const AdminPage(initialSection: 5);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: AdminEmpty(
              'Não foi possível carregar os relatórios.',
              retry: () => setState(_resetStream),
            ),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!.docs
            .map((d) => {...d.data(), 'id': d.id})
            .toList();
        final metrics = AdminMetrics.fromOrders(
          orders,
          start: _range?.start,
          end: _range?.end,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminHeading(
                'Relatórios',
                'Acompanhe os resultados com os mesmos critérios em toda a tela.',
                action: ElevatedButton.icon(
                  onPressed: _exporting ? null : () => _export(metrics.orders),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(_exporting ? 'Gerando PDF...' : 'Exportar PDF'),
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pick,
                    icon: const Icon(Icons.date_range),
                    label: Text(_period),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _range = null),
                    child: const Text('Todo o período'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'O período considera a criação do pedido. Valores confirmados incluem frete informado; cancelados e excluídos não entram nas vendas.',
                style: TextStyle(fontSize: 12, color: Color(0xFF756A65)),
              ),
              const SizedBox(height: 24),
              AdminMetricGrid(
                children: [
                  AdminMetric(
                    'Valores confirmados',
                    formatMoney(metrics.revenue),
                    Icons.payments_outlined,
                  ),
                  AdminMetric(
                    'Pedidos confirmados',
                    '${metrics.confirmed.length}',
                    Icons.check_circle_outline,
                  ),
                  AdminMetric(
                    'Unidades vendidas',
                    '${metrics.units}',
                    Icons.shopping_bag_outlined,
                  ),
                  AdminMetric(
                    'Valores pendentes',
                    formatMoney(metrics.pendingValue),
                    Icons.schedule,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _panel(
                'Valores confirmados por dia de pedido (R\$)',
                _chart(metrics),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, c) {
                  final width = c.maxWidth >= 800
                      ? (c.maxWidth - 20) / 2
                      : c.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      SizedBox(
                        width: width,
                        child: _panel(
                          'Meios em pedidos confirmados',
                          _distribution(
                            metrics.payments,
                            'Nenhum pagamento confirmado.',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _panel(
                          'Preferências em pedidos pendentes',
                          _distribution(
                            metrics.preferences,
                            'Nenhum pedido pendente.',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _panel(
                'Produtos vendidos — unidades',
                metrics.products.isEmpty
                    ? const AdminEmpty('Nenhum produto vendido no período.')
                    : Column(
                        children:
                            (metrics.products.entries.toList()
                                  ..sort((a, b) => b.value.compareTo(a.value)))
                                .map(
                                  (e) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(e.key),
                                    trailing: Text('${e.value} un.'),
                                  ),
                                )
                                .toList(),
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                'Taxas registradas: ${formatMoney(metrics.fees)}. Nenhuma taxa é estimada automaticamente.',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
