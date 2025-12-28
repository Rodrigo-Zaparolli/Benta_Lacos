import 'package:cloud_firestore/cloud_firestore.dart';

class RelatoriosMock {
  static List<Map<String, dynamic>> get dadosManuais => [
    {
      'total': 35420.0,
      'metodoPagamento': 'PIX',
      'nomeCliente': 'Maria Silva',
      'data': Timestamp.now(),
      'itens': [
        {'nome': 'Laço Luxo Red', 'categoria': 'Laços', 'preco': 150.0},
        {'nome': 'Tiara Floral', 'categoria': 'Tiaras', 'preco': 100.0},
      ],
    },
    {
      'total': 12500.0,
      'metodoPagamento': 'Cartão',
      'nomeCliente': 'Ana Souza',
      'data': Timestamp.now(),
      'itens': [
        {'nome': 'Kit Presilhas', 'categoria': 'Kits', 'preco': 85.50},
      ],
    },
  ];
}
