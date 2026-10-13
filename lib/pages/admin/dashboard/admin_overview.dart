import 'package:benta_lacos/core/config/store_environment.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../pedidos/admin_order_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/services/admin_metrics.dart';
import '../../../domain/repository/product_repository.dart';
import '../../../domain/models/product_model.dart';
import '../../../shared/utils/store_format.dart';
import '../widgets/admin_ui.dart';
import '../pedidos/gestao_pedidos_page.dart';

class AdminOverview extends StatefulWidget {
  final ValueChanged<int> onOpen;
  final ValueChanged<String>? onOpenOrders;
  const AdminOverview({super.key, required this.onOpen, this.onOpenOrders});
  @override
  State<AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<AdminOverview> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  @override
  void initState() {
    super.initState();
    _stream = StoreEnvironment.database
        .collection(StoreEnvironment.collectionName('pedidos'))
        .snapshots();
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, s) {
          if (s.hasError)
            return Center(
              child: AdminEmpty(
                'Não foi possível carregar a visão geral.',
                retry: () => setState(
                  () => _stream = StoreEnvironment.database
                      .collection(StoreEnvironment.collectionName('pedidos'))
                      .snapshots(),
                ),
              ),
            );
          if (!s.hasData)
            return const Center(child: CircularProgressIndicator());
          return AnimatedBuilder(
            animation: ProductRepository.instance,
            builder: (context, _) => AdminOverviewContent(
              orders: s.data!.docs
                  .map((d) => {...d.data(), 'pedidoId': d.id})
                  .toList(),
              products: ProductRepository.instance.products,
              onOpen: widget.onOpen,
              onOpenOrders: widget.onOpenOrders,
              productError: ProductRepository.instance.error,
              productsLoading: ProductRepository.instance.isLoading,
            ),
          );
        },
      );
}

class AdminOverviewContent extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final List<Product> products;
  final ValueChanged<int> onOpen;
  final ValueChanged<String>? onOpenOrders;
  final String? productError;
  final bool productsLoading;
  const AdminOverviewContent({
    super.key,
    required this.orders,
    required this.products,
    required this.onOpen,
    this.onOpenOrders,
    this.productError,
    this.productsLoading = false,
  });
  void _orders(String status) {
    if (onOpenOrders != null) {
      onOpenOrders!(status);
    } else {
      onOpen(1);
    }
  }

  Widget _chart(DateTime now) {
    final first = DateTime(now.year, now.month, now.day - 13);
    final metrics = AdminMetrics.fromOrders(orders, start: first, end: now);
    if (metrics.confirmed.isEmpty)
      return const SizedBox(
        height: 220,
        child: Center(
          child: AdminEmpty(
            'As vendas confirmadas dos últimos 14 dias aparecerão aqui.',
          ),
        ),
      );
    final days = List.generate(
      14,
      (i) => DateTime(first.year, first.month, first.day + i),
    );
    final values = days.map((d) => metrics.daily[d] ?? 0.0).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 13,
          minY: 0,
          maxY: max == 0 ? 1 : max * 1.25,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AdminStyle.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 3,
                reservedSize: 28,
                getTitlesWidget: (v, m) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    v.toInt() >= 0 && v.toInt() < days.length
                        ? DateFormat('dd/MM').format(days[v.toInt()])
                        : '',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AdminStyle.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      '${DateFormat('dd/MM').format(days[s.x.toInt()])}\n${formatMoney(s.y)}',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(14, (i) => FlSpot(i.toDouble(), values[i])),
              isCurved: false,
              color: AdminStyle.rose,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AdminStyle.rose.withValues(alpha: .13),
                    AdminStyle.rose.withValues(alpha: .01),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pipeline(List<Map<String, dynamic>> active) {
    const stages = ['Pendente', 'Aceito', 'Fabricado', 'Enviado', 'Entregue'];
    final counts = {
      for (final s in stages) s: active.where((o) => o['status'] == s).length,
    };
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    return Column(
      children: [
        for (final s in stages)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _orders(s),
              child: Column(
                children: [
                  Row(
                    children: [
                      AdminStatus(s),
                      const Spacer(),
                      Text(
                        '${counts[s]}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: total == 0 ? 0 : counts[s]! / total,
                      backgroundColor: AdminStyle.background,
                      color: s == 'Pendente'
                          ? AdminStyle.amber
                          : s == 'Enviado'
                          ? AdminStyle.blue
                          : AdminStyle.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final metrics = AdminMetrics.fromOrders(
      orders,
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    final active = orders
        .where((o) => o['arquivado'] != true && o['status'] != 'Excluido')
        .toList();
    final pending = active.where((o) => o['status'] == 'Pendente').length;
    final shipping = active
        .where((o) => ['Pago', 'Fabricado'].contains(o['status']))
        .length;
    final low =
        products
            .where((p) => !p.isArchived && !p.madeToOrder && p.quantity <= 5)
            .toList()
          ..sort((a, b) => a.quantity.compareTo(b.quantity));
    final recent = [...active]
      ..sort(
        (a, b) => (recordDate(b['dataPedido']) ?? DateTime(1970)).compareTo(
          recordDate(a['dataPedido']) ?? DateTime(1970),
        ),
      );
    final open = active
        .where(
          (o) => [
            'Pendente',
            'Aceito',
            'Fabricado',
            'Pago',
            'Enviado',
          ].contains(o['status']),
        )
        .length;
    final chart = AdminPanel(
      title: 'Vendas confirmadas',
      subtitle: 'Últimos 14 dias • valores em reais',
      action: TextButton(
        onPressed: () => onOpen(5),
        child: const Text('Ver relatório', style: TextStyle(fontSize: 11)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatMoney(
              AdminMetrics.fromOrders(
                orders,
                start: DateTime(now.year, now.month, now.day - 13),
                end: now,
              ).revenue,
            ),
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 18),
          _chart(now),
        ],
      ),
    );
    final pipeline = AdminPanel(
      title: 'Fluxo de pedidos',
      subtitle: 'Pedidos ativos, em todas as datas',
      child: _pipeline(active),
    );
    final stock = AdminPanel(
      title: 'Prioridades do estoque',
      subtitle: 'Reposição em produtos com até 5 unidades',
      action: TextButton(
        onPressed: () => onOpen(3),
        child: const Text('Abrir estoque', style: TextStyle(fontSize: 11)),
      ),
      child: productError != null
          ? AdminEmpty(productError!, retry: ProductRepository.instance.reload)
          : productsLoading
          ? const Center(child: CircularProgressIndicator())
          : low.isEmpty
          ? const AdminEmpty('Tudo certo. Nenhum produto precisa de reposição.')
          : Column(
              children: low
                  .take(4)
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        onTap: () => onOpen(3),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AdminStyle.background,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 18,
                                color: AdminStyle.muted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.category ?? 'Sem categoria',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AdminStyle.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${p.quantity} un.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: p.quantity == 0
                                    ? const Color(0xFFB64D58)
                                    : AdminStyle.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
    return ListView(
      padding: const EdgeInsets.all(26),
      children: [
        AdminHeading(
          'Visão geral',
          'Tudo o que importa para cuidar da sua loja, em um só lugar.',
          action: OutlinedButton.icon(
            onPressed: () => onOpen(5),
            icon: const Icon(Icons.insights_outlined, size: 17),
            label: const Text('Ver resultados', style: TextStyle(fontSize: 11)),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF6E7EE), Color(0xFFF1ECF7)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, c) => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seu dia, bem organizado.',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        open == 0
                            ? 'Os próximos pedidos aparecerão aqui. Aproveite para cuidar do catálogo.'
                            : 'Você tem $open ${open == 1 ? 'pedido em atendimento' : 'pedidos em atendimento'}. Confira o que precisa da sua atenção.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AdminStyle.muted,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _orders('Todos'),
                        icon: const Icon(Icons.arrow_forward, size: 15),
                        label: const Text(
                          'Acompanhar pedidos',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                if (c.maxWidth > 650) ...[
                  const SizedBox(width: 30),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 50,
                      color: AdminStyle.rose,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        AdminMetricGrid(
          children: [
            AdminMetric(
              'Vendas no mês',
              formatMoney(metrics.revenue),
              Icons.payments_outlined,
              color: AdminStyle.green,
              detail:
                  '${metrics.confirmed.length} pedidos confirmados • ${DateFormat('MM/yyyy').format(now)}',
              onTap: () => onOpen(5),
            ),
            AdminMetric(
              'Pedidos pendentes',
              '$pending',
              Icons.schedule,
              color: AdminStyle.amber,
              detail: 'Aguardam atendimento ou pagamento',
              onTap: () => _orders('Pendente'),
            ),
            AdminMetric(
              'Prontos para envio',
              '$shipping',
              Icons.local_shipping_outlined,
              color: AdminStyle.blue,
              detail: 'Pagamento já confirmado',
              onTap: () => _orders('Pago'),
            ),
            AdminMetric(
              'Reposição de estoque',
              productsLoading || productError != null ? '—' : '${low.length}',
              Icons.inventory_2_outlined,
              detail: 'Produtos com até 5 unidades',
              onTap: () => onOpen(3),
            ),
          ],
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 850
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: chart),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: pipeline),
                  ],
                )
              : Column(children: [chart, const SizedBox(height: 20), pipeline]),
        ),
        const SizedBox(height: 22),
        AdminPanel(
          title: 'Pedidos recentes',
          subtitle: 'Últimas solicitações recebidas',
          action: TextButton(
            onPressed: () => _orders('Todos'),
            child: const Text('Ver todos', style: TextStyle(fontSize: 11)),
          ),
          child: AdminOrderList(
            orders: recent.take(5).toList(),
            compact: true,
            onOpen: (id) => openOrderDetails(context, id),
          ),
        ),
        const SizedBox(height: 22),
        stock,
        const SizedBox(height: 12),
        const Text(
          'Valores confirmados consideram a data de criação do pedido e incluem frete registrado.',
          style: TextStyle(fontSize: 10, color: AdminStyle.muted),
        ),
      ],
    );
  }
}
