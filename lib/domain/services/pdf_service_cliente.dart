import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfServiceCliente {
  /// =====================================================
  /// 🔒 CONVERSÃO SEGURA DE DATA (FIREBASE TIMESTAMP)
  /// =====================================================
  static String _formatarData(dynamic raw) {
    if (raw == null) return "N/A";

    DateTime data;

    if (raw is Timestamp) {
      // Converte o formato do Firebase mostrado na imagem
      data = raw.toDate();
    } else if (raw is DateTime) {
      data = raw;
    } else if (raw is String) {
      data = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      return "Data Inválida";
    }

    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  /// =====================================================
  /// 📄 GERA COMPROVANTE DE PEDIDO
  /// =====================================================
  static Future<void> gerarComprovantePedido({
    required String pedidoId,
    required String nomeCliente,
    required List<dynamic> itens,
    required double total,
    required double frete,
    required String metodoPagamento,
    required String enderecoCompleto,
    required dynamic dataPedido,
  }) async {
    final pdf = pw.Document();

    // Formata a data antes de iniciar a construção do PDF
    final String dataExibicao = _formatarData(dataPedido);

    final Map<String, Uint8List?> imagens = {};

    // Cache de imagens dos itens
    for (final item in itens) {
      final map = item as Map<String, dynamic>;
      final String id = map['id'] ?? map['nome'] ?? '';
      final String? url = map['imageUrl'];

      if (url != null && url.isNotEmpty) {
        try {
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) imagens[id] = response.bodyBytes;
        } catch (_) {
          imagens[id] = null;
        }
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho Principal
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'BENTA LAÇOS',
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
                        'Pedido #${pedidoId.substring(0, 8).toUpperCase()}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      // Exibição da Data corrigida
                      pw.Text('Data do Pedido: $dataExibicao'),
                      pw.Text(
                        'Status: Confirmado',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.green700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Seção de Endereço e Pagamento
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DADOS DE ENTREGA',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Cliente: $nomeCliente'),
                    pw.Text(
                      'Endereço: $enderecoCompleto',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Pagamento: $metodoPagamento',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Tabela de Produtos
              pw.Container(
                color: PdfColor.fromHex('#E91E63'),
                padding: const pw.EdgeInsets.all(6),
                child: pw.Row(
                  children: [
                    _header('Foto', width: 45),
                    _header('Produto', expanded: true),
                    _header('Qtd', width: 40, center: true),
                    _header('Total', width: 80, right: true),
                  ],
                ),
              ),

              ...itens.map((item) {
                final map = item as Map<String, dynamic>;
                final nome = map['nome'] ?? '';
                final qtd = map['quantidade'] ?? 1;
                final preco = (map['preco'] as num).toDouble();
                final id = map['id'] ?? map['nome'];
                final img = imagens[id];

                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey300,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 40,
                        height: 35,
                        child: img != null
                            ? pw.Image(
                                pw.MemoryImage(img),
                                fit: pw.BoxFit.cover,
                              )
                            : pw.Center(
                                child: pw.Text(
                                  'N/A',
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
                          'R\$ ${(preco * qtd).toStringAsFixed(2)}',
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

              pw.SizedBox(height: 20),

              // Resumo Financeiro
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _rowResumo(
                        'Subtotal:',
                        'R\$ ${(total - frete).toStringAsFixed(2)}',
                      ),
                      _rowResumo('Frete:', 'R\$ ${frete.toStringAsFixed(2)}'),
                      pw.Divider(),
                      _rowResumo(
                        'TOTAL:',
                        'R\$ ${total.toStringAsFixed(2)}',
                        bold: true,
                        color: PdfColor.fromHex('#E91E63'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'Pedido_$pedidoId.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  static pw.Widget _header(
    String text, {
    double? width,
    bool expanded = false,
    bool right = false,
    bool center = false,
  }) {
    final widget = pw.Text(
      text,
      textAlign: right
          ? pw.TextAlign.right
          : center
          ? pw.TextAlign.center
          : pw.TextAlign.left,
      style: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
    );
    if (expanded) return pw.Expanded(child: widget);
    if (width != null) return pw.SizedBox(width: width, child: widget);
    return widget;
  }

  static pw.Widget _rowResumo(
    String label,
    String value, {
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}
