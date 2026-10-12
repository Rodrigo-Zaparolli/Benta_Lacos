import 'package:benta_lacos/domain/models/product_model.dart';
import 'package:benta_lacos/domain/providers/cart_provider.dart';
import 'package:benta_lacos/domain/services/order_service.dart';
import 'package:benta_lacos/domain/services/admin_metrics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class _Firestore extends Fake implements FirebaseFirestore {
  final Object? networkError;
  final transaction = _Transaction();
  _Firestore({this.networkError});

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(path);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    if (networkError != null) throw networkError!;
    try {
      return await transactionHandler(transaction);
    } on StateError {
      // Reproduce the web bridge replacing a Dart error with a JS error.
      throw Exception('Dart exception thrown from converted Future');
    }
  }
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final String path;
  _Collection(this.path);
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Reference('${this.path}/$path');
}

class _Reference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  @override
  final String path;
  _Reference(this.path);
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection('${this.path}/$path');
}

class _Snapshot<T> extends Fake implements DocumentSnapshot<T> {
  final T? value;
  _Snapshot(this.value);
  @override
  bool get exists => value != null;
  @override
  T? data() => value;
  @override
  String get id => 'faixa';
}

class _Transaction extends Fake implements Transaction {
  final writes = <String, Object?>{};
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> reference,
  ) async => _Snapshot<T>(
    reference.path.startsWith('produtos/')
        ? {'quantity': -14, 'price': 11.58, 'name': 'Faixa'} as T
        : null,
  );
  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    writes[ref.path] = data;
    return this;
  }

  @override
  Transaction delete(DocumentReference<Object?> ref) {
    writes[ref.path] = null;
    return this;
  }
}

void main() {
  final items = [
    CartItem(
      product: Product(
        id: 'faixa',
        name: 'Faixa',
        price: 11.58,
        description: '',
        color: '',
        composition: '',
        quantity: 1,
      ),
    ),
  ];
  Future<Map<String, dynamic>> request(
    FirebaseFirestore firestore, {
    bool testMode = false,
  }) => OrderService(firestore, testMode: testMode).createRequest(
    id: 'test-order',
    uid: 'test-customer',
    items: items,
    customer: {'nome': 'Teste'},
    delivery: 'Retirar na loja',
    payment: 'Pix',
  );

  test(
    'web transaction preserves insufficient stock message without writes',
    () async {
      final firestore = _Firestore();
      await expectLater(
        request(firestore),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Estoque insuficiente para Faixa. Revise o carrinho.',
          ),
        ),
      );
      expect(firestore.transaction.writes, isEmpty);
    },
  );

  test(
    'test checkout accepts unavailable stock and labels order without product writes',
    () async {
      final firestore = _Firestore();
      final order = await request(firestore, testMode: true);
      expect(order['pedidoTeste'], true);
      expect(order['estoqueBaixado'], false);
      expect(order['total'], 11.58);
      expect(firestore.transaction.writes.keys, contains('pedidos/test-order'));
      expect(
        firestore.transaction.writes.keys,
        contains('pedidos/test-order/itens/faixa'),
      );
      expect(order['produtoIds'], ['faixa']);
      expect(order['arquivado'], false);
      expect(
        firestore.transaction.writes.keys.any((p) => p.startsWith('produtos/')),
        false,
      );
    },
  );

  test('test orders do not affect sales, units or pending values', () {
    final metrics = AdminMetrics.fromOrders([
      {'pedidoTeste': true, 'status': 'Pago', 'total': 100},
      {'pedidoTeste': true, 'status': 'Pendente', 'total': 200},
      {'status': 'Pago', 'total': 30},
    ]);
    expect(metrics.orders.length, 1);
    expect(metrics.revenue, 30);
    expect(metrics.pendingValue, 0);
    expect(metrics.units, 0);
  });

  test('Firebase failures retain their original code', () async {
    final error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );
    await expectLater(
      request(_Firestore(networkError: error)),
      throwsA(same(error)),
    );
  });
}
