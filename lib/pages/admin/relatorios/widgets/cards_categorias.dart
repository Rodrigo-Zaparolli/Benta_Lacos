import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardsCategorias extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs; // Lista de Pedidos (vendas)
  const CardsCategorias({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('produtos').snapshots(),
      builder: (context, snapshotProdutos) {
        // Mapa de dados inicializando categorias conforme o padrão da Benta Laços
        Map<String, Map<String, dynamic>> dados = {
          "Laços": {"v": 0, "e": 0, "total": 0.0},
          "Tiaras": {"v": 0, "e": 0, "total": 0.0},
          "Kits": {"v": 0, "e": 0, "total": 0.0},
          "Presilhas": {"v": 0, "e": 0, "total": 0.0},
          "Faixas": {"v": 0, "e": 0, "total": 0.0},
        };

        // --- 1. PROCESSAR VENDAS (CONTABILIZAR ITENS VENDIDOS) ---
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Verifica se existe a lista de itens no pedido
          if (data['itens'] != null && data['itens'] is List) {
            List itens = data['itens'];

            for (var item in itens) {
              // BUSCA A CATEGORIA: Tenta 'category' ou 'categoria' (comum em PT-BR)
              String cat = (item['category'] ?? item['categoria'] ?? "")
                  .toString();

              // Se a categoria do item vendido estiver no nosso mapa, incrementa a quantidade vendida ('v')
              if (dados.containsKey(cat)) {
                // Aqui somamos a quantidade vendida desse item específico no pedido
                // Se o campo 'quantidade' não existir no item, assume 1
                int qtdVendida = (item['quantity'] ?? item['quantidade'] ?? 1)
                    .toInt();
                dados[cat]!['v'] += qtdVendida;
              }
            }
          }
        }

        // --- 2. PROCESSAR ESTOQUE (DADOS DOS PRODUTOS CADASTRADOS) ---
        if (snapshotProdutos.hasData) {
          for (var prodDoc in snapshotProdutos.data!.docs) {
            final p = prodDoc.data() as Map<String, dynamic>;
            String cat = (p['category'] ?? p['categoria'] ?? "").toString();

            if (dados.containsKey(cat)) {
              // 'quantity' é a quantidade atual em estoque
              // 'price' é o preço unitário do produto
              num qtdEstoque = p['quantity'] ?? p['quantidade'] ?? 0;
              num preco = p['price'] ?? p['preco'] ?? 0;

              dados[cat]!['e'] += qtdEstoque.toInt();
              dados[cat]!['total'] +=
                  (preco.toDouble() * qtdEstoque.toDouble());
            }
          }
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildCard(
                "Laços",
                Icons.card_giftcard,
                Colors.pinkAccent,
                dados["Laços"]!,
              ),
              _buildCard(
                "Tiaras",
                Icons.face,
                Colors.deepPurpleAccent,
                dados["Tiaras"]!,
              ),
              _buildCard(
                "Kits",
                Icons.layers,
                Colors.lightBlue,
                dados["Kits"]!,
              ),
              _buildCard(
                "Presilhas",
                Icons.cut,
                Colors.orange,
                dados["Presilhas"]!,
              ),
              _buildCard(
                "Faixas",
                Icons.linear_scale,
                Colors.green,
                dados["Faixas"]!,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(
    String titulo,
    IconData icone,
    Color cor,
    Map<String, dynamic> info,
  ) {
    // Cálculo do preço médio do que está em estoque
    double precoMedio = info['e'] > 0 ? info['total'] / info['e'] : 0.0;

    return Container(
      width: 230,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: cor, size: 20),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // --- LINHA DE VENDIDOS (Onde estava o problema) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Vendidos:",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Text(
                "${info['v']} un",
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: Colors.black12, thickness: 1),
          ),
          const Text(
            "ESTOQUE",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          _rowInfo("Quantidade:", "${info['e']} un", Colors.black87),
          _rowInfo(
            "Preço Médio:",
            "R\$ ${precoMedio.toStringAsFixed(2)}",
            Colors.black87,
          ),
          _rowInfo(
            "Valor Total:",
            "R\$ ${info['total'].toStringAsFixed(2)}",
            cor,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _rowInfo(
    String label,
    String valor,
    Color corValor, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            valor,
            style: TextStyle(
              color: corValor,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
