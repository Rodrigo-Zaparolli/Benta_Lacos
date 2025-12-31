import 'package:benta_lacos/pages/admin/institucional/editar_trocas_devolucoes_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// Firebase e Core
import 'core/firebase/firebase_options.dart';
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
      theme: TemaSite.tema,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),

      initialRoute: '/',

      routes: {
        '/': (context) => const HomePage(),
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
        '/admin-editar-historia': (context) => const EditarHistoriaPage(),
        '/admin-editar-politica': (context) => const EditarPoliticaPage(),
        '/admin-editar-trocas': (context) => const EditarTrocasDevolucoesPage(),
        '/admin-editar-envio': (context) => const EditarEnvioEntregaPage(),
      },

      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const HomePage());
      },
    );
  }
}
