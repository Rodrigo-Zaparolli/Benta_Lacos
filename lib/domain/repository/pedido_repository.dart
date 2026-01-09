import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido_model.dart';

class PedidoRepository {
  final _db = FirebaseFirestore.instance;

  Future<PedidoModel> buscarPedidoPorId(String pedidoId) async {
    final doc = await _db.collection('pedidos').doc(pedidoId).get();
    return PedidoModel.fromFirestore(doc);
  }
}
