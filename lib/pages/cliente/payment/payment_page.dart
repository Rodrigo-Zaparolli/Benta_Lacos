import 'package:flutter/material.dart';
import '../../../domain/providers/cart_provider.dart';
import '../checkout/checkout_page.dart';

class PaymentPage extends StatelessWidget {
  final CartProvider cart;
  final String nomeCliente;
  final String cepCliente;
  const PaymentPage({
    super.key,
    required this.cart,
    required this.nomeCliente,
    required this.cepCliente,
  });
  @override
  Widget build(BuildContext context) => const CheckoutPage();
}
