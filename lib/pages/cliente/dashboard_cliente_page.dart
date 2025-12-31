import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:benta_lacos/domain/providers/cart_provider.dart';
import '../../shared/sections/header/cabecalho.dart';
import '../../shared/sections/footer/rodape.dart';
import '../../shared/widgets/background_fundo.dart';
import 'login_page.dart';

class DashboardClientePage extends StatefulWidget {
  const DashboardClientePage({super.key});

  @override
  State<DashboardClientePage> createState() => _DashboardClientePageState();
}

class _DashboardClientePageState extends State<DashboardClientePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _nomeCompleto = "Carregando...";

  @override
  void initState() {
    super.initState();
    // ⚡ Dispara a inicialização dos dados assim que a tela abre
    _inicializarDados();
  }

  Future<void> _inicializarDados() async {
    final user = _auth.currentUser;

    // Se não houver usuário, redireciona para login imediatamente
    if (user == null) {
      _redirecionarLogin();
      return;
    }

    // 1. Busca o nome no Firestore
    await _carregarNome(user.uid);

    // 2. Sincroniza o carrinho (Garante que os itens apareçam no Header)
    if (mounted) {
      await Provider.of<CartProvider>(
        context,
        listen: false,
      ).sincronizarDoFirestore(user.uid);
    }
  }

  Future<void> _carregarNome(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('usuarios')
          .doc(uid)
          .get();

      if (doc.exists && mounted) {
        final dados = doc.data() as Map<String, dynamic>;

        // 🔹 Verifica diferentes possibilidades de nomes de campos no seu Firestore
        String nome = dados['nome'] ?? dados['nomeCompleto'] ?? '';
        String sobrenome = dados['sobrenome'] ?? '';

        setState(() {
          _nomeCompleto = '$nome $sobrenome'.trim();
          if (_nomeCompleto.isEmpty) _nomeCompleto = "Cliente";
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar nome no Dashboard: $e");
      if (mounted) setState(() => _nomeCompleto = "Cliente");
    }
  }

  void _redirecionarLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Future<void> _executarLogout() async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    // 🔹 IMPORTANTE: Move para favoritos e limpa o carrinho no Firestore
    // antes de sair, conforme sua nova regra de negócio.
    await cart.moverParaFavoritosELimpar();

    await _auth.signOut();
    _redirecionarLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundFundo(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Cabecalho(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, $_nomeCompleto',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Gerencie seus pedidos e dados cadastrais.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              alignment: WrapAlignment.center,
                              children: [
                                _DashboardCard(
                                  title: 'Meus Pedidos',
                                  icon: Icons.local_shipping_outlined,
                                  onTap: () {
                                    // Adicione a rota de pedidos aqui
                                  },
                                ),
                                _DashboardCard(
                                  title: 'Meus Dados',
                                  icon: Icons.person_outline,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/minha-conta',
                                  ),
                                  // VOLTOU PARA FAVORITOS
                                  //_DashboardCard(
                                  //title: 'Favoritos',
                                  //icon: Icons.favorite_border,
                                  //onTap: () {
                                  /* Lista de Favoritos */
                                  //},
                                  //),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Divider(),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _executarLogout,
                            icon: const Icon(
                              Icons.exit_to_app,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              "Sair da Conta",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Rodape(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          height: 140,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.brown),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
