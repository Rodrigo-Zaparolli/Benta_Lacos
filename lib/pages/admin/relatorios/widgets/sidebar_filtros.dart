import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../tema/tema_site.dart';

class SidebarFiltros extends StatefulWidget {
  // Callbacks para comunicação com a tela principal
  final Function(DateTime inicio, DateTime fim)? onFiltrar;
  final VoidCallback? onExportarPDF;

  // Lista de documentos (pedidos ou usuários) para validação
  final List<QueryDocumentSnapshot> docs;

  const SidebarFiltros({
    super.key,
    this.onFiltrar,
    this.onExportarPDF,
    required this.docs,
  });

  @override
  State<SidebarFiltros> createState() => _SidebarFiltrosState();
}

class _SidebarFiltrosState extends State<SidebarFiltros> {
  DateTime? _dataInicio;
  DateTime? _dataFim;
  final ConfigRelatorio _config = ConfigRelatorio();

  // Formata o texto exibido no display de período
  String get _textoPeriodo {
    if (_dataInicio == null) return "Selecionar Início";
    if (_dataFim == null) {
      return "${_dataInicio!.day}/${_dataInicio!.month} - Selecionar Fim";
    }
    return "${_dataInicio!.day}/${_dataInicio!.month} - ${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color.fromARGB(255, 11, 23, 35),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo da Empresa
          Center(
            child: SizedBox(
              height: 80,
              child: Image.asset(
                'assets/imagens/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.business, color: Colors.white24, size: 45),
              ),
            ),
          ),
          const SizedBox(height: 30),

          Text(
            "PERÍODO DE FILTRO",
            style: _config.kpiLabel().copyWith(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Display visual do período selecionado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_config.borderRadius),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 16,
                  color: Color(0xFF546E7A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _textoPeriodo,
                    style: _config.textoPadrao().copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: const Color(0xFF2D3E50),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Calendário de Seleção
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(_config.borderRadius),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.white,
                    onPrimary: Color(0xFF2D3E50),
                    surface: Color(0xFF2D3E50),
                    onSurface: Colors.white,
                  ),
                ),
                child: SingleChildScrollView(
                  child: CalendarDatePicker(
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2022),
                    lastDate: DateTime.now(),
                    onDateChanged: (date) {
                      setState(() {
                        // Lógica de seleção de intervalo (Início -> Fim)
                        if (_dataInicio == null ||
                            (_dataInicio != null && _dataFim != null)) {
                          _dataInicio = date;
                          _dataFim = null;
                        } else {
                          if (date.isBefore(_dataInicio!)) {
                            _dataInicio = date;
                          } else {
                            _dataFim = date;
                          }
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // BOTÕES DE AÇÃO

          // 1. Botão Gerar Dados (Aplica o filtro na tela)
          _botaoAction(
            "FILTRAR RELATÓRIO",
            _config.sucesso, // Verde
            Icons.filter_alt_outlined,
            onTap: () {
              if (_dataInicio != null && _dataFim != null) {
                widget.onFiltrar?.call(_dataInicio!, _dataFim!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Selecione o intervalo completo!"),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),

          // 2. Botão Exportar PDF
          _botaoAction(
            "EXPORTAR PDF",
            _config.erro, // Vermelho/Laranja
            Icons.picture_as_pdf_rounded,
            onTap: () {
              if (widget.docs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Não há dados para exportar!")),
                );
              } else {
                widget.onExportarPDF?.call();
              }
            },
          ),
          const SizedBox(height: 12),

          // 3. Botão Voltar
          _botaoAction(
            "VOLTAR",
            const Color(0xFF546E7A),
            Icons.arrow_back_ios_new_rounded,
            isVoltar: true,
          ),
        ],
      ),
    );
  }

  // Widget de botão estilizado para a Sidebar
  Widget _botaoAction(
    String label,
    Color cor,
    IconData icone, {
    bool isVoltar = false,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icone, size: 18, color: Colors.white),
        label: Text(
          label,
          style: _config.tabelaHeader().copyWith(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_config.borderRadius),
          ),
        ),
        onPressed: isVoltar ? () => Navigator.pop(context) : onTap,
      ),
    );
  }
}
