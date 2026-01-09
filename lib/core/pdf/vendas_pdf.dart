import 'package:benta_lacos/shared/theme/tema_site.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pdf_helper.dart';

class VendasPdf {
  static final _moeda = NumberFormat.simpleCurrency(locale: 'pt_BR');
  static final _dataFmt = DateFormat('dd/MM/yyyy HH:mm');

  // Conversão de cores do seu TemaAdmin para o formato PDF
  static final PdfColor corPrimaria = PdfColor.fromInt(
    TemaAdmin.PdfPrimary.value,
  );
  static final PdfColor corTextoDestaque = PdfColor.fromInt(
    TemaAdmin.PdfonPrimary.value,
  );
  static final PdfColor corFundoTabela = PdfColor.fromInt(
    TemaAdmin.PdfOne.value,
  );
  static final PdfColor corBarras = PdfColor.fromInt(TemaAdmin.PdfThree.value);

  static Future<void> gerar(
    List<QueryDocumentSnapshot> docs, {
    int? mes,
    int? ano,
    String? categoria,
  }) async {
    final pdf = pw.Document();

    // --- 1. FILTRAGEM ---
    final filtrados = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      Timestamp? ts = data['dataPedido'] ?? data['dataHora'];
      if (ts == null) return false;
      DateTime dt = ts.toDate();
      bool bateMes = mes == null || dt.month == mes;
      bool bateAno = ano == null || dt.year == ano;

      bool bateCat = true;
      if (categoria != null && categoria.isNotEmpty && categoria != "Todas") {
        List itens = data['itens'] ?? [];
        bateCat = itens.any(
          (i) =>
              (i['categoria'] ?? i['category'] ?? "")
                  .toString()
                  .toLowerCase() ==
              categoria.toLowerCase(),
        );
      }
      return bateMes && bateAno && bateCat;
    }).toList();

    // --- 2. CÁLCULOS E CONTADORES ---
    double bruto = 0;
    int totalItensGeral = 0;
    Map<String, int> produtosCount = {};
    Map<String, double> pagamentos = {};

    for (var doc in filtrados) {
      final data = doc.data() as Map<String, dynamic>;
      double total = (data['total'] ?? 0).toDouble();
      bruto += total;

      List itens = data['itens'] ?? [];
      for (var item in itens) {
        int qtd = (item['quantidade'] ?? 0) is int
            ? item['quantidade']
            : int.parse(item['quantidade'].toString());
        String nomeProd = item['nome'] ?? "Produto Indefinido";

        totalItensGeral += qtd;
        produtosCount[nomeProd] = (produtosCount[nomeProd] ?? 0) + qtd;
      }

      String metodo = data['metodoPagamento'] ?? 'Pix';
      pagamentos[metodo] = (pagamentos[metodo] ?? 0) + total;
    }

    double taxas = bruto * 0.04;
    double liquido = bruto - taxas;

    // --- 3. LAYOUT DO PDF ---
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => PdfHelper.buildHeader(
          "Relatório Gerencial",
          _dataFmt.format(DateTime.now()),
        ),
        build: (context) => [
          // CARDS DE MÉTRICAS (Expandidos e com cores do tema)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: PdfHelper.buildMetricCard(
                  "BRUTO",
                  _moeda.format(bruto),
                  PdfColor.fromInt(TemaAdmin.PdfSeven.value),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: PdfHelper.buildMetricCard(
                  "TAXAS",
                  "- ${_moeda.format(taxas)}",
                  PdfColor.fromInt(TemaAdmin.PdfThree.value),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: PdfHelper.buildMetricCard(
                  "LÍQUIDO",
                  _moeda.format(liquido),
                  PdfColor.fromInt(TemaAdmin.PdfFour.value),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 25),

          pw.Text(
            "ANÁLISE DE VENDAS",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 13,
              color: corTextoDestaque,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Lado Esquerdo: Barras de Pagamento
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  children: pagamentos.entries
                      .map((e) => _buildBarraMetodo(e.key, e.value, bruto))
                      .toList(),
                ),
              ),
              pw.SizedBox(width: 25),

              // Lado Direito: Quadro Geral de Itens (Aumentado)
              pw.Container(
                width: 210,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 1),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "Geral",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        pw.Text(
                          totalItensGeral.toString(),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    pw.Divider(thickness: 1, color: PdfColors.grey300),
                    ...produtosCount.entries.map(
                      (e) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                e.key,
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.Text(
                              e.value.toString(),
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 25),

          pw.Text(
            "DETALHAMENTO DOS PEDIDOS",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 13,
              color: corTextoDestaque,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildTabelaPedidos(filtrados),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (f) async => pdf.save());
  }

  // Widget das Barras de Pagamento
  static pw.Widget _buildBarraMetodo(String label, double valor, double total) {
    double percent = total > 0 ? (valor / total) : 0;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 55,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          ),
          pw.Expanded(
            child: pw.Stack(
              children: [
                pw.Container(
                  height: 7,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                ),
                pw.Container(
                  height: 7,
                  width: percent * 180,
                  decoration: pw.BoxDecoration(
                    color: corBarras,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(
            width: 75,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                _moeda.format(valor),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget da Tabela de Pedidos
  static pw.Widget _buildTabelaPedidos(List<QueryDocumentSnapshot> docs) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      columnWidths: {
        0: const pw.FixedColumnWidth(60), // PEDIDO (Aumentado)
        1: const pw.FixedColumnWidth(85), // DATA
        2: const pw.FixedColumnWidth(110), // CLIENTE (Aumentado)
        3: const pw.FlexColumnWidth(1.5), // ITENS (Diminuído/Ajustado)
        4: const pw.FixedColumnWidth(75), // TOTAL
      },
      children: [
        // Cabeçalho da Tabela
        pw.TableRow(
          decoration: pw.BoxDecoration(color: corFundoTabela),
          children: [
            PdfHelper.pTabela("PEDIDO", bol: true, color: PdfColors.white),
            PdfHelper.pTabela("DATA", bol: true, color: PdfColors.white),
            PdfHelper.pTabela("CLIENTE", bol: true, color: PdfColors.white),
            PdfHelper.pTabela("ITENS / VR", bol: true, color: PdfColors.white),
            PdfHelper.pTabela("TOTAL", bol: true, color: PdfColors.white),
          ],
        ),
        // Linhas de Dados
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String numPedido =
              data['numeroPedido']?.toString() ??
              doc.id.substring(0, 7).toUpperCase();
          List itens = data['itens'] ?? [];

          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              PdfHelper.pTabela(numPedido),
              PdfHelper.pTabela(
                _dataFmt.format((data['dataPedido'] as Timestamp).toDate()),
              ),
              PdfHelper.pTabela(
                data['nomeCliente']?.toString().toUpperCase() ?? 'N/A',
              ),
              // Coluna de Itens e Valores (Compactada)
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: itens.map((i) {
                    double preco = (i['preco'] ?? 0).toDouble();
                    int qtd = (i['quantidade'] ?? 1) is int
                        ? i['quantidade']
                        : int.parse(i['quantidade'].toString());
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "${qtd}x ${i['nome']}",
                          style: const pw.TextStyle(fontSize: 6.5),
                        ), // Fonte menor para itens
                        pw.Text(
                          _moeda.format(preco * qtd),
                          style: const pw.TextStyle(
                            fontSize: 6.5,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              PdfHelper.pTabela(
                _moeda.format(data['total'] ?? 0),
                bol: true,
                align: pw.Alignment.centerRight,
              ),
            ],
          );
        }),
      ],
    );
  }
}
