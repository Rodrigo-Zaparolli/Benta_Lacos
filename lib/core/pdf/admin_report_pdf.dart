import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/services/admin_metrics.dart';
import '../../shared/utils/store_format.dart';

class AdminReportPdf {
  static Future<Uint8List> build(
    List<Map<String, dynamic>> orders, {
    String period = 'Todo o período',
  }) async {
    final metrics = AdminMetrics.fromOrders(orders);
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Montserrat.ttf'),
    );
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 100,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Text(
            'Benta Laços - Relatório de vendas',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text(period),
          pw.Text(
            'Período pela data de criação dos pedidos. Valores confirmados incluem frete registrado.',
          ),
          pw.SizedBox(height: 20),
          pw.Text('Valores confirmados: ${formatMoney(metrics.revenue)}'),
          pw.Text('Pedidos confirmados: ${metrics.confirmed.length}'),
          pw.Text('Unidades vendidas: ${metrics.units}'),
          pw.Text('Valores pendentes: ${formatMoney(metrics.pendingValue)}'),
          pw.Text(
            'Taxas registradas: ${formatMoney(metrics.fees)} (sem estimativas automáticas)',
          ),
          pw.SizedBox(height: 20),
          if (metrics.confirmed.isEmpty)
            pw.Text('Nenhum pedido confirmado neste período.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Pedido', 'Cliente', 'Status', 'Valor'],
              data: metrics.confirmed
                  .map(
                    (o) => [
                      '${o['pedidoId'] ?? o['id'] ?? ''}',
                      '${o['nomeCliente'] ?? ''}',
                      '${o['status'] ?? ''}',
                      formatMoney(o['total'] as num? ?? 0),
                    ],
                  )
                  .toList(),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Produtos vendidos',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          ...metrics.products.entries.map(
            (e) => pw.Text('${e.key}: ${e.value} unidades'),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  static Future<void> export(
    List<Map<String, dynamic>> orders, {
    String period = 'Todo o período',
  }) async {
    final bytes = await build(orders, period: period);
    await Printing.layoutPdf(
      name: 'Benta_Lacos_Vendas.pdf',
      onLayout: (_) async => bytes,
    );
  }
}
