import 'package:benta_lacos/core/config/store_environment.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_ui.dart';
import '../widgets/admin_access_view.dart';
import '../widgets/admin_actions.dart';
import '../dashboard/admin_overview.dart';
import '../dashboard/admin_products.dart';
import '../dashboard/admin_clients.dart';
import '../pedidos/gestao_pedidos_page.dart';
import '../relatorios/relatorios_page.dart';
import '../institucional/editar_depoimentos_page.dart';
import '../institucional/editar_historia_page.dart';
import '../institucional/editar_contato_page.dart';
import '../institucional/editar_trocas_devolucoes_page.dart';
import '../institucional/editar_envio_entrega_page.dart';
import '../institucional/editar_duvidas_page.dart';
import '../institucional/editar_quem_sou_page.dart';
import '../institucional/editar_oque_faco_page.dart';
import '../institucional/editar_politica_page.dart';

class AdminPage extends StatefulWidget {
  final bool isSplitView;
  final int initialSection;
  final Widget? initialEditor;
  const AdminPage({
    super.key,
    this.isSplitView = false,
    this.initialSection = 0,
    this.initialEditor,
  });
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late int _selected;
  int _retry = 0;
  String _orderFilter = 'Todos';
  late Stream<User?> _authStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _roleStream;
  String? _roleUser;
  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
    _selected = widget.initialSection.clamp(0, 7);
  }

  void _select(int index) => setState(() {
    _selected = index;
    if (index == 1) _orderFilter = 'Todos';
  });
  void _openOrders(String status) => setState(() {
    _orderFilter = status;
    _selected = 1;
  });
  void _store() => Navigator.of(
    context,
    rootNavigator: true,
  ).pushNamedAndRemoveUntil('/', (_) => false);
  Widget _access(String message, {bool retry = false, bool login = false}) =>
      AdminAccessView(
        message: message,
        onStore: _store,
        onLogin: login
            ? () =>
                  Navigator.of(context, rootNavigator: true).pushNamed('/login')
            : null,
        onRetry: retry
            ? () => setState(() {
                _retry++;
                _roleStream = null;
                _authStream = FirebaseAuth.instance.authStateChanges();
              })
            : null,
      );
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: _authStream,
    builder: (context, auth) {
      if (auth.connectionState == ConnectionState.waiting)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (auth.hasError)
        return _access('Não foi possível verificar sua sessão.', retry: true);
      if (auth.data == null)
        return _access(
          'Entre com uma conta administradora para acessar o painel.',
          login: true,
        );
      if (_roleUser != auth.data!.uid) {
        _roleUser = auth.data!.uid;
        _roleStream = null;
      }
      _roleStream ??= StoreEnvironment.database
          .collection(StoreEnvironment.collectionName('usuarios'))
          .doc(auth.data!.uid)
          .snapshots();
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        key: ValueKey('${auth.data!.uid}:$_retry'),
        stream: _roleStream,
        builder: (context, role) {
          if (role.hasError)
            return _access(
              'Não foi possível verificar a permissão de acesso.',
              retry: true,
            );
          if (!role.hasData)
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          if (role.data!.data()?['tipo'] != 'admin')
            return _access('Esta conta não possui acesso à administração.');
          return AdminLayout(
            email: auth.data!.email ?? '',
            selected: _selected,
            onSelect: _select,
            onStore: _store,
            onLogout: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) _store();
              } catch (_) {
                if (mounted)
                  adminMessage(
                    context,
                    'Não foi possível sair. Tente novamente.',
                  );
              }
            },
            child: Navigator(
              key: ValueKey('admin:$_selected:$_orderFilter'),
              onGenerateInitialRoutes: (navigator, initialRoute) => [
                MaterialPageRoute(
                  builder: (_) => _section(auth.data!.email ?? ''),
                ),
                if (widget.initialEditor != null &&
                    _selected == widget.initialSection)
                  MaterialPageRoute(builder: (_) => widget.initialEditor!),
              ],
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => _section(auth.data!.email ?? ''),
              ),
            ),
          );
        },
      );
    },
  );

  Widget _section(String email) => switch (_selected) {
    0 => AdminOverview(onOpen: _select, onOpenOrders: _openOrders),
    1 => GestaoPedidosPage(embedded: true, initialStatus: _orderFilter),
    2 => const AdminProducts(),
    3 => const AdminProducts(stock: true),
    4 => const AdminClients(),
    5 => const RelatoriosPage(embedded: true),
    6 => const _ContentMenu(),
    _ => _Settings(email: email),
  };
}

class _ContentMenu extends StatelessWidget {
  const _ContentMenu();
  @override
  Widget build(BuildContext context) {
    final pages = <(String, String, Widget)>[
      (
        'História da marca',
        'Conte a origem da Benta Laços.',
        const EditarHistoriaPage(),
      ),
      (
        'Quem sou',
        'Apresente a responsável pela loja.',
        const EditarQuemSouPage(),
      ),
      (
        'O que faço',
        'Descreva o trabalho e os produtos.',
        const EditarOQueFacoPage(),
      ),
      (
        'Depoimentos',
        'Gerencie a prova social da loja.',
        const GestaoDepoimentosPage(),
      ),
      (
        'Dúvidas frequentes',
        'Responda às perguntas dos clientes.',
        const EditarDuvidasPage(),
      ),
      (
        'Envio e entrega',
        'Atualize prazos e modalidades.',
        const EditarEnvioEntregaPage(),
      ),
      (
        'Trocas e devoluções',
        'Mantenha as condições de atendimento claras.',
        const EditarTrocasDevolucoesPage(),
      ),
      (
        'Política de privacidade',
        'Revise a política publicada.',
        const EditarPoliticaPage(),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const AdminHeading(
          'Conteúdo do site',
          'Edite as informações da marca e as páginas de atendimento.',
        ),
        ...pages.map(
          (p) => Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(p.$1),
              subtitle: Text(p.$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => p.$3)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Settings extends StatelessWidget {
  final String email;
  const _Settings({required this.email});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const AdminHeading(
        'Configurações',
        'Contato comercial e informações da conta administradora.',
      ),
      Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(20),
          leading: const Icon(Icons.contact_phone_outlined),
          title: const Text('Contato e WhatsApp da loja'),
          subtitle: const Text(
            'Atualize os canais usados no rodapé e no atendimento dos pedidos.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const EditarContatoPage())),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Conta conectada',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SelectableText(email),
              const Text('Permissão: administrador'),
              const SizedBox(height: 20),
              const Text(
                'As vendas são confirmadas após verificar o pagamento recebido. Frete, contato e envio são gerenciados pelo atendimento.',
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
