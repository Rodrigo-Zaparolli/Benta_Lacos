import 'package:cloud_firestore/cloud_firestore.dart';

class PedidoModel {
  final String id;
  final String nomeCliente;
  final List<Map<String, dynamic>> itens;
  final double total;
  final double frete;
  final String metodoPagamento;
  final String endereco;
  final DateTime dataPedido;

  PedidoModel({
    required this.id,
    required this.nomeCliente,
    required this.itens,
    required this.total,
    required this.frete,
    required this.metodoPagamento,
    required this.endereco,
    required this.dataPedido,
  });

  factory PedidoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PedidoModel(
      id: doc.id,
      nomeCliente: data['nomeCliente'] ?? '',
      itens: List<Map<String, dynamic>>.from(data['itens'] ?? []),
      total: (data['total'] as num).toDouble(),
      frete: (data['valorFrete'] as num?)?.toDouble() ?? 0.0,
      metodoPagamento: data['metodoPagamento'] ?? '',
      endereco: data['enderecoExibicao'] ?? '',
      dataPedido: (data['dataPedido'] as Timestamp).toDate(), // 🔥 GARANTIDO
    );
  }
}
