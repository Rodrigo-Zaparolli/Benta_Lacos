import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardMetricasClientes extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs; // Lista de Pedidos

  const CardMetricasClientes({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    // 1. Cálculo de clientes únicos
    final Set<String> clientesQueCompraram = {};
    // 2. Lista para pegar os nomes dos últimos compradores (sem duplicar nomes seguidos)
    final List<String> ultimosCompradores = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final nome = data['nomeCliente'] ?? "";

      if (nome.isNotEmpty) {
        clientesQueCompraram.add(nome);
        // Adiciona à lista se não for o mesmo nome do último adicionado (para variar a lista)
        if (ultimosCompradores.length < 5 &&
            !ultimosCompradores.contains(nome)) {
          ultimosCompradores.add(nome);
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3E50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- MÉTRICA PRINCIPAL ---
          _buildLinhaMetrica(
            "Já Compraram",
            clientesQueCompraram.length.toString(),
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 15),

          // --- SEÇÃO: ÚLTIMOS CLIENTES ---
          const Text(
            "Últimas compras por:",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          if (ultimosCompradores.isEmpty)
            const Text(
              "Nenhuma compra recente",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            )
          else
            ...ultimosCompradores.map(
              (nome) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      "Hoje", // Ou você pode extrair a data do doc se preferir
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // --- LEGENDA INFERIOR ---
          const Center(
            child: Text(
              "Últimos 5 clientes que realizaram pedidos.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaMetrica(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
