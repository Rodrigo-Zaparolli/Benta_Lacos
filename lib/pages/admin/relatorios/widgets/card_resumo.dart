import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardsResumo extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs; // Todos os pedidos
  final List<QueryDocumentSnapshot> usuariosDocs; // Todos os usuários
  final DateTime? dataInicio;
  final DateTime? dataFim;

  const CardsResumo({
    super.key,
    required this.docs,
    required this.usuariosDocs,
    this.dataInicio,
    this.dataFim,
  });

  @override
  Widget build(BuildContext context) {
    // VARIÁVEIS PARA ACUMULADOS TOTAIS (GERAL)
    double faturamentoGeral = 0;
    int pedidosGeral = docs.length;
    int produtosGeral = 0;
    int clientesGeral = 0;

    // VARIÁVEIS PARA FILTRO POR PERÍODO (CALENDÁRIO)
    double faturamentoPeriodo = 0;
    int pedidosPeriodoCount = 0;
    int produtosPeriodoCount = 0;
    int clientesPeriodoCount = 0;

    // 1. LÓGICA DE PEDIDOS (Geral vs Período)
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final double totalPedido = (data['total'] ?? 0).toDouble();
      final List itens = data['itens'] as List? ?? [];

      // No seu Firebase o campo de data nos pedidos geralmente é 'data' ou 'dataPedido'
      final Timestamp? ts =
          data['dataPedido'] as Timestamp? ?? data['data'] as Timestamp?;

      // Acúmulo Geral
      faturamentoGeral += totalPedido;
      produtosGeral += itens.length;

      // Acúmulo Por Período (Filtro do Administrador)
      if (ts != null && dataInicio != null && dataFim != null) {
        DateTime dataPed = ts.toDate();
        // Verifica se está dentro do intervalo selecionado
        if (dataPed.isAfter(dataInicio!) &&
            dataPed.isBefore(dataFim!.add(const Duration(days: 1)))) {
          faturamentoPeriodo += totalPedido;
          pedidosPeriodoCount++;
          produtosPeriodoCount += itens.length;
        }
      }
    }

    // 2. LÓGICA DE USUÁRIOS (Geral vs Período)
    for (var doc in usuariosDocs) {
      final data = doc.data() as Map<String, dynamic>;

      // Filtra apenas se for do tipo 'cliente'
      if (data['tipo'] == 'cliente') {
        clientesGeral++;

        // No seu Firebase o campo é 'dataCriacao'
        Timestamp? ts = data['dataCriacao'] as Timestamp?;
        if (ts != null && dataInicio != null && dataFim != null) {
          DateTime dataCad = ts.toDate();
          if (dataCad.isAfter(dataInicio!) &&
              dataCad.isBefore(dataFim!.add(const Duration(days: 1)))) {
            clientesPeriodoCount++;
          }
        }
      }
    }

    return Column(
      children: [
        // PRIMEIRA LINHA: CARDS GERAIS (ACUMULADO TOTAL)
        Row(
          children: [
            _card(
              "Faturamento Total",
              _formatMoeda(faturamentoGeral),
              const Color(0xFF4CAF50),
              Icons.payments,
            ),
            _card(
              "Total de Pedidos",
              pedidosGeral.toString(),
              const Color(0xFF2196F3),
              Icons.shopping_cart,
            ),
            _card(
              "Produtos Vendidos",
              produtosGeral.toString(),
              const Color(0xFF9C27B0),
              Icons.inventory_2,
            ),
            _card(
              "Clientes Cadastrados",
              clientesGeral.toString(),
              const Color(0xFFFF9800),
              Icons.group,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // DIVISOR VISUAL PARA O PERÍODO
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.date_range, size: 14, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text(
                "MÉTRICAS POR PERÍODO (FILTRADO)",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),

        // SEGUNDA LINHA: CARDS POR PERÍODO (DADOS DO CALENDÁRIO)
        Row(
          children: [
            _card(
              "Vendas por Período",
              _formatMoeda(faturamentoPeriodo),
              const Color(0xFF388E3C),
              Icons.trending_up,
            ),
            _card(
              "Pedidos por Período",
              pedidosPeriodoCount.toString(),
              const Color(0xFF1976D2),
              Icons.add_shopping_cart,
            ),
            _card(
              "Produtos por Período",
              produtosPeriodoCount.toString(),
              const Color(0xFF7B1FA2),
              Icons.shopping_bag,
            ),
            _card(
              "Clientes por Período",
              clientesPeriodoCount.toString(),
              const Color(0xFFE64A19),
              Icons.person_add,
            ),
          ],
        ),
      ],
    );
  }

  // Função para formatar valores em Real (R$)
  String _formatMoeda(double valor) {
    return "R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}";
  }

  Widget _card(String t, String v, Color c, IconData i) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  v,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Ícone de fundo suave
          Icon(i, color: Colors.white24, size: 32),
        ],
      ),
    ),
  );
}
