import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- NOVOS IMPORTS DE ACORDO COM A ESTRUTURA CORE/PDF ---
import 'package:benta_lacos/core/pdf/vendas_pdf.dart'; // Import do novo local

// --- OUTROS IMPORTS DAS PÁGINAS ---
import 'package:benta_lacos/pages/admin/relatorios/widgets/card_metricas_clientes.dart';
import 'package:benta_lacos/pages/admin/relatorios/widgets/card_ultimos_clientes.dart';
import 'package:benta_lacos/pages/admin/relatorios/widgets/card_produtos.dart';
import 'package:benta_lacos/pages/admin/relatorios/widgets/card_visualizados.dart';
import 'package:benta_lacos/shared/theme/tema_site.dart';

import 'widgets/sidebar_filtros.dart';
import 'widgets/card_resumo.dart';
import 'widgets/card_categorias.dart';
import 'widgets/grafico_evolucao.dart';
import 'widgets/grafico_pagamentos.dart';
import 'widgets/grafico_envio.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  DateTime? dataInicio;
  DateTime? dataFim;

  @override
  Widget build(BuildContext context) {
    final config = ConfigRelatorio();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 172, 205, 178),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pedidos').snapshots(),
        builder: (context, snapshotPedidos) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .snapshots(),
            builder: (context, snapshotUsuarios) {
              if (snapshotPedidos.hasError || snapshotUsuarios.hasError) {
                return const Center(child: Text("Erro ao carregar dados"));
              }
              if (snapshotPedidos.connectionState == ConnectionState.waiting ||
                  snapshotUsuarios.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<QueryDocumentSnapshot> pedidosDocs =
                  snapshotPedidos.data?.docs ?? [];
              final List<QueryDocumentSnapshot> usuariosDocs =
                  snapshotUsuarios.data?.docs ?? [];

              return Row(
                children: [
                  // --- SIDEBAR ATUALIZADA ---
                  SidebarFiltros(
                    docs: pedidosDocs,
                    onFiltrar: (inicio, fim) {
                      setState(() {
                        dataInicio = inicio;
                        dataFim = fim;
                      });
                    },
                    onExportarPDF: (mes, ano) {
                      // CHAMADA ATUALIZADA PARA A NOVA CLASSE VendasPdf
                      VendasPdf.gerar(pedidosDocs, mes: mes, ano: ano);
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(config.paddingPagina),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dashboard - Benta Laços",
                            style: config.tituloRelatorio(),
                          ),
                          const SizedBox(height: 25),

                          // KPIs e Resumos
                          CardsResumo(
                            docs: pedidosDocs,
                            usuariosDocs: usuariosDocs,
                            dataInicio: dataInicio,
                            dataFim: dataFim,
                          ),
                          const SizedBox(height: 25),

                          CardsCategorias(docs: pedidosDocs),
                          const SizedBox(height: 25),

                          // --- SEÇÃO DE GRÁFICOS ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: GraficoEvolucao(docs: pedidosDocs),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                flex: 2,
                                child: GraficoPagamentos(docs: pedidosDocs),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                flex: 2,
                                child: GraficoEnvio(docs: pedidosDocs),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // --- SEÇÃO: MÉTRICAS ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: CardProdutos(docs: pedidosDocs),
                              ),
                              const SizedBox(width: 15),
                              const Expanded(
                                flex: 2,
                                child: CardVisualizados(altura: 300),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                flex: 2,
                                child: CardMetricasClientes(docs: pedidosDocs),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // --- ÚLTIMOS CLIENTES ---
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: UltimosClientes()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
