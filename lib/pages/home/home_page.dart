import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importação necessária para verificar login
// Importações das seções
import '../../shared/sections/header/cabecalho.dart';
import '../../shared/sections/carousel/carrossel_principal.dart';
import 'widgets/produtos_em_destaque.dart';
import '../../shared/sections/carousel/depoimentos/carrossel_depoimentos.dart';
import '../../shared/sections/footer/rodape.dart';
import '../../shared/widgets/background_fundo.dart';
import '../../shared/widgets/depoimento_form.dart'; // Import do formulário que criamos
import '../../shared/theme/tema_site.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Função para abrir o formulário em um modal
  void _abrirFormularioDepoimento(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DepoimentoForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuta o estado da autenticação para decidir se mostra o botão
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: BackgroundFundo(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // CABEÇALHO - AGORA ROLA COM O CONTEÚDO
              const Cabecalho(),

              const SizedBox(height: 5),
              const CarrosselPrincipal(),

              const SizedBox(height: 5),
              const ProdutosEmDestaque(),

              // --- SEÇÃO DO CARROSSEL DE DEPOIMENTOS ---
              // Visível para todos os usuários
              const Padding(
                padding: EdgeInsets.only(top: 5.0),
                child: CarrosselDepoimentos(),
              ),

              // --- BOTÃO DE CADASTRAR DEPOIMENTO ---
              // Aparece APENAS se o cliente estiver logado
              if (user != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirFormularioDepoimento(context),
                    icon: const Icon(Icons.rate_review, color: Colors.white),
                    label: const Text(
                      "DEIXAR MEU DEPOIMENTO",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TemaSite.corPrimaria,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),

              // --- RODAPÉ ---
              const Rodape(),
            ],
          ),
        ),
      ),
    );
  }
}
