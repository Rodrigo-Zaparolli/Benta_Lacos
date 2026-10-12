import 'package:flutter/material.dart';
import '../../../domain/models/product_model.dart';
import '../../../shared/utils/store_format.dart';
import 'admin_ui.dart';

class AdminCatalogSummary extends StatelessWidget {
  final List<Product> products;
  final bool stock, unavailable;
  const AdminCatalogSummary({
    super.key,
    required this.products,
    this.stock = false,
    this.unavailable = false,
  });
  @override
  Widget build(BuildContext context) {
    final active = products.where((p) => !p.isArchived).toList();
    String value(num n) => unavailable ? '—' : '$n';
    return AdminMetricGrid(
      children: stock
          ? [
              AdminMetric(
                'Unidades disponíveis',
                value(active.fold<int>(0, (n, p) => n + p.quantity)),
                Icons.inventory_2_outlined,
                detail: 'Soma de todos os produtos ativos',
                color: AdminStyle.blue,
              ),
              AdminMetric(
                'Produtos esgotados',
                value(active.where((p) => p.quantity == 0).length),
                Icons.production_quantity_limits,
                detail: 'Precisam de reposição',
                color: const Color(0xFFB64D58),
              ),
              AdminMetric(
                'Estoque baixo',
                value(
                  active.where((p) => p.quantity > 0 && p.quantity <= 5).length,
                ),
                Icons.warning_amber_outlined,
                detail: 'Entre 1 e 5 unidades',
                color: AdminStyle.amber,
              ),
              AdminMetric(
                'Valor do estoque',
                unavailable
                    ? '—'
                    : formatMoney(
                        active.fold<double>(
                          0,
                          (n, p) => n + p.price * p.quantity,
                        ),
                      ),
                Icons.sell_outlined,
                detail: 'A preço de venda • não é lucro',
                color: AdminStyle.green,
              ),
            ]
          : [
              AdminMetric(
                'Produtos ativos',
                value(active.length),
                Icons.shopping_bag_outlined,
                detail: 'Visíveis no catálogo',
                color: AdminStyle.blue,
              ),
              AdminMetric(
                'Em destaque',
                value(active.where((p) => p.isFeatured).length),
                Icons.star_outline,
                detail: 'Selecionados para a página inicial',
                color: AdminStyle.rose,
              ),
              AdminMetric(
                'Sem estoque',
                value(active.where((p) => p.quantity == 0).length),
                Icons.inventory_2_outlined,
                detail: 'Indisponíveis para novos pedidos',
                color: AdminStyle.amber,
              ),
              AdminMetric(
                'Arquivados',
                value(products.where((p) => p.isArchived).length),
                Icons.archive_outlined,
                detail: 'Preservados no histórico',
                color: AdminStyle.muted,
              ),
            ],
    );
  }
}
