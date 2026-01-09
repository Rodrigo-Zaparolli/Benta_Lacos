import 'package:benta_lacos/shared/theme/tema_site.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pdf_helper.dart';

class ClientesPdf {
  static final _dataFmt = DateFormat('dd/MM/yyyy HH:mm');

  static Future<void> gerar(List<QueryDocumentSnapshot> clientes) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => PdfHelper.buildHeader(
          "RELATÓRIO GERAL DE CLIENTES",
          _dataFmt.format(DateTime.now()),
        ),
        build: (context) => [
          _buildResumo(clientes.length),
          pw.SizedBox(height: 15),
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(
                color: PdfColors.grey200,
                width: 0.5,
              ),
              bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(25), // Contador/Indicador
              1: const pw.FlexColumnWidth(2.5), // Nome
              2: const pw.FlexColumnWidth(2), // Localidade
              3: const pw.FixedColumnWidth(100), // Telefone
            },
            children: [
              // Cabeçalho
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(TemaAdmin.PdfOne.value),
                ),
                children: [
                  _cell(
                    "#",
                    bol: true,
                    white: true,
                    align: pw.Alignment.center,
                  ),
                  _cell("CLIENTE", bol: true, white: true),
                  _cell("CIDADE/BAIRRO", bol: true, white: true),
                  _cell(
                    "CONTATO",
                    bol: true,
                    white: true,
                    align: pw.Alignment.center,
                  ),
                ],
              ),
              // Linhas
              ...List.generate(clientes.length, (index) {
                final c = clientes[index].data() as Map<String, dynamic>;
                String nome = "${c['nome'] ?? ''} ${c['sobrenome'] ?? ''}"
                    .trim()
                    .toUpperCase();
                String local = "${c['cidade'] ?? 'S/C'} - ${c['bairro'] ?? ''}";
                String tel = c['telefone'] ?? '---';

                // Ênfase nos 10 primeiros (mais recentes)
                bool emDestaque = index < 10;

                return pw.TableRow(
                  decoration: emDestaque
                      ? pw.BoxDecoration(
                          color: PdfColors.blue50,
                        ) // Fundo leve para destaque
                      : null,
                  children: [
                    _cell(
                      "${index + 1}",
                      fontSize: 7,
                      align: pw.Alignment.center,
                      bol: emDestaque,
                    ),
                    _cell(
                      nome.isEmpty ? "SEM NOME" : nome,
                      fontSize: 8,
                      bol: emDestaque,
                    ),
                    _cell(local, fontSize: 8),
                    _cell(
                      tel,
                      fontSize: 8,
                      align: pw.Alignment.center,
                      bol: emDestaque,
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

  static pw.Widget _buildResumo(int total) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            "TOTAL DE CLIENTES CADASTRADOS: ",
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "$total",
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.blue700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Text(
            "* Itens em azul representam os 10 últimos cadastros",
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(
    String txt, {
    bool bol = false,
    bool white = false,
    pw.Alignment align = pw.Alignment.centerLeft,
    double fontSize = 9,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          txt,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bol ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: white ? PdfColors.white : PdfColors.black,
          ),
        ),
      ),
    );
  }
}
