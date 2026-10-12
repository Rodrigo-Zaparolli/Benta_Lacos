import 'package:flutter/material.dart';
import '../../../domain/services/order_policy.dart';

class OrderStatusDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderStatusDialog({super.key, required this.order});
  @override
  State<OrderStatusDialog> createState() => _OrderStatusDialogState();
}

class _OrderStatusDialogState extends State<OrderStatusDialog> {
  final _form = GlobalKey<FormState>();
  String? _next;
  @override
  Widget build(BuildContext context) {
    final current = '${widget.order['status'] ?? 'Pendente'}';
    return AlertDialog(
      title: const Text('Alterar status do pedido'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status atual: $current'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Novo status',
                errorMaxLines: 3,
              ),
              items:
                  allowedOrderStatuses(
                        current,
                        pickup:
                            widget.order['metodoEnvio'] == 'Retirar na loja',
                      )
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
              onChanged: (value) => _next = value,
              validator: (value) {
                if (value == null) return 'Selecione o novo status.';
                if (value == 'Pago' && widget.order['freteACombinar'] == true) {
                  return 'Informe o frete ou escolha Retirar na loja antes de marcar como pago.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Pagamento e envio serão confirmados na próxima etapa.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Voltar'),
        ),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) Navigator.pop(context, _next);
          },
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}
