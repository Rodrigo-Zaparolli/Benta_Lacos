import 'package:cloud_firestore/cloud_firestore.dart';

class Depoimento {
  final String id;
  final String texto;
  final String cliente;
  final int estrelas;
  final String? fotoUrl;
  final bool aprovado;

  const Depoimento({
    required this.id,
    required this.texto,
    required this.cliente,
    required this.estrelas,
    this.fotoUrl,
    this.aprovado = false,
  });

  // Converte um documento do Firebase para o objeto Depoimento
  factory Depoimento.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Depoimento(
      id: doc.id,
      texto: data['texto'] ?? '',
      cliente: data['cliente'] ?? 'Anônimo',
      estrelas: data['estrelas'] ?? 5,
      fotoUrl: data['fotoUrl'],
      aprovado: data['aprovado'] ?? false,
    );
  }
}
