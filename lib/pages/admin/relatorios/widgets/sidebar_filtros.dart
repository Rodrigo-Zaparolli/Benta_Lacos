import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/theme/tema_site.dart';

class SidebarFiltros extends StatefulWidget {
  final Function(DateTime inicio, DateTime fim)? onFiltrar;
  final Function(int? mes, int ano)?
  onExportarPDF; // Alterado para receber parâmetros
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

  // Variáveis para o PDF
  int? _mesSelecionado;
  int _anoSelecionado = DateTime.now().year;

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
          // Logo
          Center(
            child: SizedBox(
              height: 60,
              child: Image.asset(
                'assets/imagens/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.business, color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(height: 25),

          // --- SEÇÃO EXPORTAR PDF (MÊS E ANO) ---
          Text(
            "EXPORTAÇÃO PDF VENDAS",
            style: TextStyle(
              color: Colors.pink.shade200,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Seletor de Mês
          _buildDropdownContainer(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _mesSelecionado,
                isExpanded: true,
                dropdownColor: const Color(0xFF2D3E50),
                hint: const Text(
                  "Mês: Geral",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                icon: const Icon(
                  Icons.calendar_month,
                  color: Colors.pink,
                  size: 16,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text("Relatório Geral"),
                  ),
                  ...List.generate(
                    12,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(
                        [
                          "Janeiro",
                          "Fevereiro",
                          "Março",
                          "Abril",
                          "Maio",
                          "Junho",
                          "Julho",
                          "Agosto",
                          "Setembro",
                          "Outubro",
                          "Novembro",
                          "Dezembro",
                        ][index],
                      ),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _mesSelecionado = val),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Seletor de Ano
          _buildDropdownContainer(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _anoSelecionado,
                isExpanded: true,
                dropdownColor: const Color(0xFF2D3E50),
                icon: const Icon(Icons.history, color: Colors.pink, size: 16),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: List.generate(5, (index) {
                  int ano = DateTime.now().year - index;
                  return DropdownMenuItem(value: ano, child: Text("Ano: $ano"));
                }),
                onChanged: (val) => setState(() => _anoSelecionado = val!),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botão Exportar PDF (Agora logo abaixo dos seletores)
          _botaoAction(
            "EXPORTAR PDF",
            const Color(0xFFE57373), // Vermelho suave
            Icons.picture_as_pdf_rounded,
            onTap: () {
              if (widget.docs.isEmpty) {
                _mostrarAviso("Não há dados para exportar!");
              } else {
                widget.onExportarPDF?.call(_mesSelecionado, _anoSelecionado);
              }
            },
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 15),

          // --- SEÇÃO FILTRAR DASHBOARD ---
          Text(
            "FILTRAR DASHBOARD",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Display do Período
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.date_range,
                  size: 14,
                  color: Color(0xFF546E7A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _textoPeriodo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Color(0xFF2D3E50),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Calendário
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.pink,
                    surface: Color(0xFF1B2B3A),
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2022),
                  lastDate: DateTime.now(),
                  onDateChanged: (date) {
                    setState(() {
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
          const SizedBox(height: 15),

          _botaoAction(
            "FILTRAR DASHBOARD",
            const Color(0xFF66BB6A), // Verde
            Icons.sync_alt,
            onTap: () {
              if (_dataInicio != null && _dataFim != null) {
                widget.onFiltrar?.call(_dataInicio!, _dataFim!);
              } else {
                _mostrarAviso("Selecione o intervalo no calendário!");
              }
            },
          ),
          const SizedBox(height: 10),
          _botaoAction(
            "VOLTAR",
            const Color(0xFF546E7A),
            Icons.arrow_back_ios_new,
            isVoltar: true,
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para os containers dos Dropdowns
  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  void _mostrarAviso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _botaoAction(
    String label,
    Color cor,
    IconData icone, {
    bool isVoltar = false,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton.icon(
        icon: Icon(icone, size: 16, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: isVoltar ? () => Navigator.pop(context) : onTap,
      ),
    );
  }
}
