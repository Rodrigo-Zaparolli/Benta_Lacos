import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/theme/tema_site.dart';

class GraficoEnvio extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final ConfigRelatorio config = ConfigRelatorio();

  // --- AJUSTE PARA O ADMINISTRADOR ---
  // Agora o widget pode receber uma lista de cores personalizada.
  // Exemplo de uso: GraficoEnvio(docs: seusDocs, coresCustom: [Colors.red, Colors.blue])
  final List<Color>? coresCustom;

  GraficoEnvio({super.key, required this.docs, this.coresCustom});

  @override
  Widget build(BuildContext context) {
    // --- 1. PREPARAÇÃO DOS DADOS ---
    Map<String, double> dadosEnvio = {};
    double totalPedidos = docs.length.toDouble();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      String envio = data['metodoEnvio'] ?? "Não informado";
      dadosEnvio[envio] = (dadosEnvio[envio] ?? 0) + 1;
    }

    // --- 2. GERENCIAMENTO DE CORES ---
    // Se 'coresCustom' for nulo, usa esta paleta padrão.
    // O Administrador pode alterar esta lista para mudar o visual base.
    final List<Color> listaDeCores =
        coresCustom ??
        [
          const Color(0xFF4CAF50), // Verde
          const Color(0xFFF9A825), // Amarelo/laranja suave
          const Color(0xFF546E7A), // cinza azulado
          const Color(0xFF00E676), // Verde
          const Color(0xFFFFAB40), // Laranja
        ];

    return _buildCardPizza(
      "Volume por Envio",
      dadosEnvio,
      totalPedidos,
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
      height: 250, // <--- AJUSTE DE ALTURA: Altere aqui para aumentar o card
      padding: EdgeInsets.all(config.paddingCard),
      decoration: BoxDecoration(
        color: config.fundoCard, // Cor de fundo vinda do seu tema
        borderRadius: BorderRadius.circular(config.borderRadius),
        border: Border.all(color: config.bordaCard),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: config.subtitulo().copyWith(
              fontSize: 12, // <--- TAMANHO DA FONTE DO TÍTULO
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(
            height: 20,
          ), // <--- ESPAÇAMENTO: Espaço entre título e gráfico
          Expanded(
            child: total == 0
                ? const Center(child: Text("Sem dados"))
                : PieChart(
                    PieChartData(
                      sectionsSpace:
                          2, // <--- GAP: Espaço branco entre as fatias
                      centerSpaceRadius:
                          0, // <--- ESTILO: 0 para Pizza, >30 para Rosca
                      sections: _gerarSecoes(dados, total, cores),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          // --- LEGENDA ---
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
        // Atribui a cor da lista baseada no índice atual
        color: cores[i % cores.length],
        value: e.value,

        // --- TEXTO DENTRO DA FATIA ---
        // Atualmente mostra a quantidade. Para mostrar %, use:
        // '${(e.value / total * 100).toStringAsFixed(0)}%'
        title: '${e.value.toInt()}',

        radius: 65, // <--- TAMANHO DA FATIA: Aumente ou diminua o gráfico aqui

        titleStyle: const TextStyle(
          fontSize: 10, // <--- FONTE INTERNA: Tamanho do número na pizza
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      i++;
      return secao;
    }).toList();
  }

  // --- COMPONENTE DE LEGENDA ---
  Widget _buildLegendaManual(List<String> nomes, List<Color> cores) {
    return Wrap(
      spacing: 10, // Espaço horizontal entre itens da legenda
      runSpacing: 5, // Espaço vertical entre linhas da legenda
      alignment: WrapAlignment.center,
      children: List.generate(nomes.length, (index) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, // <--- TAMANHO DA BOLINHA
              height: 8,
              decoration: BoxDecoration(
                color: cores[index % cores.length],
                shape: BoxShape.circle, // Círculo ou Rectangle
              ),
            ),
            const SizedBox(width: 4),
            Text(
              nomes[index],
              style: const TextStyle(
                fontSize: 9, // <--- TAMANHO DO TEXTO DA LEGENDA
                color: Colors.grey,
              ),
            ),
          ],
        );
      }),
    );
  }
}
