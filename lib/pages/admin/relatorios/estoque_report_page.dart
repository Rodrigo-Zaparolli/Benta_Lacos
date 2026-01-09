import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- NOVOS IMPORTS DOS SERVIÇOS MODULARES ---
import 'package:benta_lacos/core/pdf/estoque_pdf.dart';
import 'package:benta_lacos/shared/theme/tema_site.dart';

class EstoqueReportPage extends StatelessWidget {
  final String categoria;
  final List<QueryDocumentSnapshot> pedidos;

  const EstoqueReportPage({
    super.key,
    required this.categoria,
    required this.pedidos,
  });

  @override
  Widget build(BuildContext context) {
    final formatadorMoeda = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Busca os produtos atualizados no banco
          final snap = await FirebaseFirestore.instance
              .collection('produtos')
              .get();

          final produtosFiltrados = snap.docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final cat = (data['categoria'] ?? data['category'] ?? "")
                .toString();
            return cat.toLowerCase() == categoria.toLowerCase();
          }).toList();

          // --- CHAMADA CORRIGIDA AQUI ---
          // Agora usamos o EstoquePdf que criamos anteriormente
          await EstoquePdf.gerar(produtosFiltrados, categoria);
        },
        backgroundColor: TemaAdmin.PdfOne,
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: const Text(
          "Exportar PDF",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- CABEÇALHO ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: 18,
                      color: TemaAdmin.PdfOne,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      "Inventário Benta Laços: ${categoria.toUpperCase()}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: TemaAdmin.PdfOne,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // --- CONTEÚDO ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('produtos')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: TemaAdmin.PdfOne),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("Nenhum produto encontrado."),
                    );
                  }

                  final produtos = snapshot.data!.docs.where((doc) {
                    final p = doc.data() as Map<String, dynamic>;
                    final catBanco = (p['categoria'] ?? p['category'] ?? "")
                        .toString()
                        .toLowerCase();
                    return catBanco == categoria.toLowerCase();
                  }).toList();

                  int totalEstoquePecas = 0;
                  for (var p in produtos) {
                    final d = p.data() as Map<String, dynamic>;
                    totalEstoquePecas +=
                        ((d['quantidade'] ?? d['quantity'] ?? d['estoque'] ?? 0)
                                as num)
                            .toInt();
                  }

                  return Column(
                    children: [
                      // --- MÉTRICAS ---
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                "PRODUTOS",
                                produtos.length.toString(),
                                TemaAdmin.PdfSix,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricCard(
                                "ESTOQUE TOTAL",
                                totalEstoquePecas.toString(),
                                TemaAdmin.PdfFour,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricCard(
                                "CATEGORIA",
                                categoria.toUpperCase(),
                                TemaAdmin.PdfOne,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- GRID DE PRODUTOS ---
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 7,
                              ),
                          itemCount: produtos.length,
                          itemBuilder: (context, index) {
                            final p =
                                produtos[index].data() as Map<String, dynamic>;

                            final nome = (p['nome'] ?? p['name'] ?? 'Sem nome')
                                .toString();
                            final imagemUrl =
                                p['foto'] ?? p['url'] ?? p['imageUrl'];
                            final estoque =
                                (p['quantidade'] ??
                                        p['quantity'] ??
                                        p['estoque'] ??
                                        0)
                                    .toInt();
                            final preco =
                                (p['preco'] ?? p['price'] ?? p['valor'] ?? 0)
                                    .toDouble();

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 75,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      child:
                                          (imagemUrl != null &&
                                              imagemUrl.toString().isNotEmpty)
                                          ? Image.network(
                                              imagemUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) =>
                                                  const Icon(
                                                    Icons.image_not_supported,
                                                    size: 20,
                                                    color: Colors.grey,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.image,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            nome,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Estoque: $estoque",
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            formatadorMoeda.format(preco),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: TemaAdmin.PdfOne,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
