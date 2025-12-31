import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/sections/header/cabecalho.dart';
import '../../shared/sections/footer/rodape.dart';
import '../../shared/widgets/background_fundo.dart';

class NossaHistoriaPage extends StatelessWidget {
  const NossaHistoriaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundFundo(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Cabecalho(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 60,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('institucional')
                        .doc('nossa_historia')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());

                      var data = snapshot.data!.data() as Map<String, dynamic>?;
                      String titulo = data?['titulo'] ?? 'Nossa História';
                      String conteudo = data?['conteudo'] ?? 'Em breve...';
                      String? urlImagem = data?['urlImagem'];
                      // 🔹 Pega a largura do banco ou usa 350 como padrão
                      double larguraDefinida = (data?['larguraImagem'] ?? 350)
                          .toDouble();

                      return Column(
                        children: [
                          Text(
                            titulo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                          const SizedBox(height: 50),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              bool isMobile = constraints.maxWidth < 700;

                              return Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.start,
                                spacing: 40,
                                runSpacing: 30,
                                children: [
                                  // 🟡 IMAGEM COM TAMANHO AJUSTÁVEL
                                  if (urlImagem != null && urlImagem.isNotEmpty)
                                    SizedBox(
                                      width: isMobile
                                          ? constraints.maxWidth
                                          : larguraDefinida,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.network(
                                          urlImagem,
                                          fit: BoxFit
                                              .contain, // Contain para não cortar a logo
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),

                                  // 🔴 TEXTO
                                  SizedBox(
                                    width: isMobile
                                        ? constraints.maxWidth
                                        : (1000 - larguraDefinida - 40).clamp(
                                            300,
                                            700,
                                          ),
                                    child: Text(
                                      conteudo,
                                      textAlign: TextAlign.justify,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        height: 1.7,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const Rodape(),
            ],
          ),
        ),
      ),
    );
  }
}
