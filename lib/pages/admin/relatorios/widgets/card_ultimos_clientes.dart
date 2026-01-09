import 'package:benta_lacos/core/pdf/clientes_pdf.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UltimosClientes extends StatelessWidget {
  const UltimosClientes({super.key});

  /// Função para gerar o PDF de todos os clientes
  Future<void> _exportarTodosClientes(BuildContext context) async {
    try {
      // Busca a base completa sem o limite de 12 itens do widget
      final queryAll = await FirebaseFirestore.instance
          .collection('usuarios')
          .orderBy('dataCriacao', descending: true)
          .get();

      if (queryAll.docs.isNotEmpty) {
        await ClientesPdf.gerar(queryAll.docs);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Nenhum cliente encontrado para exportar."),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao gerar PDF: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const int colunas = 4;

    return _buildBox(
      titulo: "Últimos Clientes Cadastrados",
      // Adiciona o ícone de PDF no topo do card
      onPdfPressed: () => _exportarTodosClientes(context),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .orderBy('dataCriacao', descending: true)
            .limit(12)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Erro ao carregar clientes.",
                style: TextStyle(color: Colors.red, fontSize: 11),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final clientes = snapshot.data!.docs;

          if (clientes.isEmpty) {
            return const Center(child: Text("Nenhum cliente cadastrado."));
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: colunas,
              crossAxisSpacing: 0,
              mainAxisExtent: 100, // Altura para comportar todos os textos
            ),
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final c = clientes[index].data() as Map<String, dynamic>;

              String nomeCompleto = "${c['nome'] ?? ''} ${c['sobrenome'] ?? ''}"
                  .trim();
              String endereco =
                  "${c['endereco'] ?? 'Sem endereço'}, ${c['numero'] ?? 'S/N'}";
              String localidade = "${c['bairro'] ?? ''} - ${c['cidade'] ?? ''}";
              String telefone = c['telefone'] ?? 'Sem telefone';

              bool eUltimaColuna = (index + 1) % colunas == 0;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: const BorderSide(color: Colors.black12, width: 0.5),
                    right: eUltimaColuna
                        ? BorderSide.none
                        : const BorderSide(color: Colors.black12, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar estilizado
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE3F2FD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 20,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Informações Detalhadas
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            nomeCompleto.isEmpty
                                ? "Usuário Sem Nome"
                                : nomeCompleto,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Color(0xFF2D3E50),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            endereco,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            localidade,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            telefone,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Estrutura do Card (Box) com suporte ao ícone de PDF
  Widget _buildBox({
    required String titulo,
    required Widget child,
    VoidCallback? onPdfPressed,
  }) => Container(
    height: 420,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF2D3E50),
              ),
            ),
            if (onPdfPressed != null)
              IconButton(
                onPressed: onPdfPressed,
                icon: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.pinkAccent, // Cor para destacar o PDF
                  size: 22,
                ),
                tooltip: "Gerar Relatório Geral",
                splashRadius: 20,
              ),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(color: Colors.black12),
        Expanded(child: child),
      ],
    ),
  );
}
