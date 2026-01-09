import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfHelper {
  // Cabeçalho com Título, Versão e Data de Geração
  static pw.Widget buildHeader(String titulo, String dataGeracao) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Relatório Gerencial",
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
                pw.Text(
                  "Benta Laços v2.0",
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Text(
              "BENTA LAÇOS",
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#BC0B6F'),
              ),
            ),
            pw.Text(
              "Gerado em: $dataGeracao",
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            titulo,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Divider(color: PdfColor.fromHex('#BC0B6F'), thickness: 1),
        pw.SizedBox(height: 15),
      ],
    );
  }

  // Cards de Métricas (Bruto, Taxas, Líquido)
  static pw.Widget buildMetricCard(String label, String valor, PdfColor cor) {
    return pw.Container(
      width: 170,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: cor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(color: PdfColors.white, fontSize: 8),
          ),
          pw.Text(
            valor,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Célula da Tabela
  static pw.Widget pTabela(
    String h, {
    bool bol = false,
    PdfColor color = PdfColors.black,
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          h,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: bol ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ),
    );
  }
}
