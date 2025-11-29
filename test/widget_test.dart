import 'package:benta_lacos/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:benta_lacos/tema/tema_site.dart';
import 'package:benta_lacos/pages/home_page.dart';
import 'package:benta_lacos/pages/home_page.dart';

// Importações do Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:benta_lacos/firebase/firebase_options.dart'; // Assumindo que este arquivo existe

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INICIALIZAÇÃO DO FIREBASE CORE
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const BentaLacosApp());
}

class BentaLacosApp extends StatelessWidget {
  const BentaLacosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Benta Laços',
      theme: TemaSite.tema, // Usa o tema que você definiu
      initialRoute:
          '/login', // Define a rota inicial para a página de Login/Cadastro
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) =>
            const LoginPage(), // Rota para a página de Login/Cadastro
        // Adicione outras rotas aqui, como '/admin', '/minha-conta', etc.
      },
    );
  }
}
