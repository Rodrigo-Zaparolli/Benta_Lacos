import 'package:benta_lacos/pages/admin/institucional/editar_oque_faco_page.dart';
import 'package:benta_lacos/pages/admin/institucional/editar_politica_page.dart';
import 'package:benta_lacos/pages/admin/institucional/editar_quem_sou_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORTAÇÕES DAS SUBPÁGINAS ---
import 'package:benta_lacos/pages/admin/institucional/editar_depoimentos_page.dart';
import 'package:benta_lacos/pages/admin/institucional/editar_historia_page.dart';
import 'package:benta_lacos/pages/admin/institucional/editar_contato_page.dart';
import 'package:benta_lacos/pages/admin/relatorios/relatorios_page.dart';
import 'package:benta_lacos/pages/admin/institucional/editar_trocas_devolucoes_page.dart';
import 'package:benta_lacos/pages/admin/institucional/editar_envio_entrega_page.dart';
import 'package:benta_lacos/pages/admin/institucional/editar_duvidas_page.dart';
import 'package:benta_lacos/pages/admin/pedidos/gestao_pedidos_page.dart';

// --- TEMA E COMPONENTES ---
import '../../../shared/theme/tema_site.dart';
import '../../../domain/repository/product_repository.dart';
import 'package:benta_lacos/domain/models/product_model.dart';
import '../../../shared/widgets/product_form.dart';

class AdminPage extends StatefulWidget {
  final bool isSplitView;
  const AdminPage({super.key, this.isSplitView = false});

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
        if (mounted)
          setState(() {
            _isAdmin = true;
            _isLoading = false;
          });
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Acesso restrito.')));
        Navigator.of(context).pushReplacementNamed('/home');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final filteredProducts = ProductRepository.instance.products.where((p) {
      final matchesBusca = p.name.toLowerCase().contains(
        _buscaQuery.toLowerCase(),
      );
      final matchesCat =
          _categoriaSelecionada == 'Todos' ||
          p.category == _categoriaSelecionada;
      return matchesBusca && matchesCat;
    }).toList();

    double larguraTela = MediaQuery.of(context).size.width;
    int colunasGrid = larguraTela > 1100 ? 3 : (larguraTela > 700 ? 2 : 1);

    return Scaffold(
      backgroundColor: TemaAdmin.corBackgroundAdmin,
      appBar: widget.isSplitView
          ? null
          : AppBar(
              title: const Text('Painel Administrativo'),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(TemaAdmin.admin.pathBackground),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
      body: CustomScrollView(
        slivers: [
          // --- GESTÃO DE CONTEÚDO (Botões largos e quase juntos) ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    " Gestão de Conteúdo",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Define quantos botões por linha baseado na largura
                      int itensPorLinha = constraints.maxWidth > 1000
                          ? 11
                          : (constraints.maxWidth > 600 ? 3 : 2);
                      double espacamento = 4.0; // Espaço bem pequeno entre eles
                      double larguraBotao =
                          (constraints.maxWidth -
                              (espacamento * (itensPorLinha - 1))) /
                          itensPorLinha;

                      return Wrap(
                        spacing: espacamento,
                        runSpacing: espacamento,
                        children: [
                          _buildWideActionButton(
                            context,
                            "Relatórios",
                            Icons.analytics,
                            TemaAdmin.ContainerOne,
                            const RelatoriosPage(),
                            larguraBotao,
                          ),
                          _buildWideActionButton(
                            context,
                            "Pedidos",
                            Icons.shopping_cart,
                            TemaAdmin.ContainerNine,
                            const GestaoPedidosPage(),
                            larguraBotao,
                          ),
                          _buildWideActionButton(
                            context,
                            "Depoimentos",
                            Icons.message,
                            TemaAdmin.ContainerTwo,
                            const GestaoDepoimentosPage(),
                            larguraBotao,
                          ),
                          _buildWideActionButton(
                            context,
                            "História",
                            Icons.book,
                            TemaAdmin.ContainerThree,
                            const EditarHistoriaPage(),
                            larguraBotao,
                          ),

                          _buildWideActionButton(
                            context,
                            "Quem Sou",
                            Icons.book,
                            TemaAdmin.ContainerTen,
                            const EditarQuemSouPage(),
                            larguraBotao,
                          ),

                          _buildWideActionButton(
                            context,
                            "Oque Faço",
                            Icons.book,
                            TemaAdmin.ContainerEleven,
                            const EditarOQueFacoPage(),
                            larguraBotao,
                          ),

                          _buildWideActionButton(
                            context,
                            "Contatos",
                            Icons.phone,
                            TemaAdmin.ContainerFour,
                            const EditarContatoPage(),
                            larguraBotao,
                          ),
                          _buildWideActionButton(
                            context,
                            "Dúvidas",
                            Icons.help_outline,
                            TemaAdmin.ContainerFive,
                            const EditarDuvidasPage(),
                            larguraBotao,
                          ),
                          _buildWideActionButton(
                            context,
                            "Trocas",
                            Icons.swap_horiz,
                            TemaAdmin.ContainerSix,
                            const EditarTrocasDevolucoesPage(),
                            larguraBotao,
                          ),
                          _buildWideActionButton(
                            context,
                            "Envio",
                            Icons.local_shipping,
                            TemaAdmin.ContainerSeven,
                            const EditarEnvioEntregaPage(),
                            larguraBotao,
                          ),
                          _buildWideActionButton(
                            context,
                            "Políticas",
                            Icons.gavel,
                            TemaAdmin.ContainerEight,
                            const EditarPoliticaPage(),
                            larguraBotao,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // --- ESTOQUE DE PRODUTOS ---
          _buildHeaderSliver("Estoque de Produtos"),
          _buildSearchBarSliver(),
          _buildFiltersSliver(),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: colunasGrid,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildProductCard(filteredProducts[i]),
                childCount: filteredProducts.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TemaAdmin.onAdminEditor,
        onPressed: () => _openForm(null),
        label: const Text(
          "ADICIONAR PRODUTO",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Novo Widget de Botão Largo
  Widget _buildWideActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color cor,
    Widget dest,
    double width,
  ) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => dest)),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(
            4,
          ), // Bordas mais retas para parecerem "quase juntos"
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product p) {
    final bool temImagem = p.imageUrl != null && p.imageUrl!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
              image: temImagem
                  ? DecorationImage(
                      image: NetworkImage(p.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: !temImagem
                ? const Icon(Icons.image_outlined, color: Colors.grey, size: 20)
                : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "R\$ ${p.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: TemaSite.corPrimaria,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue, size: 16),
            onPressed: () => _openForm(p),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
            onPressed: () => _confirmDelete(p),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSliver(String t) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Text(
        t,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );

  Widget _buildFiltersSliver() => SliverToBoxAdapter(
    child: SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categorias.length,
        itemBuilder: (c, i) => Padding(
          padding: const EdgeInsets.only(right: 4),
          child: ChoiceChip(
            label: Text(_categorias[i], style: const TextStyle(fontSize: 10)),
            selected: _categoriaSelecionada == _categorias[i],
            selectedColor: TemaSite.corPrimaria.withOpacity(0.2),
            onSelected: (v) =>
                setState(() => _categoriaSelecionada = _categorias[i]),
          ),
        ),
      ),
    ),
  );

  Widget _buildSearchBarSliver() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: TextField(
        onChanged: (v) => setState(() => _buscaQuery = v),
        decoration: InputDecoration(
          hintText: "Buscar produto...",
          prefixIcon: const Icon(Icons.search, size: 16),
          filled: true,
          fillColor: const Color.fromARGB(255, 240, 240, 240),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ),
  );

  void _openForm(Product? p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TemaAdmin.ContainerEight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProductForm(
        product: p,
        onSave: (prod) async {
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
        title: const Text("Excluir?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Não"),
          ),
          TextButton(
            onPressed: () async {
              await ProductRepository.instance.deleteProduct(p.id);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text(
              "Sim",
              style: TextStyle(color: TemaAdmin.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
