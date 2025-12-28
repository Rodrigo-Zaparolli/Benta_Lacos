import 'package:benta_lacos/pages/admin/login/admin_page.dart';
import 'package:benta_lacos/pages/home/home_page.dart';
import 'package:benta_lacos/pages/cliente/login_page.dart';
import 'package:benta_lacos/shared/theme/tema_site.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RootDecider extends StatelessWidget {
  const RootDecider({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: TemaSite.corPrimaria),
            ),
          );
        }

        // [AJUSTE]: Se o usuário está logado, agora usamos um FutureBuilder para checar o 'tipo' no Firestore
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('usuarios') // Nome da sua coleção no Firebase
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: TemaSite.corPrimaria,
                    ),
                  ),
                );
              }

              // [AJUSTE]: Verifica se o documento existe e se o campo 'tipo' é 'admin'
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final String tipo = userData['tipo'] ?? 'cliente';

                if (tipo == 'admin') {
                  return const AdminPage(); // Redireciona para Admin
                }
              }

              return const HomePage(); // Se não for admin, vai para Home
            },
          );
        }

        return const LoginPage(); // Se não estiver logado, vai para Login
      },
    );
  }
}
