import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/tema_site.dart';

class GestaoPedidosPage extends StatefulWidget {
  const GestaoPedidosPage({super.key});

  @override
  State<GestaoPedidosPage> createState() => _GestaoPedidosPageState();
}

class _GestaoPedidosPageState extends State<GestaoPedidosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inicializa o controle das 4 abas (Pendentes, Pagos, Enviados, Cancelados)
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      // Atualiza a tela quando o usuário troca de aba para destacar o botão correto
      if (_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAdmin.corBackgroundGestao,
      body: Column(
        children: [
          // 1. CABEÇALHO (Título da página)
          _buildHeaderCompacto(),

          // 2. MENU DE ABAS (Botões coloridos centralizados)
          _buildCustomTabsLargas(),

          // 3. CONTEÚDO DAS LISTAS (Muda conforme a aba selecionada)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListaPedidos("Pendente"),
                _buildListaPedidos("Pago"),
                _buildListaPedidos("Enviado"),
                _buildListaPedidos("Cancelado"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o cabeçalho superior roxo compacto
  Widget _buildHeaderCompacto() {
    return Container(
      width: double.infinity,
      // AJUSTE DE ALTURA: Aumente ou diminua os valores de padding abaixo
      padding: const EdgeInsets.fromLTRB(8, 30, 8, 10),
      color: TemaAdmin.corAdminEditor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: TemaAdmin.Primary),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              "Gestão de Pedidos",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18, // TAMANHO DA FONTE DO TÍTULO
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(
            width: 40,
          ), // Equilíbrio visual para centralizar o texto
        ],
      ),
    );
  }

  /// Constrói a linha de botões (abas) centralizada
  Widget _buildCustomTabsLargas() {
    return Container(
      width: double.infinity,
      // ESPAÇAMENTO VERTICAL: Aumente aqui para dar mais respiro em cima/baixo das abas
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: TemaAdmin.corBackgroundCampo,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        // Center centraliza os itens caso a tela seja larga (como Tablets/Web)
        child: Container(
          width: MediaQuery.of(context).size.width,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _tabItemLargo(
                0,
                "Pendentes",
                Icons.timer,
                TemaAdmin.PedidoPendente,
              ),
              _tabItemLargo(1, "Pagos", Icons.paid, TemaAdmin.PedidoPago),
              _tabItemLargo(
                2,
                "Enviados",
                Icons.local_shipping,
                TemaAdmin.PedidoEnviado,
              ),
              _tabItemLargo(
                3,
                "Cancelados",
                Icons.cancel,
                TemaAdmin.PedidoCancelado,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modelo de cada botão individual das abas
  Widget _tabItemLargo(int index, String label, IconData icon, Color cor) {
    bool selected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(
          horizontal: 6,
        ), // ESPAÇO ENTRE OS BOTÕES
        // --- AJUSTE DE LARGURA E ALTURA ---
        // Aumente 'horizontal' para o botão ficar mais largo.
        // Aumente 'vertical' para o botão ficar mais alto.
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),

        decoration: BoxDecoration(
          color: selected ? cor : cor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10), // ARREDONDAMENTO
          border: Border.all(color: cor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? const Color.fromARGB(255, 86, 112, 82) : cor,
              size: 18, // TAMANHO DO ÍCONE
            ),
            const SizedBox(width: 8), // ESPAÇO ENTRE ÍCONE E TEXTO
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : cor,
                fontWeight: FontWeight.bold,
                fontSize: 13, // TAMANHO DA LETRA DA ABA
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Busca os dados do Firebase e cria a lista de cards
  Widget _buildListaPedidos(String statusFiltro) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pedidos')
          .where('status', isEqualTo: statusFiltro)
          .orderBy('dataPedido', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(child: Text("Erro ao carregar"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return Center(child: Text("Sem pedidos $statusFiltro"));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final pedido = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: ExpansionTile(
                // Ícone redondo lateral no Card
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(
                    statusFiltro,
                  ).withOpacity(0.1),
                  child: Icon(
                    _getStatusIcon(statusFiltro),
                    color: _getStatusColor(statusFiltro),
                    size: 18,
                  ),
                ),
                title: Text(
                  "Pedido #${id.substring(0, 6).toUpperCase()}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  "${pedido['nomeCliente']}",
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Text(
                  "R\$ ${pedido['total']?.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: TemaAdmin.PedidoRS,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [_buildAcoes(id, statusFiltro)],
              ),
            );
          },
        );
      },
    );
  }

  /// Área interna do Card que mostra botões para mudar o status
  Widget _buildAcoes(String id, String statusAtual) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50], // Fundo levemente cinza para a área de ação
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MOVER PARA:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (statusAtual != "Pendente")
                _statusBtn(id, "Pendente", TemaAdmin.PedidoPendente),
              if (statusAtual != "Pago")
                _statusBtn(id, "Pago", TemaAdmin.PedidoPago),
              if (statusAtual != "Enviado")
                _statusBtn(id, "Enviado", TemaAdmin.PedidoEnviado),
              if (statusAtual != "Cancelado")
                _statusBtn(id, "Cancelado", TemaAdmin.PedidoCancelado),
            ],
          ),
        ],
      ),
    );
  }

  /// Botão de ação (Mover Status)
  Widget _statusBtn(String id, String status, Color cor) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: cor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // AJUSTE DE ALTURA DO BOTÃO DE AÇÃO:
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () => FirebaseFirestore.instance
          .collection('pedidos')
          .doc(id)
          .update({'status': status}),
      child: Text(
        status,
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Funções Auxiliares para Cores e Ícones
  Color _getStatusColor(String s) {
    if (s == 'Pago') return TemaAdmin.PedidoPago;
    if (s == 'Enviado') return TemaAdmin.PedidoEnviado;
    if (s == 'Cancelado') return TemaAdmin.PedidoCancelado;
    return TemaAdmin.PedidoPendente;
  }

  IconData _getStatusIcon(String s) {
    if (s == 'Pago') return Icons.paid;
    if (s == 'Enviado') return Icons.local_shipping;
    if (s == 'Cancelado') return Icons.cancel;
    return Icons.timer;
  }
}
