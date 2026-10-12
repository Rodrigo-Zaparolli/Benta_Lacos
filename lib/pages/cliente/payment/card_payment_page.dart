import 'package:flutter/material.dart';
import '../checkout/checkout_page.dart';

/// Compatibility entry point for the single, assisted checkout flow.
class CardPaymentPage extends StatelessWidget {
  final String nomeCliente;
  final bool isCredito;
  const CardPaymentPage({
    super.key,
    required this.nomeCliente,
    required this.isCredito,
  });
  @override
  Widget build(BuildContext context) => const CheckoutPage();
}
