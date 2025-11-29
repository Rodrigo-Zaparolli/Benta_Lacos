//import 'package:benta_lacos/pages/admin_page.dart';
import 'package:benta_lacos/pages/home_page.dart';
import 'package:benta_lacos/root_decider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Benta Laços',
      //home: const RootDecider(),
      home: const HomePage(), // <<<< AQUI AGORA ABRE A PÁGINA PRINCIPAL
      //home: const AdminPage(), // <<<< AQUI AGORA ABRE A PÁGINA ADMIN
    );
  }
}
