// ===============================================
// PROFILE PAGE (Página de Perfil do Usuário)
// Criada nesta etapa do projeto
// Somente usuários logados + email verificado têm acesso
// ===============================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meu Perfil"),
        automaticallyImplyLeading: true,
      ),
      body: user == null
          ? const Center(child: Text("Usuário não encontrado."))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Informações da Conta",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // EMAIL
                  Text(
                    "E-mail:",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  Text(
                    user.email ?? "Não informado",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),

                  // STATUS
                  Text(
                    "E-mail verificado:",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  Text(
                    user.emailVerified ? "Sim" : "Não",
                    style: TextStyle(
                      fontSize: 18,
                      color: user.emailVerified ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CRIAÇÃO DA CONTA
                  Text(
                    "Conta criada em:",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  Text(
                    user.metadata.creationTime != null
                        ? "${user.metadata.creationTime}"
                        : "Indefinido",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // BOTÃO ALTERAR SENHA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: user.email!,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Enviamos um e-mail para redefinir sua senha.",
                            ),
                          ),
                        );
                      },
                      child: const Text("Alterar senha"),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // BOTÃO EXCLUIR CONTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirmar exclusão"),
                            content: const Text(
                              "Deseja realmente excluir sua conta? Essa ação não pode ser desfeita.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancelar"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Excluir",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await user.delete();
                          Navigator.pushReplacementNamed(context, "/login");
                        }
                      },
                      child: const Text("Excluir conta"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
