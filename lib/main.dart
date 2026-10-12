import 'pages/cliente/categoria_page.dart';
import 'pages/cliente/product_route.dart';
import 'pages/cliente/cart/cart_screen.dart';
import 'pages/cliente/checkout/checkout_page.dart';
import 'package:benta_lacos/pages/admin/institucional/editar_trocas_devolucoes_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// Firebase e Core
import 'core/firebase/firebase_options.dart';
import 'core/config/store_environment.dart';
import 'shared/theme/tema_site.dart';
import 'domain/repository/product_repository.dart';
import 'domain/providers/cart_provider.dart';

// Páginas Home e Gerais
import 'pages/home/home_page.dart';

// Páginas Cliente
import 'pages/cliente/login_page.dart';
import 'pages/cliente/criar_conta_page.dart';
import 'pages/cliente/dashboard_cliente_page.dart';
import 'pages/cliente/meus_pedidos_page.dart';
import 'pages/cliente/minha_conta.dart';

// Páginas Institucionais (VISUALIZAÇÃO CLIENTE)
import 'pages/institucional/nossa_historia_page.dart';
import 'pages/institucional/politica_de_privacidade_page.dart';
import 'pages/institucional/trocas_devolucoes_page.dart'; // Importar
import 'pages/institucional/envio_entrega_page.dart'; // Importar

// Páginas ADMIN (CONTROLE)
import 'pages/admin/login/admin_page.dart';
import 'pages/admin/institucional/editar_historia_page.dart';
import 'pages/admin/institucional/editar_politica_page.dart'; // Importar
import 'pages/admin/institucional/editar_envio_entrega_page.dart'; // Importar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Remove o '#' da URL no navegador
  usePathUrlStrategy();

  // Inicializa o Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Carrega os nomes dos meses em português
  await initializeDateFormatting('pt_BR', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ProductRepository.instance),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const BentaLacosApp(),
    ),
  );
}

class BentaLacosApp extends StatelessWidget {
  const BentaLacosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Benta Laços',
      builder: StoreEnvironment.isTest
          ? (context, child) => Column(
              children: [
                const Material(
                  color: Color(0xFFFFF0C2),
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Ambiente de testes: pedidos de teste, sem cobrança ou movimentação de estoque.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: child ?? const SizedBox.shrink()),
              ],
            )
          : null,
      theme: TemaSite.tema,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),

      routes: {
        '/': (context) => const HomePage(),
        '/colecao': (context) => const CategoriaPage(categoriaNome: ''),
        '/carrinho': (context) => const CartScreen(),
        '/checkout': (context) => const CheckoutPage(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/criar-conta': (context) => const CriarContaPage(),
        '/admin': (context) => const AdminPage(),

        // --- Rotas Cliente ---
        '/meus-pedidos': (context) => const MeusPedidosPage(),
        '/minha-conta': (context) => const MinhaContaPage(),
        '/dashboard-cliente': (context) => const DashboardClientePage(),

        // --- Rotas Institucionais (Visualização no Site) ---
        '/nossa-historia': (context) => const NossaHistoriaPage(),
        '/politica-privacidade': (context) => const PoliticaPrivacidadePage(),
        '/trocas-devolucoes': (context) => const TrocasDevolucoesPage(),
        '/envio-entrega': (context) => const EnvioEntregaPage(),

        // --- Rotas Admin (Gerenciamento de Conteúdo) ---
        '/admin-editar-historia': (context) => const AdminPage(
          initialSection: 6,
          initialEditor: EditarHistoriaPage(),
        ),
        '/admin-editar-politica': (context) => const AdminPage(
          initialSection: 6,
          initialEditor: EditarPoliticaPage(),
        ),
        '/admin-editar-trocas': (context) => const AdminPage(
          initialSection: 6,
          initialEditor: EditarTrocasDevolucoesPage(),
        ),
        '/admin-editar-envio': (context) => const AdminPage(
          initialSection: 6,
          initialEditor: EditarEnvioEntregaPage(),
        ),
      },

      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '/');
        final segments = uri?.pathSegments ?? <String>[];
        Widget? page;
        if (segments.length == 2 && segments.first == 'produto') {
          page = ProductRoute(id: segments[1]);
        } else if (segments.length == 2 && segments.first == 'categoria') {
          page = CategoriaPage(categoriaNome: segments[1]);
        } else if (uri?.path == '/busca') {
          page = CategoriaPage(
            categoriaNome:
                settings.arguments as String? ??
                uri?.queryParameters['q'] ??
                '',
            isBusca: true,
          );
        }
        return page == null
            ? null
            : MaterialPageRoute(settings: settings, builder: (_) => page!);
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const HomePage());
      },
    );
  }
}
