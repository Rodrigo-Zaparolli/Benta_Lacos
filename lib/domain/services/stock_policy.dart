int stockDirection({required bool deducted, required String status}) {
  if (!deducted &&
      (status == 'Pago' || status == 'Enviado' || status == 'Entregue'))
    return -1;
  if (deducted &&
      (status == 'Cancelado' || status == 'Excluido' || status == 'Pendente'))
    return 1;
  return 0;
}

int checkedStock(
  int available,
  int quantity,
  int direction,
  String productName,
) {
  final next = available + direction * quantity;
  if (quantity < 1 || next < 0)
    throw StateError('Estoque insuficiente para $productName.');
  return next;
}
