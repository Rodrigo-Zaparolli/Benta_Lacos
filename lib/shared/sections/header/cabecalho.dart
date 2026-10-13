import 'package:benta_lacos/core/config/store_environment.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../domain/providers/cart_provider.dart';
import '../../../pages/cliente/cart/cart_screen.dart';
import '../../theme/tema_site.dart';

class Cabecalho extends StatefulWidget {
  const Cabecalho({super.key});
  @override
  State<Cabecalho> createState() => _CabecalhoState();
}

class _CabecalhoState extends State<Cabecalho> {
  final _search = TextEditingController();
  static const _categories = ['Laços', 'Tiaras', 'Presilhas', 'Kits', 'Faixas'];
  bool _menuOpen = false;
  void _searchProducts() {
    final term = _search.text.trim();
    if (term.isNotEmpty)
      Navigator.pushNamed(
        context,
        Uri(path: '/busca', queryParameters: {'q': term}).toString(),
      );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _searchField() => TextField(
    controller: _search,
    textInputAction: TextInputAction.search,
    onSubmitted: (_) => _searchProducts(),
    decoration: InputDecoration(
      hintText: 'Encontre seu acessório favorito',
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      suffixIcon: IconButton(
        tooltip: 'Pesquisar produtos',
        onPressed: _searchProducts,
        icon: const Icon(Icons.search),
      ),
    ),
  );
  Widget _logo() => Semantics(
    label: 'Benta Laços, página inicial',
    button: true,
    child: InkWell(
      onTap: () =>
          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/imagens/logo.png',
              height: 56,
              width: 100,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            const Text(
              'Feito à mão',
              style: TextStyle(fontSize: 11, color: TemaSite.corSecundaria),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _actions(User? user) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (user != null)
        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: StoreEnvironment.database
              .collection(StoreEnvironment.collectionName('usuarios'))
              .doc(user.uid)
              .get(),
          builder: (context, snapshot) =>
              snapshot.data?.data()?['tipo'] == 'admin'
              ? IconButton(
                  tooltip: 'Painel administrativo',
                  onPressed: () => Navigator.pushNamed(context, '/admin'),
                  icon: const Icon(Icons.settings_outlined),
                )
              : const SizedBox.shrink(),
        ),
      if (user == null)
        IconButton(
          tooltip: 'Entrar na minha conta',
          onPressed: () => Navigator.pushNamed(context, '/login'),
          icon: const Icon(Icons.person_outline),
        )
      else
        PopupMenuButton<String>(
          tooltip: 'Minha conta',
          icon: const Icon(Icons.person_outline),
          onSelected: (action) async {
            if (action == 'sair') {
              await FirebaseAuth.instance.signOut();
              if (context.mounted)
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            } else {
              Navigator.pushNamed(context, action);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: '/minha-conta', child: Text('Minha conta')),
            PopupMenuItem(value: '/meus-pedidos', child: Text('Meus pedidos')),
            PopupMenuItem(value: 'sair', child: Text('Sair da conta')),
          ],
        ),
      Consumer<CartProvider>(
        builder: (context, cart, _) => IconButton(
          tooltip: 'Carrinho com ${cart.itemCount} itens',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
          icon: Badge(
            isLabelVisible: cart.itemCount > 0,
            label: Text('${cart.itemCount}'),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
        ),
      ),
    ],
  );
  Widget _category(String title) => TextButton(
    onPressed: () => Navigator.pushNamed(
      context,
      '/categoria/${Uri.encodeComponent(title)}',
    ),
    child: Text(
      title,
      style: const TextStyle(
        color: TemaSite.corSecundaria,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    initialData: FirebaseAuth.instance.currentUser,
    builder: (context, snapshot) => LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Material(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFFF7E9E9),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: const Text(
                  'Feito à mão, com carinho em cada detalhe',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: TemaSite.corSecundaria),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 32,
                      vertical: 12,
                    ),
                    child: compact
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Categorias',
                                    onPressed: () =>
                                        setState(() => _menuOpen = !_menuOpen),
                                    icon: Icon(
                                      _menuOpen ? Icons.close : Icons.menu,
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: _logo(),
                                    ),
                                  ),
                                  _actions(snapshot.data),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _searchField(),
                            ],
                          )
                        : Row(
                            children: [
                              _logo(),
                              const SizedBox(width: 40),
                              Expanded(child: _searchField()),
                              const SizedBox(width: 32),
                              _actions(snapshot.data),
                            ],
                          ),
                  ),
                ),
              ),
              if (!compact || _menuOpen)
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFF1E9E3)),
                      bottom: BorderSide(color: Color(0xFFF1E9E3)),
                    ),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: compact ? 8 : 40,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/colecao'),
                        child: const Text('Todos os produtos'),
                      ),
                      ..._categories.map(_category),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class CarrinhoIcon extends StatelessWidget {
  final int quantidade;
  final VoidCallback? onTap;
  const CarrinhoIcon({super.key, this.quantidade = 0, this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Carrinho',
    onPressed: onTap,
    icon: Badge(
      isLabelVisible: quantidade > 0,
      label: Text('$quantidade'),
      child: const Icon(Icons.shopping_bag_outlined),
    ),
  );
}
