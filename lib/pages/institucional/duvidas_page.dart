import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/widgets/background_fundo.dart';
import '../../shared/sections/header/cabecalho.dart';
import '../../shared/sections/footer/rodape.dart';
import '../../shared/theme/tema_site.dart';

class DuvidasPage extends StatelessWidget {
  const DuvidasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundFundo(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Cabecalho(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('duvidas')
                      .orderBy('ordem')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(50.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("Nenhuma dúvida cadastrada."),
                      );
                    }

                    return Container(
                      constraints: const BoxConstraints(maxWidth: 900),
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Como podemos ajudar?",
                            textAlign: TextAlign.center,
                            style: TemaSite.rodape.headerStyle(
                              fontSize: 24,
                              color: const Color(0xFF4A4A4A),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Divider(height: 30),
                          const SizedBox(height: 15),
                          // Gerando a lista de FAQ
                          ...snapshot.data!.docs.map((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Theme(
                                // Remove a borda padrão do ExpansionTile
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  iconColor: TemaSite.corPrimaria,
                                  title: Text(
                                    data['pergunta'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4A4A4A),
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        16,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          data['resposta'] ?? '',
                                          style: const TextStyle(
                                            height: 1.6,
                                            color: Color(0xFF555555),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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
