import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/widgets/background_fundo.dart';
import '../../shared/sections/header/cabecalho.dart';
import '../../shared/sections/footer/rodape.dart';

class EnvioEntregaPage extends StatelessWidget {
  const EnvioEntregaPage({super.key});

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
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('institucional')
                      .doc('envio') // ID do documento no Firestore
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var data = snapshot.data?.data() as Map<String, dynamic>?;
                    String titulo = data?['titulo'] ?? 'Envio e Entrega';
                    String conteudo =
                        data?['conteudo'] ??
                        'As informações de envio estarão disponíveis em breve.';

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
                            titulo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A4A4A),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Divider(height: 30),
                          const SizedBox(height: 15),
                          Text(
                            conteudo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Color(0xFF555555),
                            ),
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
