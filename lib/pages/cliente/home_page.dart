import 'package:flutter/material.dart';
// Importações das seções
import '../../secoes/cabecalho/cabecalho.dart';
import '../../secoes/carrossel/carrossel_principal.dart';
//import '../secoes/beneficios_categorias/beneficios_e_categorias.dart';
import '../../secoes/produtos_destaque/produtos_em_destaque.dart';
import '../../secoes/carrossel/carrossel_depoimentos.dart';
import '../../secoes/rodape/rodape.dart';
import '../../widgets/background_fundo.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // Removendo o Column e Expanded de nível superior
      // e usando o BackgroundFundo diretamente como body,
      // pois ele contém o SingleChildScrollView.
      body: BackgroundFundo(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // <<< MUDANÇA AQUI: CABEÇALHO DENTRO DO SINGLECHILDSCROLLVIEW >>>
              // CABEÇALHO - AGORA ROLA COM O CONTEÚDO
              Cabecalho(),

              SizedBox(height: 5),
              CarrosselPrincipal(),
              //SizedBox(height: 5),
              //BeneficiosECategorias(),
              SizedBox(height: 5),
              ProdutosEmDestaque(),

              // --- SEÇÃO DO CARROSSEL DE DEPOIMENTOS ---
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: CarrosselDepoimentos(),
              ),

              // --- RODAPÉ ---
              Rodape(),
            ],
          ),
        ),
      ),
    );
  }
}
