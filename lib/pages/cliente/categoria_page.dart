import 'package:flutter/material.dart';
import '../../domain/models/product_model.dart';
import '../../domain/repository/product_repository.dart';
import '../../shared/constants/card.dart';
import '../../shared/utils/store_format.dart';
import '../../shared/widgets/catalog_status.dart';
import '../../shared/sections/header/cabecalho.dart';
import '../../shared/sections/footer/rodape.dart';

class CategoriaPage extends StatefulWidget {
  final String categoriaNome;
  final bool isBusca;
  const CategoriaPage({
    super.key,
    required this.categoriaNome,
    this.isBusca = false,
  });
  @override
  State<CategoriaPage> createState() => _CategoriaPageState();
}

class _CategoriaPageState extends State<CategoriaPage> {
  String _sort = 'Destaques';
  String? _color;
  bool _availableOnly = false;
  List<Product> _baseProducts() {
    final term = normalizeSearch(widget.categoriaNome);
    return ProductRepository.instance.products
        .where(
          (p) => widget.isBusca
              ? normalizeSearch(
                  '${p.name} ${p.description} ${p.category ?? ''} ${p.color}',
                ).contains(term)
              : term.isEmpty || normalizeSearch(p.category ?? '') == term,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          const Cabecalho(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isBusca
                          ? 'Resultados para “${widget.categoriaNome}”'
                          : widget.categoriaNome.isEmpty
                          ? 'Nossa coleção'
                          : widget.categoriaNome,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Encontre o detalhe perfeito para cada momento.',
                    ),
                    const SizedBox(height: 24),
                    ListenableBuilder(
                      listenable: ProductRepository.instance,
                      builder: (context, _) {
                        final repository = ProductRepository.instance;
                        if (repository.isLoading || repository.error != null)
                          return CatalogStatus(repository: repository);
                        final base = _baseProducts();
                        final colors =
                            base
                                .map((p) => p.color.trim())
                                .where((c) => c.isNotEmpty)
                                .toSet()
                                .toList()
                              ..sort();
                        final selectedColor = colors.contains(_color)
                            ? _color
                            : null;
                        final products = base
                            .where(
                              (p) =>
                                  (!_availableOnly || p.available) &&
                                  (selectedColor == null ||
                                      p.color.trim() == selectedColor),
                            )
                            .toList();
                        products.sort((a, b) {
                          if (_sort == 'Novidades')
                            return (b.createdAt ?? DateTime(1970)).compareTo(
                              a.createdAt ?? DateTime(1970),
                            );
                          if (_sort == 'Menor preço')
                            return a.price.compareTo(b.price);
                          if (_sort == 'Maior preço')
                            return b.price.compareTo(a.price);
                          if (_sort == 'Nome A–Z')
                            return a.name.compareTo(b.name);
                          final featured = (b.isFeatured ? 1 : 0).compareTo(
                            a.isFeatured ? 1 : 0,
                          );
                          return featured == 0
                              ? a.name.compareTo(b.name)
                              : featured;
                        });
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                  width: 190,
                                  child: DropdownButtonFormField<String>(
                                    value: _sort,
                                    decoration: const InputDecoration(
                                      labelText: 'Ordenar por',
                                    ),
                                    items:
                                        [
                                              'Destaques',
                                              'Novidades',
                                              'Menor preço',
                                              'Maior preço',
                                              'Nome A–Z',
                                            ]
                                            .map(
                                              (s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(s),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (s) =>
                                        setState(() => _sort = s!),
                                  ),
                                ),
                                if (colors.isNotEmpty)
                                  SizedBox(
                                    width: 190,
                                    child: DropdownButtonFormField<String>(
                                      value: selectedColor ?? '',
                                      decoration: const InputDecoration(
                                        labelText: 'Cor',
                                      ),
                                      items: [
                                        const DropdownMenuItem(
                                          value: '',
                                          child: Text('Todas as cores'),
                                        ),
                                        ...colors.map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(
                                              c,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (s) => setState(
                                        () => _color = s == '' ? null : s,
                                      ),
                                    ),
                                  ),
                                FilterChip(
                                  label: const Text('Disponíveis'),
                                  selected: _availableOnly,
                                  onSelected: (v) =>
                                      setState(() => _availableOnly = v),
                                ),
                                Text('${products.length} produtos'),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (products.isEmpty) ...[
                              CatalogStatus(
                                repository: repository,
                                emptyMessage:
                                    'Nenhum produto encontrado. Experimente outra busca ou remova os filtros.',
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/colecao'),
                                child: const Text('Explorar toda a coleção'),
                              ),
                            ] else
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns = constraints.maxWidth >= 1000
                                      ? 4
                                      : constraints.maxWidth >= 650
                                      ? 3
                                      : constraints.maxWidth >= 340
                                      ? 2
                                      : 1;
                                  final width =
                                      (constraints.maxWidth -
                                          (columns - 1) * 16) /
                                      columns;
                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 24,
                                    children: products
                                        .map(
                                          (p) => SizedBox(
                                            width: width,
                                            child: LacoCard(product: p),
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Rodape(),
        ],
      ),
    ),
  );
}
