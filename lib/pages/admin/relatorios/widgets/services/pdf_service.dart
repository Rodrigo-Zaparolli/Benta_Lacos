import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfService {
  /// Gera o PDF corrigindo o erro de data vazia e personalizando o cabeçalho
  static Future<void> gerarRelatorioPedidos(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final pdf = pw.Document();

    // Carregamento de fontes para suportar R$ e acentos
    final fontData = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final formatadorMoeda = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final formatadorData = DateFormat('dd/MM/yyyy HH:mm');

    // Cálculos de Faturamento e Clientes
    double faturamento = 0;
    Set<String> clientesUnicos = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      faturamento += (data['total'] ?? 0).toDouble();
      clientesUnicos.add(data['nomeCliente']?.toString() ?? "Desconhecido");
    }

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: fontData, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // CABEÇALHO ATUALIZADO
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Relatório de Vendas - Benta Laços",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),

          // QUADRO DE RESUMO
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _colunaResumo("Pedidos", docs.length.toString()),
                _colunaResumo("Clientes", clientesUnicos.length.toString()),
                _colunaResumo(
                  "Faturamento",
                  formatadorMoeda.format(faturamento),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 25),

          // TABELA COM CORREÇÃO DE DATA
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headers: ['Data do Pedido', 'Cliente', 'Valor Total'],
            data: docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;

              // Tenta ler 'dataHora' ou 'data' para evitar o "-"
              dynamic dataBruta = d['dataHora'] ?? d['data'];
              String dataTexto = "-";

              if (dataBruta != null) {
                if (dataBruta is Timestamp) {
                  dataTexto = formatadorData.format(dataBruta.toDate());
                } else if (dataBruta is String) {
                  dataTexto = dataBruta;
                }
              }

              return [
                dataTexto,
                d['nomeCliente'] ?? "Consumidor",
                formatadorMoeda.format(d['total'] ?? 0.0),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'relatorio_benta_lacos.pdf',
    );
  }

  static pw.Widget _colunaResumo(String titulo, String valor) {
    return pw.Column(
      children: [
        pw.Text(
          titulo,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.Text(
          valor,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
}
