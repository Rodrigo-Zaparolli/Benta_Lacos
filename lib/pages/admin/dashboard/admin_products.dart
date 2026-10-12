import 'package:flutter/material.dart';
import '../../../core/pdf/admin_inventory_pdf.dart';
import '../../../domain/models/product_model.dart';
import '../../../domain/repository/product_repository.dart';
import '../../../shared/utils/store_format.dart';
import '../../../shared/widgets/product_form.dart';
import '../widgets/admin_ui.dart';
import '../widgets/admin_catalog_summary.dart';
import '../widgets/admin_actions.dart';

class AdminProducts extends StatefulWidget {
  final bool stock;
  const AdminProducts({super.key, this.stock = false});
  @override
  State<AdminProducts> createState() => _AdminProductsState();
}

class _AdminProductsState extends State<AdminProducts> {
  final _repo = ProductRepository.instance;
  String _search = '', _category = 'Todas', _filter = 'Ativos';
  int _page = 0;
  bool _busy = false;
  Future<void> _export(List<Product> products) async {
    setState(() => _busy = true);
    try {
      await AdminInventoryPdf.export(
        products,
        filters:
            'Categoria: ' +
            _category +
            ' • ' +
            _filter +
            ' • Busca: ' +
            _search,
      );
    } catch (_) {
      if (mounted)
        adminMessage(
          context,
          'Não foi possível gerar o inventário. Tente novamente.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([Product? p]) async {
    final saved = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 760,
            maxHeight: MediaQuery.sizeOf(c).height - 48,
          ),
          child: ProductForm(
            product: p,
            onSave: (next) => p == null
                ? _repo.addProduct(next)
                : _repo.updateProduct(next, original: p),
          ),
        ),
      ),
    );
    if (saved == true && mounted) adminMessage(context, 'Produto salvo.');
  }

  Future<void> _archive(Product p) async {
    if (!await adminConfirm(
      context,
      p.isArchived ? 'Restaurar produto?' : 'Arquivar ${p.name}?',
      p.isArchived
          ? 'O produto voltará ao catálogo.'
          : 'O produto sairá do catálogo. Seus dados e pedidos anteriores serão preservados.',
    ))
      return;
    await _run(
      () => _repo.setArchived(p.id, !p.isArchived),
      'Produto ${p.isArchived ? 'restaurado' : 'arquivado'}.',
    );
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) adminMessage(context, success);
    } catch (e) {
      if (mounted) adminMessage(context, 'Não foi possível salvar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stock(Product p) async {
    final quantity = TextEditingController(text: '${p.quantity}'),
        reason = TextEditingController();
    final key = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Ajustar estoque: ${p.name}'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade total disponível',
                  ),
                  validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0
                      ? 'Informe um número inteiro positivo ou zero.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reason,
                  decoration: const InputDecoration(
                    labelText: 'Motivo do ajuste',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Informe o motivo.' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Salvar ajuste'),
          ),
        ],
      ),
    );
    if (result == true)
      await _run(
        () => _repo.adjustStock(
          p.id,
          int.parse(quantity.text),
          reason.text,
          expectedQuantity: p.quantity,
        ),
        'Estoque atualizado.',
      );
    quantity.dispose();
    reason.dispose();
  }

  Widget _actions(Product p) => Wrap(
    children: [
      IconButton(
        tooltip: widget.stock ? 'Ajustar estoque' : 'Editar produto',
        onPressed: _busy ? null : () => widget.stock ? _stock(p) : _edit(p),
        icon: Icon(
          widget.stock ? Icons.inventory_2_outlined : Icons.edit_outlined,
        ),
      ),
      IconButton(
        tooltip: 'Histórico',
        onPressed: () => showProductHistory(context, p.id),
        icon: const Icon(Icons.history),
      ),
      if (!widget.stock)
        IconButton(
          tooltip: p.isArchived ? 'Restaurar' : 'Arquivar',
          onPressed: _busy ? null : () => _archive(p),
          icon: Icon(
            p.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
          ),
        ),
    ],
  );
  Widget _photo(Product p) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 44,
      height: 44,
      child: p.imageUrl == null || p.imageUrl!.isEmpty
          ? const Icon(Icons.image_outlined)
          : Image.network(
              p.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined),
            ),
    ),
  );
  String _status(Product p) => p.isArchived
      ? 'Arquivado'
      : p.quantity == 0
      ? 'Sem estoque'
      : p.quantity <= 5
      ? 'Estoque baixo'
      : 'Disponível';
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _repo,
    builder: (context, _) {
      final categories = {
        'Todas',
        ..._repo.allProducts.map((p) => p.category ?? 'Sem categoria'),
      }.toList();
      if (!categories.contains(_category)) _category = 'Todas';
      final products =
          _repo.allProducts
              .where(
                (p) =>
                    normalizeSearch(
                      '${p.name} ${p.color} ${p.id}',
                    ).contains(normalizeSearch(_search)) &&
                    (_category == 'Todas' ||
                        p.category == _category ||
                        (_category == 'Sem categoria' && p.category == null)) &&
                    (_filter == 'Arquivados' ? p.isArchived : !p.isArchived) &&
                    (_filter != 'Destaques' || p.isFeatured) &&
                    (_filter != 'Sem estoque' || p.quantity == 0) &&
                    (_filter != 'Estoque baixo' ||
                        p.quantity > 0 && p.quantity <= 5),
              )
              .toList()
            ..sort(
              (a, b) => widget.stock
                  ? a.quantity.compareTo(b.quantity)
                  : a.name.compareTo(b.name),
            );
      final pages = (products.length / 20).ceil();
      final page = _page.clamp(0, pages > 0 ? pages - 1 : 0);
      final visible = products.skip(page * 20).take(20).toList();
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AdminHeading(
            widget.stock ? 'Estoque' : 'Produtos',
            widget.stock
                ? 'Controle as quantidades e registre o motivo de cada ajuste. Estoque baixo: até 5 unidades.'
                : 'Organize o catálogo, as imagens e os produtos em destaque.',
            action: widget.stock
                ? null
                : FilledButton.icon(
                    onPressed: _busy ? null : () => _edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo produto'),
                  ),
          ),
          AdminCatalogSummary(
            products: _repo.allProducts,
            stock: widget.stock,
            unavailable: _repo.isLoading || _repo.error != null,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar produto',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() {
                    _search = v;
                    _page = 0;
                  }),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: categories
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _category = v!;
                    _page = 0;
                  }),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _filter,
                  decoration: const InputDecoration(
                    labelText: 'Disponibilidade',
                  ),
                  items:
                      [
                            'Ativos',
                            'Destaques',
                            'Sem estoque',
                            'Estoque baixo',
                            'Arquivados',
                          ]
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() {
                    _filter = v!;
                    _page = 0;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.stock)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _busy || _repo.isLoading || _repo.error != null
                    ? null
                    : () => _export(products),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_busy ? 'Gerando PDF...' : 'Exportar inventário'),
              ),
            ),
          if (_busy) const LinearProgressIndicator(),
          if (_repo.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_repo.error != null)
            AdminEmpty(_repo.error!, retry: _repo.reload)
          else if (visible.isEmpty)
            const AdminEmpty(
              'Nenhum produto encontrado para os filtros selecionados.',
            )
          else
            LayoutBuilder(
              builder: (context, c) => c.maxWidth >= 800
                  ? Card(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Produto')),
                            DataColumn(label: Text('Categoria')),
                            DataColumn(label: Text('Preço')),
                            DataColumn(label: Text('Estoque')),
                            DataColumn(label: Text('Situação')),
                            DataColumn(label: Text('Ações')),
                          ],
                          rows: visible
                              .map(
                                (p) => DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: 230,
                                        child: Row(
                                          children: [
                                            _photo(p),
                                            const SizedBox(width: 10),
                                            Expanded(child: Text(p.name)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${p.category ?? 'Sem categoria'}${p.isFeatured ? ' • Destaque' : ''}',
                                      ),
                                    ),
                                    DataCell(Text(formatMoney(p.price))),
                                    DataCell(Text('${p.quantity}')),
                                    DataCell(AdminStatus(_status(p))),
                                    DataCell(_actions(p)),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    )
                  : Column(
                      children: visible
                          .map(
                            (p) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${p.category ?? 'Sem categoria'} • ${formatMoney(p.price)} • ${p.quantity} un.',
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 12,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        AdminStatus(_status(p)),
                                        _actions(p),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: page > 0
                    ? () => setState(() => _page = page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${products.length} produtos • ${pages == 0 ? 0 : page + 1}/$pages',
              ),
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
  );
}
