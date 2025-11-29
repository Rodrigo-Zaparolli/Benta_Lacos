import 'package:benta_lacos/pages/home_page.dart';
import 'package:benta_lacos/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RootDecider extends StatelessWidget {
  const RootDecider({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Enquanto carrega o Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se está logado → vai para HomePage
        if (snapshot.hasData) {
          return const HomePage();
        }

        // Se NÃO está logado → vai para LoginPage
        return const LoginPage();
      },
    );
  }
}
