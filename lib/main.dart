import 'package:benta_lacos/models/providers/cart_provider.dart';
import 'package:benta_lacos/pages/admin/admin_page.dart';
import 'package:benta_lacos/pages/cliente/home_page.dart';
import 'package:benta_lacos/root_decider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Adicionado

import 'firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    // O MultiProvider permite que o Carrinho seja acessado de qualquer página
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Benta Laços',
      theme: ThemeData(
        useMaterial3: true,
        // Você pode ajustar as cores do tema global aqui
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC5A059)),
      ),
      //home: const RootDecider(),
      //home: const HomePage(), // <<<< AQUI AGORA ABRE A PÁGINA PRINCIPAL
      home: const AdminPage(), // <<<< AQUI AGORA ABRE A PÁGINA ADMIN
    );
  }
}
