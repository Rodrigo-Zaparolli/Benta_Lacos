import 'package:flutter/material.dart';
import '../../tema/tema_site.dart';
import '../../repository/product_repository.dart';
import '../../models/product.dart';
import '../../widgets/product_form.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String _categoriaSelecionada = 'Todos';
  String _buscaQuery = '';

  final List<String> _categorias = [
    'Todos',
    'Laços',
    'Tiaras',
    'Presilhas',
    'Kits',
    'Faixas',
  ];

  @override
  void initState() {
    super.initState();
    ProductRepository.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    ProductRepository.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  int _getCountByCategory(List<Product> products, String category) {
    if (category == 'Todos') return products.length;
    return products.where((p) => p.category == category).length;
  }

  double _getValueByCategory(List<Product> products, String category) {
    if (category == 'Todos') {
      return products.fold(0, (sum, item) => sum + item.price);
    }
    return products
        .where((p) => p.category == category)
        .fold(0, (sum, item) => sum + item.price);
  }

  void _openForm(Product? p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductForm(
        product: p,
        onSave: (prod) {
          if (p == null) {
            ProductRepository.instance.addProduct(prod);
          } else {
            ProductRepository.instance.updateProduct(prod);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ProductRepository.instance.products;

    final filteredProducts = allProducts.where((p) {
      final matchesBusca = p.name.toLowerCase().contains(
        _buscaQuery.toLowerCase(),
      );
      final matchesCategoria =
          _categoriaSelecionada == 'Todos' ||
          p.category == _categoriaSelecionada;
      return matchesBusca && matchesCategoria;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Dashboard Benta Laços',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: TemaSite.admin.fonteTituloAppBar,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(TemaSite.admin.pathBackground),
              fit: BoxFit.cover,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // SEÇÃO 1: MÉTRICAS (QUANTIDADES)
          _buildSectionTitle("Estoque (Quantidades)"),
          _buildResponsiveGrid(
            itemCount: _categorias.length,
            builder: (context, index) {
              final cat = _categorias[index];
              final count = _getCountByCategory(allProducts, cat);
              return _buildStatCard(
                cat == 'Todos' ? 'Produtos' : cat,
                count.toString(),
                cat == 'Todos' ? Icons.inventory_2 : Icons.tag,
                cat == 'Todos' ? Colors.blue : TemaSite.corPrimaria,
              );
            },
          ),

          // SEÇÃO 2: MÉTRICAS (FINANCEIRO)
          _buildSectionTitle("Financeiro (R\$)"),
          _buildResponsiveGrid(
            itemCount: _categorias.length,
            builder: (context, index) {
              final cat = _categorias[index];
              final value = _getValueByCategory(allProducts, cat);
              return _buildStatCard(
                cat == 'Todos' ? 'Total' : cat,
                'R\$ ${value.toStringAsFixed(2)}',
                Icons.payments_outlined,
                cat == 'Todos' ? Colors.green : Colors.green.shade400,
              );
            },
          ),

          // --- BARRA DE BUSCA E FILTROS ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) => setState(() => _buscaQuery = value),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar produto...',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: TemaSite.corPrimaria,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categorias.length,
                      itemBuilder: (context, index) {
                        final cat = _categorias[index];
                        final isSelected = _categoriaSelecionada == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: isSelected,
                            selectedColor: TemaSite.corPrimaria,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (_) =>
                                setState(() => _categoriaSelecionada = cat),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- LISTAGEM DE PRODUTOS ---
          filteredProducts.isEmpty
              ? const SliverFillRemaining(
                  child: Center(child: Text('Nenhum item encontrado.')),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _buildProductItem(filteredProducts[i]),
                      childCount: filteredProducts.length,
                    ),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TemaSite.corPrimaria,
        onPressed: () => _openForm(null),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'NOVO PRODUTO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // --- COMPONENTES DE LAYOUT RESPONSIVO ---

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(title, style: TemaSite.admin.styleTituloSecao()),
      ),
    );
  }

  Widget _buildResponsiveGrid({
    required int itemCount,
    required Widget Function(BuildContext, int) builder,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180, // Largura máxima de cada card
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2, // Proporção ideal para layout horizontal
        ),
        delegate: SliverChildBuilderDelegate(builder, childCount: itemCount),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TemaSite.admin.corCardFundo,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LINHA 1: ÍCONE + TÍTULO (HORIZONTAL)
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: TemaSite.admin.fonteCardTitulo,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // LINHA 2: VALOR
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TemaSite.admin.styleCardValor()),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 40,
            height: 40,
            child: p.imageBytes != null
                ? Image.memory(p.imageBytes!, fit: BoxFit.cover)
                : const Icon(Icons.image, color: Colors.grey, size: 20),
          ),
        ),
        title: Text(
          p.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          'R\$ ${p.price.toStringAsFixed(2)} • ${p.category}',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.blue,
                size: 18,
              ),
              onPressed: () => _openForm(p),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Colors.redAccent,
                size: 18,
              ),
              onPressed: () => _confirmDelete(p),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Excluir?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text('Remover "${p.name}" da base de dados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ProductRepository.instance.deleteProduct(p.id);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
