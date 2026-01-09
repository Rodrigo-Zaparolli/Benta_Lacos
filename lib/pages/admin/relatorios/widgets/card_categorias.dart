import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORTS DO SISTEMA ---
import 'package:benta_lacos/core/pdf/estoque_pdf.dart'; // Import da classe que ajustamos
import '../estoque_report_page.dart';

class CardsCategorias extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs; // Lista de Pedidos (Vendas)

  const CardsCategorias({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Monitora a coleção de produtos para cálculos de estoque em tempo real
      stream: FirebaseFirestore.instance.collection('produtos').snapshots(),
      builder: (context, snapshotProdutos) {
        // Mapa base para organizar os dados por categoria
        Map<String, Map<String, dynamic>> dados = {
          "Laços": {"v": 0, "e": 0, "total": 0.0},
          "Tiaras": {"v": 0, "e": 0, "total": 0.0},
          "Kits": {"v": 0, "e": 0, "total": 0.0},
          "Presilhas": {"v": 0, "e": 0, "total": 0.0},
          "Faixas": {"v": 0, "e": 0, "total": 0.0},
        };

        // --- 1. PROCESSAMENTO DE VENDAS (Baseado nos docs recebidos) ---
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['itens'] != null && data['itens'] is List) {
            List itens = data['itens'];
            for (var item in itens) {
              String cat = (item['category'] ?? item['categoria'] ?? "")
                  .toString();
              if (dados.containsKey(cat)) {
                int qtdVendida = (item['quantity'] ?? item['quantidade'] ?? 1)
                    .toInt();
                dados[cat]!['v'] += qtdVendida;
              }
            }
          }
        }

        // --- 2. PROCESSAMENTO DE ESTOQUE (Baseado no Firestore) ---
        if (snapshotProdutos.hasData) {
          for (var prodDoc in snapshotProdutos.data!.docs) {
            final p = prodDoc.data() as Map<String, dynamic>;
            String cat = (p['category'] ?? p['categoria'] ?? "").toString();
            if (dados.containsKey(cat)) {
              num qtdEstoque = p['quantity'] ?? p['quantidade'] ?? 0;
              num preco = p['price'] ?? p['preco'] ?? 0;
              dados[cat]!['e'] += qtdEstoque.toInt();
              dados[cat]!['total'] +=
                  (preco.toDouble() * qtdEstoque.toDouble());
            }
          }
        }

        // --- 3. INTERFACE SCROLLÁVEL ---
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: dados.keys.map((cat) {
              return _buildCard(
                context,
                cat,
                _getIcon(cat),
                _getColor(cat),
                dados[cat]!,
                snapshotProdutos, // Passamos o snapshot para o card usar no PDF
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // --- CONSTRUTOR DOS CARDS INDIVIDUAIS ---
  Widget _buildCard(
    BuildContext context,
    String titulo,
    IconData icone,
    Color cor,
    Map<String, dynamic> info,
    AsyncSnapshot<QuerySnapshot> snapshotProdutos,
  ) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Row(
                children: [
                  _miniButton(
                    icon: Icons.analytics_outlined,
                    color: cor,
                    tooltip: "Ver Detalhes",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EstoqueReportPage(
                            categoria: titulo,
                            pedidos: docs,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // BOTÃO PDF: LINKADO COM A CLASSE ESTOQUE_PDF
                  _miniButton(
                    icon: Icons.picture_as_pdf_rounded,
                    color: cor,
                    tooltip: "Gerar PDF de Estoque",
                    onPressed: () {
                      if (snapshotProdutos.hasData) {
                        // Chama o PDF passando a lista bruta de produtos do Firestore
                        // A filtragem por categoria é feita dentro da classe EstoquePdf
                        EstoquePdf.gerar(snapshotProdutos.data!.docs, titulo);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Aguardando carregamento dos dados...",
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Informação de Vendas
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
            "ESTOQUE ATUAL",
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

  // Helpers para ícones e cores para manter o código limpo
  IconData _getIcon(String cat) {
    switch (cat) {
      case "Tiaras":
        return Icons.face;
      case "Kits":
        return Icons.layers;
      case "Presilhas":
        return Icons.cut;
      case "Faixas":
        return Icons.linear_scale;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getColor(String cat) {
    switch (cat) {
      case "Tiaras":
        return Colors.deepPurpleAccent;
      case "Kits":
        return Colors.lightBlue;
      case "Presilhas":
        return Colors.orange;
      case "Faixas":
        return Colors.green;
      default:
        return Colors.pinkAccent;
    }
  }

  Widget _miniButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 28,
      width: 28,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: color.withOpacity(0.6)),
        onPressed: onPressed,
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
