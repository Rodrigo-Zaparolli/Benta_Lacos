import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/sections/header/cabecalho.dart';
import '../../shared/sections/footer/rodape.dart';
import '../../shared/widgets/background_fundo.dart';

class OQueFacoPage extends StatelessWidget {
  const OQueFacoPage({super.key});

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
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('institucional')
                      .doc('oque_faco')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var data = snapshot.data?.data() as Map<String, dynamic>?;
                    String titulo = data?['titulo'] ?? 'O Que Faço';
                    String conteudo = data?['conteudo'] ?? 'Em breve...';
                    String? urlImagem = data?['urlImagem'];
                    bool temImagem = urlImagem != null && urlImagem.isNotEmpty;
                    double larguraDefinida = (data?['larguraImagem'] ?? 350)
                        .toDouble();

                    return Container(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Text(
                            titulo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A4A4A),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Divider(height: 30),
                          const SizedBox(height: 25),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              bool isMobile = constraints.maxWidth < 700;

                              return Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.start,
                                spacing: 40,
                                runSpacing: 30,
                                children: [
                                  // Se tiver imagem, renderiza o box da imagem
                                  if (temImagem)
                                    SizedBox(
                                      width: isMobile
                                          ? constraints.maxWidth
                                          : larguraDefinida,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.network(
                                          urlImagem!,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),
                                  // Texto: se não tem imagem, ocupa maxWidth. Se tem, calcula o restante.
                                  SizedBox(
                                    width: !temImagem || isMobile
                                        ? constraints.maxWidth
                                        : (1000 - larguraDefinida - 40).clamp(
                                            300,
                                            700,
                                          ),
                                    child: Text(
                                      conteudo,
                                      textAlign: temImagem
                                          ? TextAlign.justify
                                          : TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        height: 1.7,
                                        color: Color(0xFF555555),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
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
