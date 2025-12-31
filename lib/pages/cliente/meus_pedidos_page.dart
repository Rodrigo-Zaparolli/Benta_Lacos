import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../domain/services/pdf_service_cliente.dart';
import '../../shared/sections/header/cabecalho.dart';
import '../../shared/sections/footer/rodape.dart';
import '../../shared/widgets/background_fundo.dart';
import '../../shared/theme/tema_site.dart';

class MeusPedidosPage extends StatelessWidget {
  const MeusPedidosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: BackgroundFundo(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Cabecalho(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meus Pedidos',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (user == null)
                        const Center(
                          child: Text(
                            "Você precisa estar logado para ver seus pedidos.",
                          ),
                        )
                      else
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('pedidos')
                              .where('clienteId', isEqualTo: user.uid)
                              .orderBy('dataPedido', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              debugPrint("ERRO FIRESTORE: ${snapshot.error}");
                              if (snapshot.error.toString().contains(
                                'failed-precondition',
                              )) {
                                return const Center(
                                  child: Text(
                                    "Configurando o banco de dados... Por favor, aguarde 2 minutos e atualize a página.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                );
                              }
                              return Center(
                                child: Text(
                                  "Erro ao carregar: ${snapshot.error}",
                                ),
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final pedidos = snapshot.data!.docs;

                            if (pedidos.isEmpty) {
                              return _buildEmptyState();
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pedidos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 15),
                              itemBuilder: (context, index) {
                                final pedido =
                                    pedidos[index].data()
                                        as Map<String, dynamic>;
                                final pedidoId = pedidos[index].id;
                                return _OrderCard(
                                  pedido: pedido,
                                  pedidoId: pedidoId,
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const Rodape(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            "Você ainda não realizou nenhum pedido.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> pedido;
  final String pedidoId;

  const _OrderCard({required this.pedido, required this.pedidoId});

  // CORREÇÃO: Passando a lista de mapas diretamente para o serviço
  void _gerarPdfHistorico() async {
    // Garantimos que estamos enviando os dados exatamente como o Firestore salvou
    final List itensDoBanco = pedido['itens'] as List? ?? [];

    await PdfServiceCliente.gerarComprovantePedido(
      pedidoId: pedidoId,
      nomeCliente: pedido['nomeCliente'] ?? 'Cliente',
      itens:
          itensDoBanco, // Agora passamos a lista do banco que contém 'imageUrl'
      total: (pedido['total'] as num).toDouble(),
      frete: (pedido['valorFrete'] as num? ?? 0.0).toDouble(),
      metodoPagamento: pedido['metodoPagamento'] ?? 'Não informado',
      enderecoCompleto:
          pedido['enderecoExibicao'] ?? "Consulte o WhatsApp para detalhes",
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'entregue':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      case 'enviado':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime data = pedido['dataPedido'] is Timestamp
        ? (pedido['dataPedido'] as Timestamp).toDate()
        : DateTime.now();

    final String dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(data);
    final String status = pedido['status'] ?? 'Pendente';
    final double total = (pedido['total'] ?? 0.0).toDouble();
    final Color statusColor = _getStatusColor(status);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(Icons.shopping_basket, color: statusColor),
        title: Text("Pedido #${pedidoId.substring(0, 8).toUpperCase()}"),
        subtitle: Text("Data: $dataFormatada"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "R\$ ${total.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Itens:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: _gerarPdfHistorico,
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text("PDF"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: TemaSite.corPrimaria,
                        side: const BorderSide(color: TemaSite.corPrimaria),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...(pedido['itens'] as List? ?? []).map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      "${item['quantidade']}x ${item['nome']} - R\$ ${(item['preco'] * item['quantidade']).toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
