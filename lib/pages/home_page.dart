import 'package:flutter/material.dart';

// Importações das seções
import '../secoes/cabecalho/cabecalho.dart';
import '../secoes/carrossel/carrossel_principal.dart';
import '../secoes/beneficios_categorias/beneficios_e_categorias.dart';
import '../secoes/produtos_destaque/produtos_em_destaque.dart';
import '../secoes/carrossel/carrossel_depoimentos.dart';
import '../secoes/rodape/rodape.dart';
import '../widgets/background_fundo.dart'; // <- Importa o widget de fundo

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // CABEÇALHO
          const Cabecalho(),

          // CONTEÚDO COM FUNDO GERAL
          Expanded(
            child: BackgroundFundo(
              child: SingleChildScrollView(
                child: Column(
                  children: const [
                    SizedBox(height: 5),
                    CarrosselPrincipal(),
                    SizedBox(height: 5),
                    BeneficiosECategorias(),
                    SizedBox(height: 5),
                    ProdutosEmDestaque(),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: CarrosselDepoimentos(),
                    ),
                    Rodape(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
