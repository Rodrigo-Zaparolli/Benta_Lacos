import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

// ESTA IMPORTAÇÃO É O QUE ESTÁ FALTANDO PARA RECONHECER O GlobalMaterialLocalizations
import 'package:flutter_localizations/flutter_localizations.dart';

// Firebase
import 'firebase/firebase_options.dart';
import 'tema/tema_site.dart';
import 'repository/product_repository.dart';
import 'models/providers/cart_provider.dart';

// Páginas
import 'pages/cliente/home_page.dart';
import 'pages/cliente/login_page.dart';
import 'pages/cliente/criar_conta_page.dart';
import 'pages/admin/admin_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

      // CONFIGURAÇÕES DE LOCALIZAÇÃO (Sem 'const' para evitar erros de versão)
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),

      home: const HomePage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/criar-conta': (context) => const CriarContaPage(),
        '/admin': (context) => const AdminPage(),
      },
    );
  }
}
