import 'package:benta_lacos/core/config/store_environment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido_model.dart';

class PedidoRepository {
  final _db = StoreEnvironment.database;

  Future<PedidoModel> buscarPedidoPorId(String pedidoId) async {
    final doc = await _db.collection('pedidos').doc(pedidoId).get();
    return PedidoModel.fromFirestore(doc);
  }
}
