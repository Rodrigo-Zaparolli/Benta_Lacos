import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardProdutos extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  const CardProdutos({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    Map<String, int> rankingVendas = {};

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

    final listaMais = List<MapEntry<String, int>>.from(todasVendas)
      ..sort((a, b) => b.value.compareTo(a.value));

    final topMaisVendidos = listaMais.take(3).toList();

    final listaMenos = todasVendas.where((entry) {
      return !topMaisVendidos.any((top) => top.key == entry.key);
    }).toList()..sort((a, b) => a.value.compareTo(b.value));

    final topMenosVendidos = listaMenos.take(3).toList();

    return Container(
      // === [AJUSTE DE ALTURA] ===
      // Altere o valor de 'height' para aumentar ou diminuir o tamanho vertical do card.
      height: 300,
      decoration: BoxDecoration(
        // === [COR DE BACKGROUND DO CARD] ===
        // Use 'Colors.white' ou hexadecimais como 'Color(0xFFXXXXXX)'.
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: _RankingInternalSection(
              titulo: "Mais Vendidos",
              icone: Icons.trending_up,
              cor: Colors.green, // Cor do ícone e destaque
              lista: topMaisVendidos,
            ),
          ),

          // === [DIVISOR] ===
          // Você pode alterar a cor da linha que separa as seções aqui.
          const Divider(height: 1, thickness: 1, color: Colors.black12),

          Expanded(
            child: _RankingInternalSection(
              titulo: "Menos Vendidos",
              icone: Icons.trending_down,
              cor: Colors.redAccent, // Cor do ícone e destaque
              lista: topMenosVendidos,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingInternalSection extends StatelessWidget {
  final String titulo;
  final List<MapEntry<String, int>> lista;
  final IconData icone;
  final Color cor;

  const _RankingInternalSection({
    required this.titulo,
    required this.lista,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              // === [FONTE: TÍTULO DA SEÇÃO] ===
              fontSize: 12,
              color: Color(0xFF2D3E50), // Cor azul escura padrão
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: lista.isEmpty
                ? const Center(
                    child: Text(
                      "Sem outros dados para comparar",
                      style: TextStyle(
                        // === [FONTE: TEXTO DE AVISO/VAZIO] ===
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: lista
                        .map(
                          (e) => _itemRow(e.key, "${e.value} un.", icone, cor),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(String nome, String valor, IconData icone, Color cor) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icone, color: cor, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nome,
                style: const TextStyle(
                  // === [FONTE: NOME DO PRODUTO] ===
                  fontSize: 11,
                  color: Colors.black87, // Cor do texto do nome
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              valor,
              style: const TextStyle(
                // === [FONTE: QUANTIDADE/VALOR] ===
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Cor do número
              ),
            ),
          ],
        ),
      );
}
