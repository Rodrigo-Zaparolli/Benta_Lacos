import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/theme/tema_site.dart'; // Ajustado para sua nova estrutura

class GestaoDepoimentosPage extends StatelessWidget {
  const GestaoDepoimentosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text("Gestão de Depoimentos"),
          backgroundColor: TemaAdmin.corAdminEditor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            indicatorColor: TemaAdmin.Primary,
            tabs: [
              Tab(icon: Icon(Icons.pending_actions), text: "PENDENTES"),
              Tab(icon: Icon(Icons.check_circle_outline), text: "APROVADOS"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildListaDepoimentos(aprovados: false), // Aba Pendentes
            _buildListaDepoimentos(aprovados: true), // Aba Aprovados
          ],
        ),
      ),
    );
  }

  Widget _buildListaDepoimentos({required bool aprovados}) {
    return StreamBuilder<QuerySnapshot>(
      // Filtra os depoimentos com base no status de aprovação
      stream: FirebaseFirestore.instance
          .collection('depoimentos')
          .where('aprovado', isEqualTo: aprovados)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Erro ao carregar: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  aprovados ? Icons.chat_bubble_outline : Icons.done_all,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  aprovados
                      ? "Nenhum depoimento aprovado ainda."
                      : "Tudo limpo! Nenhum depoimento pendente.",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String id = docs[index].id;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['cliente'] ?? "Anônimo",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _buildStatusBadge(aprovados),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['texto'] ?? "Sem conteúdo",
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Estrelas
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              Icons.star,
                              size: 18,
                              color: i < (data['estrelas'] ?? 0)
                                  ? Colors.amber
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                        // Botões de Ação
                        Row(
                          children: [
                            if (!aprovados) // Se estiver pendente, mostra o check de aprovação
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                tooltip: 'Aprovar',
                                onPressed: () => _alterarStatus(id, true),
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Excluir',
                              onPressed: () => _confirmarExclusao(context, id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(bool aprovado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: aprovado
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        aprovado ? "APROVADO" : "AGUARDANDO",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: aprovado ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  void _alterarStatus(String id, bool status) {
    FirebaseFirestore.instance.collection('depoimentos').doc(id).update({
      'aprovado': status,
    });
  }

  void _confirmarExclusao(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remover Depoimento?"),
        content: const Text(
          "Isso removerá permanentemente o depoimento do banco de dados.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('depoimentos')
                  .doc(id)
                  .delete();
              Navigator.pop(ctx);
            },
            child: const Text("Remover", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
