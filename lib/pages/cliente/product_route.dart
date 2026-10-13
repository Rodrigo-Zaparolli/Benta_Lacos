import 'package:benta_lacos/core/config/store_environment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/models/product_model.dart';
import '../../domain/catalog/lacos.dart';

class ProductRoute extends StatelessWidget {
  final String id;
  const ProductRoute({super.key, required this.id});
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: StoreEnvironment.database
            .collection(StoreEnvironment.collectionName('produtos'))
            .doc(id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData &&
              snapshot.data!.exists &&
              snapshot.data!.data()?['isArchived'] != true) {
            return LacoPage(
              product: Product.fromMap(snapshot.data!.data()!, id),
            );
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Benta Laços')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            snapshot.hasError
                                ? 'Não foi possível carregar este produto.'
                                : 'Este produto não está disponível.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/colecao'),
                            child: const Text('Explorar a coleção'),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      );
}
