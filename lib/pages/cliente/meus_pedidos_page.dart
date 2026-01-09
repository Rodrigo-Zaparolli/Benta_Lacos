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
                            'Você precisa estar logado para ver seus pedidos.',
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
                              return Center(
                                child: Text(
                                  'Erro ao carregar pedidos: ${snapshot.error}',
                                ),
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final pedidos = snapshot.data?.docs ?? [];

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
                                final doc = pedidos[index];
                                final pedido =
                                    doc.data() as Map<String, dynamic>;

                                return _OrderCard(
                                  pedidoId: doc.id,
                                  pedido: pedido,
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
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'Você ainda não realizou nenhum pedido.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// =======================================================
/// CARD DO PEDIDO
/// =======================================================
class _OrderCard extends StatelessWidget {
  final String pedidoId;
  final Map<String, dynamic> pedido;

  const _OrderCard({required this.pedidoId, required this.pedido});

  /// 🔒 Resolve data de forma segura (TELA + PDF)
  DateTime _resolverDataPedido() {
    final raw = pedido['dataPedido'];

    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();

    return DateTime.now();
  }

  /// 📄 Gera PDF
  Future<void> _gerarPdf() async {
    final DateTime dataPedido = _resolverDataPedido();

    await PdfServiceCliente.gerarComprovantePedido(
      pedidoId: pedidoId,
      nomeCliente: pedido['nomeCliente'] ?? 'Cliente',
      itens: pedido['itens'] as List? ?? [],
      total: (pedido['total'] as num? ?? 0).toDouble(),
      frete: (pedido['frete'] as num? ?? 0).toDouble(),
      metodoPagamento: pedido['metodoPagamento'] ?? 'Não informado',
      enderecoCompleto: pedido['enderecoExibicao'] ?? 'Endereço não informado',
      dataPedido: Timestamp.fromDate(dataPedido), // 🔥 GARANTIDO
    );
  }

  Color _statusColor(String status) {
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
    final DateTime dataPedido = _resolverDataPedido();
    final String dataFormatada = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(dataPedido);

    final String status = pedido['status'] ?? 'Pendente';
    final double total = (pedido['total'] as num? ?? 0).toDouble();
    final Color statusColor = _statusColor(status);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(Icons.shopping_basket, color: statusColor),
        title: Text('Pedido #${pedidoId.substring(0, 8).toUpperCase()}'),
        subtitle: Text('Data: $dataFormatada'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'R\$ ${total.toStringAsFixed(2)}',
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Itens:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: _gerarPdf,
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('PDF'),
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
                  final double totalItem =
                      ((item['preco'] ?? 0) * (item['quantidade'] ?? 1))
                          .toDouble();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${item['quantidade']}x ${item['nome']} - '
                      'R\$ ${totalItem.toStringAsFixed(2)}',
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
