import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../tema/tema_site.dart';

class GraficoPagamentos extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final ConfigRelatorio config = ConfigRelatorio();

  GraficoPagamentos({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    // --- 1. PREPARAÇÃO DOS DADOS ---
    // Aqui definimos as chaves fixas. Se mudar o nome aqui, mude na lógica abaixo.
    Map<String, double> dadosPagamento = {
      "PIX": 0,
      "Cartão de Crédito": 0,
      "Cartão de Débito": 0,
    };
    double totalFinanceiro = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      double valor = (data['total'] ?? 0).toDouble();

      // Identifica o método de pagamento ignorando maiúsculas/minúsculas
      String pagRaw = (data['metodoPagamento'] ?? data['formaPagamento'] ?? "")
          .toString()
          .toLowerCase();

      // --- LÓGICA DE FILTRAGEM ---
      // Você pode adicionar mais termos aqui se o seu banco salvar nomes diferentes
      if (pagRaw.contains("pix")) {
        dadosPagamento["PIX"] = dadosPagamento["PIX"]! + valor;
      } else if (pagRaw.contains("crédito") || pagRaw.contains("credito")) {
        dadosPagamento["Cartão de Crédito"] =
            dadosPagamento["Cartão de Crédito"]! + valor;
      } else {
        // Se não for nenhum dos acima, cai em Débito (ou ajuste conforme sua necessidade)
        dadosPagamento["Cartão de Débito"] =
            dadosPagamento["Cartão de Débito"]! + valor;
      }
      totalFinanceiro += valor;
    }

    // Remove do gráfico categorias que não tiveram nenhuma venda (para não poluir)
    dadosPagamento.removeWhere((k, v) => v == 0);

    // --- 2. DEFINIÇÃO DE CORES ---
    // Você pode trocar as cores aqui. Elas seguem a ordem das categorias acima.
    final List<Color> listaDeCores = [
      const Color(0xFF4CAF50), // Verde (PIX)
      const Color(0xFF2196F3), // Azul (Crédito)
      const Color(0xFFFF9800), // Laranja (Débito)
    ];

    return _buildCardPizza(
      "Financeiro / Pagamento",
      dadosPagamento,
      totalFinanceiro,
      listaDeCores,
    );
  }

  Widget _buildCardPizza(
    String titulo,
    Map<String, double> dados,
    double total,
    List<Color> cores,
  ) {
    return Container(
      height: 250, // Ajuste a ALTURA total do card aqui
      padding: EdgeInsets.all(config.paddingCard),
      decoration: BoxDecoration(
        color: config.fundoCard, // Cor de fundo (definida no seu tema)
        borderRadius: BorderRadius.circular(config.borderRadius),
        border: Border.all(color: config.bordaCard),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: config.subtitulo().copyWith(
              fontSize: 12, // Tamanho da fonte do TÍTULO
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 20), // Espaçamento entre título e gráfico
          Expanded(
            child: total == 0
                ? const Center(child: Text("Sem dados"))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2, // Espaço (gap) entre as fatias da pizza
                      centerSpaceRadius:
                          30, // Tamanho do furo central (0 vira pizza cheia)
                      sections: _gerarSecoes(dados, total, cores),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          // --- LEGENDA SIMPLES ---
          _buildLegendaManual(dados.keys.toList(), cores),
        ],
      ),
    );
  }

  List<PieChartSectionData> _gerarSecoes(
    Map<String, double> dados,
    double total,
    List<Color> cores,
  ) {
    int i = 0;
    return dados.entries.map((e) {
      final secao = PieChartSectionData(
        color: cores[i % cores.length], // Cor da fatia
        value: e.value, // Valor financeiro
        // TÍTULO que aparece dentro da fatia (está configurado para mostrar a %)
        title: '${(e.value / total * 100).toStringAsFixed(0)}%',
        radius: 45, // "Grossura" da fatia de rosca
        titleStyle: const TextStyle(
          fontSize: 10, // Tamanho da porcentagem
          fontWeight: FontWeight.bold,
          color: Colors.white, // Cor do texto dentro da fatia
        ),
      );
      i++;
      return secao;
    }).toList();
  }

  // Widget auxiliar para criar legendas embaixo do gráfico
  Widget _buildLegendaManual(List<String> nomes, List<Color> cores) {
    return Wrap(
      spacing: 10,
      runSpacing: 5,
      alignment: WrapAlignment.center,
      children: List.generate(nomes.length, (index) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: cores[index % cores.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              nomes[index],
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        );
      }),
    );
  }
}
