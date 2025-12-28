import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../tema/tema_site.dart';
import '../../repository/product_repository.dart';
import '../../models/product.dart';
import '../../widgets/product_form.dart';
import 'relatorios/relatorios_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String _categoriaSelecionada = 'Todos';
  String _buscaQuery = '';
  bool _isAdmin = false;
  bool _isLoading = true;

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
    _checkAdminAccess();
    // Escuta mudanças no repositório para atualizar a lista automaticamente
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

  /// Verifica se o usuário logado tem perfil 'admin' no Firestore
  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _denyAccess();
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['tipo'] == 'admin') {
        if (mounted) {
          setState(() {
            _isAdmin = true;
            _isLoading = false;
          });
          _verificarAniversariantes();
        }
      } else {
        _denyAccess();
      }
    } catch (e) {
      _denyAccess();
    }
  }

  void _denyAccess() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acesso restrito ao administrador.')),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      });
    }
  }

  /// Busca usuários que fazem aniversário nos próximos 7 dias
  Future<void> _verificarAniversariantes() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .get();
      DateTime hoje = DateTime.now();
      List<Map<String, dynamic>> aniversariantes = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['dataNascimento'] != null) {
          DateTime dataNasc;
          if (data['dataNascimento'] is Timestamp) {
            dataNasc = (data['dataNascimento'] as Timestamp).toDate();
          } else {
            dataNasc = DateFormat("dd/MM/yyyy").parse(data['dataNascimento']);
          }

          DateTime aniversarioEsteAno = DateTime(
            hoje.year,
            dataNasc.month,
            dataNasc.day,
          );
          int diferenca = aniversarioEsteAno
              .difference(DateTime(hoje.year, hoje.month, hoje.day))
              .inDays;

          if (diferenca >= 0 && diferenca <= 7) {
            aniversariantes.add({
              'nome': data['nome'] ?? 'Cliente sem nome',
              'dia': DateFormat('dd/MM').format(dataNasc),
              'falta': diferenca == 0 ? "HOJE!" : "em $diferenca dias",
            });
          }
        }
      }

      if (aniversariantes.isNotEmpty && mounted) {
        _exibirPopUpAniversariantes(aniversariantes);
      }
    } catch (e) {
      debugPrint("Erro ao buscar aniversariantes: $e");
    }
  }

  void _exibirPopUpAniversariantes(List<Map<String, dynamic>> lista) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.cake, color: TemaSite.corPrimaria),
            SizedBox(width: 10),
            Text("Aniversariantes da Semana"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: lista.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = lista[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: TemaSite.corPrimaria.withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    color: TemaSite.corPrimaria,
                    size: 20,
                  ),
                ),
                title: Text(
                  item['nome'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Dia ${item['dia']} - ${item['falta']}"),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "FECHAR",
              style: TextStyle(color: TemaSite.corPrimaria),
            ),
          ),
        ],
      ),
    );
  }

  /// Abre o formulário e aguarda o salvamento para evitar tela em branco
  void _openForm(Product? p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductForm(
        product: p,
        onSave: (prod) async {
          // O processamento ocorre dentro do ProductForm,
          // aqui apenas invocamos o repositório e aguardamos a conclusão.
          if (p == null) {
            await ProductRepository.instance.addProduct(prod);
          } else {
            await ProductRepository.instance.updateProduct(prod);
          }
        },
      ),
    );
  }

  void _confirmDelete(Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir?'),
        content: Text('Deseja remover "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await ProductRepository.instance.deleteProduct(p.id);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: TemaSite.corPrimaria),
        ),
      );
    }

    final allProducts = ProductRepository.instance.products;
    final filteredProducts = allProducts.where((p) {
      final category = p.category ?? 'Sem Categoria';
      final matchesBusca = p.name.toLowerCase().contains(
        _buscaQuery.toLowerCase(),
      );
      final matchesCategoria =
          _categoriaSelecionada == 'Todos' || category == _categoriaSelecionada;
      return matchesBusca && matchesCategoria;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Gerenciamento Benta Laços',
          style: TextStyle(fontSize: TemaSite.admin.fonteTituloAppBar),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(TemaSite.admin.pathBackground),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          _buildBannerRelatorios(),
          _buildSectionTitle("Estoque"),
          _buildCategoryChips(),
          _buildSearchBar(),
          SliverPadding(
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
          'CADASTRAR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProductItem(Product p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
              ? Image.network(
                  p.imageUrl!,
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
        title: Text(
          p.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.category ?? 'Sem Categoria',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'R\$ ${p.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: TemaSite.corPrimaria,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () => _openForm(p),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(p),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 55,
      height: 55,
      color: TemaSite.corPrimaria.withOpacity(0.1),
      child: const Icon(
        Icons.image_outlined,
        color: TemaSite.corPrimaria,
        size: 20,
      ),
    );
  }

  Widget _buildBannerRelatorios() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RelatoriosPage()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [TemaSite.corPrimaria, Color(0xFFF06292)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.white, size: 30),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "Ver Relatórios de Vendas",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categorias.length,
          itemBuilder: (context, index) {
            final cat = _categorias[index];
            final isSelected = _categoriaSelecionada == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                selectedColor: TemaSite.corPrimaria,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
                onSelected: (v) => setState(() => _categoriaSelecionada = cat),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          onChanged: (v) => setState(() => _buscaQuery = v),
          decoration: InputDecoration(
            hintText: "Buscar laço...",
            prefixIcon: const Icon(Icons.search),
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: Text(title, style: TemaSite.admin.styleTituloSecao()),
      ),
    );
  }
}
