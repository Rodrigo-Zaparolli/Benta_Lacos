// main.dart
// Arquivo principal do projeto Benta Laços
// Inicializa Firebase, configura rotas e define a página inicial (Login ou Home)
// Autor: Rodrigo

import 'package:benta_lacos/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// Páginas
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/dashboard_page.dart';

// Widgets
import 'widgets/background_fundo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const BentaLacosApp());
}

class BentaLacosApp extends StatelessWidget {
  const BentaLacosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Benta Laços',
      debugShowCheckedModeBanner: false,

      // ===============================
      // ROTAS DO APLICATIVO
      // ===============================
      routes: {
        '/': (context) => const RootDecider(), // Decide a tela inicial
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/home': (context) => const HomePage(),
        "/profile": (context) => const ProfilePage(),
      },

      theme: ThemeData(
        primaryColor: Colors.brown,
        colorScheme: ColorScheme.fromSwatch().copyWith(primary: Colors.brown),
      ),
    );
  }
}

//
// ROOT DECIDER
// Verifica se o usuário está logado e redireciona automaticamente.
//
class RootDecider extends StatelessWidget {
  const RootDecider({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Ainda carregando o Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BackgroundFundo(
            child: Center(
              child: CircularProgressIndicator(color: Colors.brown),
            ),
          );
        }

        // Usuário não logado → Vai para Login
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // Usuário logado mas sem e-mail verificado → Vai para Login
        if (!(snapshot.data!.emailVerified)) {
          return const LoginPage();
        }

        // Usuário logado e verificado → Vai para Dashboard
        return const DashboardPage();
      },
    );
  }
}
