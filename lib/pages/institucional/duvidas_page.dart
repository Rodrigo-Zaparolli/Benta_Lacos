import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/theme/tema_site.dart';

class DuvidasPage extends StatelessWidget {
  const DuvidasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dúvidas Frequentes"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('duvidas')
            .orderBy('ordem')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhuma dúvida cadastrada."));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                "Como podemos ajudar?",
                style: TemaSite.rodape.headerStyle(
                  fontSize: 24,
                  color: TemaSite.corPrimaria,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ...snapshot.data!.docs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: ExpansionTile(
                    title: Text(
                      data['pergunta'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          data['resposta'],
                          style: const TextStyle(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
