import 'package:flutter/material.dart';
import 'admin_ui.dart';

class AdminAccessView extends StatelessWidget {
  final String message;
  final VoidCallback onStore;
  final VoidCallback? onLogin, onRetry;
  const AdminAccessView({
    super.key,
    required this.message,
    required this.onStore,
    this.onLogin,
    this.onRetry,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminStyle.background,
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AdminStyle.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/imagens/logo.png',
                    width: 72,
                    height: 72,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Gestão Benta Laços',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AdminStyle.ink,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Um espaço para cuidar de cada detalhe da sua loja.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: AdminStyle.muted,
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminStyle.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.7,
                      color: AdminStyle.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (onLogin != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onLogin,
                      icon: const Icon(Icons.login, size: 17),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Text('Entrar na administração'),
                      ),
                    ),
                  ),
                if (onRetry != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 17),
                      label: const Text('Tentar novamente'),
                    ),
                  ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onStore,
                  child: const Text('Voltar à loja'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
