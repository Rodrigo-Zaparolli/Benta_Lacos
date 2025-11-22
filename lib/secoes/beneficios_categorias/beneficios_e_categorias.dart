import 'package:flutter/material.dart';

class BeneficiosECategorias extends StatelessWidget {
  const BeneficiosECategorias({super.key});

  @override
  Widget build(BuildContext context) {
    // Container principal para adicionar o fundo (background)
    return Container(
      // Cor de fundo bege/creme claro (substitua por DecorationImage se usar padrão)
      //color: const Color(0xFFFBF8F5),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            // Título opcional da seção (mantido do exemplo anterior)
            //const Padding(
            //padding: EdgeInsets.only(bottom: 24.0),
            //child: Text(
            //'Produtos em Destaque',
            //style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            //),
            //),

            // Wrap para responsividade: contém apenas os 3 benefícios da segunda imagem
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 40, // Espaçamento horizontal entre os itens
              runSpacing: 40, // Espaçamento vertical (quando quebra a linha)
              children: [
                // Benefício 1: Entrega Rápida (Estilo com Círculo Rosa)
                _beneficio(
                  'Entrega Rápida',
                  'Receba seu pedido com agilidade',
                  Icons.local_shipping,
                  hasColoredBackground: true,
                ),

                // Benefício 2: Qualidade Premium (Estilo com Círculo Rosa)
                _beneficio(
                  'Qualidade Premium',
                  'Produtos com acabamento perfeito',
                  Icons.star,
                  hasColoredBackground: true,
                ),

                // Benefício 3: Feito com Amor (Estilo com Círculo Rosa)
                _beneficio(
                  'Feito com Amor',
                  'Cada peça criada com carinho',
                  Icons.favorite,
                  hasColoredBackground: true,
                ),
              ],
            ),

            // O código removido de "Queridinhos mais vendidos" e os 3 benefícios abaixo não estão mais aqui.
          ],
        ),
      ),
    );
  }

  /// Método auxiliar para criar um bloco de benefício.
  Widget _beneficio(
    String titulo,
    String subtitulo,
    IconData icone, {
    bool hasColoredBackground = true,
  }) {
    // Define as cores com base se há fundo colorido ou não
    final Color iconColor = hasColoredBackground
        ? Colors.pink
        : Colors.brown.shade700;

    // Define a decoração (círculo rosa ou nulo)
    final Decoration? iconDecoration = hasColoredBackground
        ? BoxDecoration(color: Colors.pink.shade50, shape: BoxShape.circle)
        : null;

    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Container do Ícone
          Container(
            padding: const EdgeInsets.all(20),
            decoration: iconDecoration,
            child: Icon(icone, size: 40, color: iconColor),
          ),

          const SizedBox(height: 12),

          // Título do Benefício
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),

          const SizedBox(height: 6),

          // Subtítulo/Descrição
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
