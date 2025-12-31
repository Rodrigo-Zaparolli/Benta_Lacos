import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class PdfServiceCliente {
  static Future<void> gerarComprovantePedido({
    required String pedidoId,
    required String nomeCliente,
    required List<dynamic> itens,
    required double total,
    required double frete,
    required String metodoPagamento,
    required String enderecoCompleto,
  }) async {
    final pdf = pw.Document();
    Map<String, Uint8List?> imagensBytes = {};

    // 1. Pré-carregamento das imagens com tratamento de erro
    for (var item in itens) {
      String? url;
      String id;

      if (item is Map) {
        url = item['imageUrl'];
        id = item['id'] ?? item['nome'];
      } else {
        url = item.product.imageUrl;
        id = item.product.id;
      }

      if (url != null && url.isNotEmpty) {
        try {
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            imagensBytes[id] = response.bodyBytes;
          }
        } catch (e) {
          print("Erro ao carregar imagem no PDF: $e");
        }
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // CABEÇALHO
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "BENTA LAÇOS",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#E91E63'),
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Pedido #${pedidoId.toUpperCase().substring(0, 8)}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        "Data: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // BOX DADOS DO CLIENTE
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "DADOS DO CLIENTE",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      "Nome: $nomeCliente",
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      "Endereço: $enderecoCompleto",
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      "Pagamento: $metodoPagamento",
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // CABEÇALHO DA TABELA
              pw.Container(
                color: PdfColor.fromHex('#E91E63'),
                padding: const pw.EdgeInsets.all(5),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 40,
                      child: pw.Text(
                        "Foto",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10),
                        child: pw.Text(
                          "Produto",
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(
                      width: 40,
                      child: pw.Text(
                        "Qtd",
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        "Unidade",
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        "Total",
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // LISTA DE PRODUTOS
              ...itens.map((item) {
                final String nome = item is Map
                    ? item['nome']
                    : item.product.name;
                final int qtd = item is Map
                    ? item['quantidade']
                    : item.quantity;
                final double preco = item is Map
                    ? (item['preco'] as num).toDouble()
                    : item.product.price;
                final String id = item is Map
                    ? (item['id'] ?? item['nome'])
                    : item.product.id;
                final bytes = imagensBytes[id];

                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey200),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      // Miniatura
                      pw.Container(
                        width: 40,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          borderRadius: pw.BorderRadius.circular(2),
                          color: PdfColors.grey200,
                        ),
                        child: bytes != null
                            ? pw.Image(
                                pw.MemoryImage(bytes),
                                fit: pw.BoxFit.cover,
                              )
                            : pw.Center(
                                child: pw.Text(
                                  "Sem foto",
                                  style: const pw.TextStyle(fontSize: 6),
                                ),
                              ),
                      ),
                      pw.Expanded(
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 10),
                          child: pw.Text(
                            nome,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      pw.SizedBox(
                        width: 40,
                        child: pw.Text(
                          qtd.toString(),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text(
                          "R\$ ${preco.toStringAsFixed(2)}",
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text(
                          "R\$ ${(preco * qtd).toStringAsFixed(2)}",
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // TOTAIS
              pw.SizedBox(height: 15),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 200,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Subtotal:",
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            "R\$ ${(total - frete).toStringAsFixed(2)}",
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Frete:",
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            "R\$ ${frete.toStringAsFixed(2)}",
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Divider(
                          color: PdfColors.black,
                          thickness: 1,
                        ), // Corrigido aqui: sem o parâmetro 'width'
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "TOTAL:",
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            "R\$ ${total.toStringAsFixed(2)}",
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#E91E63'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Center(
                child: pw.Text(
                  "Benta Laços - Feito com amor para sua princesa!",
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey500,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
