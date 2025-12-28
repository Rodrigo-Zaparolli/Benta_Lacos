import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UltimosClientes extends StatelessWidget {
  const UltimosClientes({super.key});

  @override
  Widget build(BuildContext context) {
    const int colunas = 4;

    return _buildBox(
      titulo: "Últimos Clientes Cadastrados",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .orderBy('dataCriacao', descending: true)
            .limit(12) // Limitado a exatamente 12 clientes
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

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final clientes = snapshot.data!.docs;

          if (clientes.isEmpty) {
            return const Center(child: Text("Nenhum cliente cadastrado."));
          }

          return GridView.builder(
            // physics: const NeverScrollableScrollPhysics(), // Opcional: desativa o scroll se couber exato
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: colunas,
              crossAxisSpacing: 0,
              mainAxisExtent:
                  100, // Aumentado para comportar Nome + Endereço + Cidade + Telefone
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
                    // Avatar
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
                    // Informações
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
                              fontSize: 12,
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

  Widget _buildBox({required String titulo, required Widget child}) =>
      Container(
        height:
            420, // Altura ajustada para caber as 3 linhas de 100px + cabeçalho
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
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF2D3E50),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.black12),
            Expanded(child: child),
          ],
        ),
      );
}
