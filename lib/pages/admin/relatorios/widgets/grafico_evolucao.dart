import 'package:benta_lacos/tema/tema_site.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GraficoEvolucao extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final ConfigRelatorio config = ConfigRelatorio();

  GraficoEvolucao({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    double faturamentoTotal = 0;
    double volumeTotal = 0;

    // 1. Processamento dos dados
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Soma o valor em R$
      faturamentoTotal += (data['total'] ?? 0).toDouble();

      // Conta a unidade (cada documento é 1 venda/cadastro)
      volumeTotal += 1;
    }

    return Container(
      height: 250,
      padding: EdgeInsets.all(config.paddingCard),
      decoration: BoxDecoration(
        color: config.fundoCard,
        borderRadius: BorderRadius.circular(config.borderRadius),
        border: Border.all(color: config.bordaCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Distribuição: R\$ vs Unidades",
            style: config.subtitulo().copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: faturamentoTotal == 0 && volumeTotal == 0
                ? const Center(child: Text("Sem dados"))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 4, // Espaço entre as fatias
                      centerSpaceRadius:
                          40, // Espaço em branco no meio (estilo Rosca)
                      sections: [
                        // === FATIA DE FATURAMENTO (R$) ===
                        PieChartSectionData(
                          value: faturamentoTotal,
                          title: 'R\$ ${faturamentoTotal.toStringAsFixed(0)}',
                          color: config
                              .sucesso, // <--- ALTERAR COR DO FATURAMENTO AQUI
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        // === FATIA DE VOLUME (UNIDADES) ===
                        PieChartSectionData(
                          value:
                              volumeTotal *
                              10, // Multiplicador para a fatia não sumir perto do R$
                          title: '${volumeTotal.toInt()} un',
                          color:
                              Colors.orange, // <--- ALTERAR COR DO VOLUME AQUI
                          radius: 45,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          // Legendas manuais na parte inferior
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legenda("Faturamento", config.sucesso),
              const SizedBox(width: 20),
              _legenda("Volume (Qtd)", Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legenda(String texto, Color cor) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
