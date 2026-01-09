import 'package:benta_lacos/shared/theme/tema_site.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'pdf_helper.dart';

class EstoquePdf {
  static final _moeda = NumberFormat.simpleCurrency(locale: 'pt_BR');
  static final _dataFmt = DateFormat('dd/MM/yyyy HH:mm');

  static Future<void> gerar(
    List<QueryDocumentSnapshot> produtos,
    String categoria,
  ) async {
    final pdf = pw.Document();

    // 1. FILTRAGEM (Garante que os dados existem)
    final filtrados = produtos.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      String catProd = (data['categoria'] ?? data['category'] ?? "").toString();
      return catProd.toLowerCase() == categoria.toLowerCase();
    }).toList();

    Map<String, pw.MemoryImage?> imagensCarregadas = {};
    double valorTotalEstoque = 0;
    int qtdTotalEstoque = 0;

    // 2. PROCESSAMENTO COM CAPTURA SEGURA
    for (var doc in filtrados) {
      final d = doc.data() as Map<String, dynamic>;

      // Captura Inteligente de Nome
      String nome = (d['nome'] ?? d['name'] ?? d['produto'] ?? "SEM NOME")
          .toString()
          .toUpperCase();

      // Captura Inteligente de Quantidade (tenta converter de qualquer formato)
      var rawQtd = d['quantidade'] ?? d['quantity'] ?? 0;
      int q = int.tryParse(rawQtd.toString()) ?? 0;

      // Captura Inteligente de Preço
      var rawPreco = d['preco'] ?? d['price'] ?? 0.0;
      double p = double.tryParse(rawPreco.toString()) ?? 0.0;

      qtdTotalEstoque += q;
      valorTotalEstoque += (q * p);

      // Carregamento da Imagem
      String? url = d['urlImagem'] ?? d['foto'] ?? d['url'];
      if (url != null && url.isNotEmpty) {
        try {
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            imagensCarregadas[doc.id] = pw.MemoryImage(response.bodyBytes);
          }
        } catch (e) {
          print("Erro imagem: $e");
        }
      }
    }

    // 3. CONSTRUÇÃO DO PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => PdfHelper.buildHeader(
          "INVENTÁRIO - ${categoria.toUpperCase()}",
          _dataFmt.format(DateTime.now()),
        ),
        build: (context) => [
          // Seção de Cards (Resumo Superior)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _metricCard(
                "MODELOS",
                "${filtrados.length}",
                TemaAdmin.PdfFive.value,
              ),
              _metricCard(
                "QTD TOTAL",
                "$qtdTotalEstoque un",
                TemaAdmin.PdfSix.value,
              ),
              _metricCard(
                "VALOR TOTAL",
                _moeda.format(valorTotalEstoque),
                TemaAdmin.PdfSeven.value,
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Tabela de Itens
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(
                color: PdfColors.grey200,
                width: 0.5,
              ),
              bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(40), // Foto
              1: const pw.FlexColumnWidth(3), // Nome
              2: const pw.FixedColumnWidth(50), // Qtd
              3: const pw.FixedColumnWidth(80), // Unitário
              4: const pw.FixedColumnWidth(90), // Total
            },
            children: [
              // Cabeçalho da Tabela
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(TemaAdmin.PdfOne.value),
                ),
                children: [
                  _cell("FOTO", b: true, w: true, a: pw.Alignment.center),
                  _cell("PRODUTO", b: true, w: true),
                  _cell("QTD", b: true, w: true, a: pw.Alignment.center),
                  _cell("UNIT.", b: true, w: true),
                  _cell("TOTAL", b: true, w: true, a: pw.Alignment.centerRight),
                ],
              ),
              // Linhas de Produtos
              ...filtrados.map((doc) {
                final d = doc.data() as Map<String, dynamic>;

                // Repetindo a lógica de captura segura por linha
                String n = (d['nome'] ?? d['name'] ?? "ITEM")
                    .toString()
                    .toUpperCase();
                int q =
                    int.tryParse(
                      (d['quantidade'] ?? d['quantity'] ?? 0).toString(),
                    ) ??
                    0;
                double p =
                    double.tryParse(
                      (d['preco'] ?? d['price'] ?? 0.0).toString(),
                    ) ??
                    0.0;

                return pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Container(
                        width: 35,
                        height: 35,
                        color: PdfColors.grey100,
                        child: imagensCarregadas[doc.id] != null
                            ? pw.Image(
                                imagensCarregadas[doc.id]!,
                                fit: pw.BoxFit.cover,
                              )
                            : pw.Center(
                                child: pw.Text(
                                  "S/F",
                                  style: const pw.TextStyle(fontSize: 5),
                                ),
                              ),
                      ),
                    ),
                    _cell(n, f: 8),
                    _cell(q.toString(), a: pw.Alignment.center),
                    _cell(_moeda.format(p)),
                    _cell(
                      _moeda.format(q * p),
                      b: true,
                      a: pw.Alignment.centerRight,
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (f) async => pdf.save());
  }

  // Métodos auxiliares para garantir que o layout não quebre
  static pw.Widget _metricCard(String label, String value, int colorInt) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(colorInt),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.white),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _cell(
    String t, {
    bool b = false,
    bool w = false,
    pw.Alignment a = pw.Alignment.centerLeft,
    double f = 9,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Align(
        alignment: a,
        child: pw.Text(
          t,
          style: pw.TextStyle(
            fontSize: f,
            fontWeight: b ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: w ? PdfColors.white : PdfColors.black,
          ),
        ),
      ),
    );
  }
}
