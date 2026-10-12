import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/services/admin_metrics.dart';
import 'admin_report_pdf.dart';

class VendasPdf {
  static Future<void> gerar(
    List<QueryDocumentSnapshot> docs, {
    int? mes,
    int? ano,
    String? categoria,
  }) async {
    final orders = docs
        .map((d) => {...Map<String, dynamic>.from(d.data() as Map), 'id': d.id})
        .where((o) {
          final date = recordDate(
            o['dataPedido'] ?? o['data'] ?? o['dataHora'],
          );
          if ((mes != null || ano != null) && date == null) return false;
          if (mes != null && date!.month != mes) return false;
          if (ano != null && date!.year != ano) return false;
          if (categoria != null &&
              categoria.isNotEmpty &&
              categoria != 'Todas') {
            return (o['itens'] as List? ?? []).any(
              (i) =>
                  (i['categoria'] ?? i['category'] ?? '')
                      .toString()
                      .toLowerCase() ==
                  categoria.toLowerCase(),
            );
          }
          return true;
        })
        .toList();
    await AdminReportPdf.export(
      orders,
      period:
          '${mes == null ? 'Todos os meses' : 'Mês $mes'}${ano == null ? '' : ' / $ano'}',
    );
  }
}
