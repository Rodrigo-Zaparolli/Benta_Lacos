import 'package:flutter/material.dart';
import '../checkout/checkout_page.dart';

class PixPaymentPage extends StatelessWidget {
  final String nomeCliente;
  const PixPaymentPage({super.key, required this.nomeCliente});
  @override
  Widget build(BuildContext context) => const CheckoutPage();
}
