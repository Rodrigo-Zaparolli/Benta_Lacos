import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardVisualizados extends StatelessWidget {
  final String titulo;
  final String colecao;
  final String campoOrdenacao;
  final IconData icone;
  final Color cor;
  final double altura;

  const CardVisualizados({
    super.key,
    this.titulo = "Mais Visualizados",
    this.colecao = 'produtos',
    this.campoOrdenacao = 'visualizacoes',
    this.icone = Icons.visibility,
    this.cor = Colors.orange,
    required this.altura, // Agora exigimos a altura para evitar conflitos
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: altura,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF2D3E50),
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(colecao)
                  .orderBy(campoOrdenacao, descending: true)
                  .limit(8)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text("Erro ao carregar"));
                if (!snapshot.hasData) return const LinearProgressIndicator();

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final d =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    return _itemRow(
                      d['name'] ?? d['nome'] ?? "Sem Nome",
                      "${(d[campoOrdenacao] ?? 0).toInt()} visual.",
                      icone,
                      cor,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(String nome, String valor, IconData icone, Color cor) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icone, color: cor, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nome,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              valor,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
}
