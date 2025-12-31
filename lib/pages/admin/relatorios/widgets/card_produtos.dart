import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardProdutos extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs; // Lista de Pedidos

  const CardProdutos({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    Map<String, int> rankingVendas = {};

    // Processa os itens de todos os pedidos carregados
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final itens = data['itens'] as List? ?? [];
      for (var item in itens) {
        String nomeProd = item['name'] ?? item['nome'] ?? "Produto Sem Nome";
        final valorQuantidade = item['quantidade'] ?? 1;
        int quantidade = valorQuantidade is num ? valorQuantidade.toInt() : 1;

        rankingVendas[nomeProd] = (rankingVendas[nomeProd] ?? 0) + quantidade;
      }
    }

    final todasVendas = rankingVendas.entries.toList();

    // Ordena do mais vendido para o menos vendido
    final listaOrdenada = List<MapEntry<String, int>>.from(todasVendas)
      ..sort((a, b) => b.value.compareTo(a.value));

    // Pega os 5 principais (aumentei de 3 para 5 para você visualizar melhor os novos)
    final topVendidos = listaOrdenada.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ranking de Saída (Pedidos)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Divider(),
          const SizedBox(height: 10),
          topVendidos.isEmpty
              ? const Center(
                  child: Text(
                    "Nenhuma venda registrada neste período.",
                    style: TextStyle(fontSize: 11),
                  ),
                )
              : Column(
                  children: topVendidos
                      .map((e) => _itemRow(e.key, "${e.value} un."))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _itemRow(String nome, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              nome,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            valor,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
