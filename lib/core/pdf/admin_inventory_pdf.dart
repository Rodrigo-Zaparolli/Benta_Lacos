import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/product_model.dart';
import '../../shared/utils/store_format.dart';

class AdminInventoryPdf {
  static Future<Uint8List> build(
    List<Product> products, {
    String filters = 'Produtos ativos',
  }) async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Montserrat.ttf'),
    );
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );
    final units = products.fold<int>(0, (n, p) => n + p.quantity);
    final value = products.fold<double>(0, (n, p) => n + p.price * p.quantity);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 100,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Text(
            'Benta Laços - Inventário',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text(filters),
          pw.Text('${products.length} produtos • $units unidades'),
          pw.Text('Valor a preço de venda: ${formatMoney(value)}'),
          pw.Text('Este valor não representa custo nem lucro.'),
          pw.SizedBox(height: 20),
          if (products.isEmpty)
            pw.Text('Nenhum produto nesta seleção.')
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'Produto',
                'Categoria',
                'Preço',
                'Unidades',
                'Situação',
              ],
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              data: products
                  .map(
                    (p) => [
                      p.name,
                      p.category ?? '—',
                      formatMoney(p.price),
                      '${p.quantity}',
                      p.isArchived
                          ? 'Arquivado'
                          : p.quantity == 0
                          ? 'Sem estoque'
                          : p.quantity <= 5
                          ? 'Estoque baixo'
                          : 'Disponível',
                    ],
                  )
                  .toList(),
            ),
        ],
      ),
    );
    return pdf.save();
  }

  static Future<void> export(
    List<Product> products, {
    String filters = 'Produtos ativos',
  }) async {
    final bytes = await build(products, filters: filters);
    await Printing.layoutPdf(
      name: 'Benta_Lacos_Inventario.pdf',
      onLayout: (_) async => bytes,
    );
  }
}
