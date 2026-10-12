import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/tema_site.dart';

abstract final class AdminStyle {
  static const ink = Color(0xFF28232E),
      muted = Color(0xFF837B89),
      background = Color(0xFFF5F4F7),
      border = Color(0xFFECE8EF),
      rose = Color(0xFFB73564),
      green = Color(0xFF258369),
      amber = Color(0xFFA56C16),
      blue = Color(0xFF4C6FB5);
}

class AdminLayout extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final Widget child;
  final VoidCallback onStore, onLogout;
  final String email;
  const AdminLayout({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.child,
    required this.onStore,
    required this.onLogout,
    this.email = '',
  });
  static const labels = [
    'Visão geral',
    'Pedidos',
    'Produtos',
    'Estoque',
    'Clientes',
    'Relatórios',
    'Conteúdo do site',
    'Configurações',
  ];
  static const icons = [
    Icons.space_dashboard_outlined,
    Icons.receipt_long_outlined,
    Icons.shopping_bag_outlined,
    Icons.inventory_2_outlined,
    Icons.people_outline,
    Icons.insights_outlined,
    Icons.web_outlined,
    Icons.tune,
  ];
  Widget _navigation(BuildContext context, bool drawer) => Material(
    color: AdminStyle.ink,
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/imagens/logo.png',
                    width: 44,
                    height: 44,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Benta Laços',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'GESTÃO DA LOJA',
                        style: TextStyle(
                          color: Color(0xFFBDB3C5),
                          fontSize: 9,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  if (i == 0 || i == 5 || i == 6)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 20, 0, 12),
                      child: Text(
                        i == 0
                            ? 'OPERAÇÃO'
                            : i == 5
                            ? 'RESULTADOS'
                            : 'MARCA E AJUSTES',
                        style: const TextStyle(
                          color: Color(0xFF9A8EAA),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: ListTile(
                      dense: true,
                      minTileHeight: 46,
                      selected: i == selected,
                      selectedTileColor: const Color(0xFF4D2C40),
                      selectedColor: const Color(0xFFF5B5CF),
                      textColor: const Color(0xFFD1C9D8),
                      iconColor: const Color(0xFFAAA0B5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: Icon(icons[i], size: 20),
                      title: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: i == selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      trailing: i == selected
                          ? const Icon(Icons.chevron_right, size: 16)
                          : null,
                      onTap: () {
                        if (drawer) Navigator.pop(context);
                        onSelect(i);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF332C3B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sua loja, seu cuidado.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cada detalhe faz parte da experiência Benta.',
                    style: TextStyle(
                      color: Color(0xFFBEB3C8),
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF65596E)),
                    ),
                    onPressed: onStore,
                    icon: const Icon(Icons.open_in_new, size: 15),
                    label: const Text(
                      'Abrir loja',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.logout,
              size: 18,
              color: Color(0xFFAAA0B5),
            ),
            title: const Text(
              'Sair da conta',
              style: TextStyle(color: Color(0xFFCEC4D6), fontSize: 12),
            ),
            onTap: onLogout,
          ),
          const SizedBox(height: 14),
        ],
      ),
    ),
  );
  Widget _account() => Tooltip(
    message: email.isEmpty ? 'Configurações da conta' : email,
    child: IconButton(
      onPressed: () => onSelect(7),
      icon: const CircleAvatar(
        radius: 17,
        backgroundColor: Color(0xFFF5E6ED),
        child: Icon(Icons.person_outline, size: 19, color: AdminStyle.rose),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final desktop = c.maxWidth >= 1000;
      final theme = TemaSite.tema.copyWith(
        scaffoldBackgroundColor: AdminStyle.background,
        dividerColor: AdminStyle.border,
        dividerTheme: const DividerThemeData(
          color: AdminStyle.border,
          thickness: 1,
          space: 1,
        ),
        textTheme: TemaSite.tema.textTheme.apply(
          bodyColor: AdminStyle.ink,
          displayColor: AdminStyle.ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AdminStyle.ink,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AdminStyle.border),
          ),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF9F8FB)),
          headingTextStyle: const TextStyle(
            fontSize: 11,
            color: AdminStyle.muted,
            fontWeight: FontWeight.w600,
          ),
          dataTextStyle: const TextStyle(fontSize: 12, color: AdminStyle.ink),
          headingRowHeight: 48,
          dataRowMinHeight: 70,
          dataRowMaxHeight: 76,
          columnSpacing: 24,
          horizontalMargin: 20,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AdminStyle.rose,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(fontSize: 12, color: AdminStyle.muted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminStyle.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminStyle.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminStyle.rose),
          ),
        ),
      );
      return Theme(
        data: theme,
        child: Scaffold(
          appBar: desktop
              ? null
              : AppBar(
                  title: Text(
                    labels[selected],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  actions: [_account(), const SizedBox(width: 8)],
                ),
          drawer: desktop ? null : Drawer(child: _navigation(context, true)),
          body: Row(
            children: [
              if (desktop)
                SizedBox(width: 250, child: _navigation(context, false)),
              Expanded(
                child: Column(
                  children: [
                    if (desktop)
                      Container(
                        height: 72,
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: AdminStyle.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Administração',
                              style: TextStyle(
                                color: AdminStyle.muted,
                                fontSize: 12,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: AdminStyle.muted,
                              ),
                            ),
                            Text(
                              labels[selected],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('dd/MM/yyyy').format(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AdminStyle.muted,
                              ),
                            ),
                            const SizedBox(width: 18),
                            _account(),
                          ],
                        ),
                      ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class AdminHeading extends StatelessWidget {
  final String title, description;
  final Widget? action;
  const AdminHeading(this.title, this.description, {super.key, this.action});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -.9,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AdminStyle.muted,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 26),
        child: c.maxWidth >= 720
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: text),
                  if (action != null) ...[const SizedBox(width: 24), action!],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,
                  if (action != null) ...[const SizedBox(height: 18), action!],
                ],
              ),
      );
    },
  );
}

class AdminMetric extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final String? detail;
  final Color color;
  final VoidCallback? onTap;
  const AdminMetric(
    this.label,
    this.value,
    this.icon, {
    super.key,
    this.detail,
    this.color = AdminStyle.rose,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AdminStyle.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AdminStyle.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                style: const TextStyle(
                  color: AdminStyle.muted,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class AdminMetricGrid extends StatelessWidget {
  final List<Widget> children;
  const AdminMetricGrid({super.key, required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth >= 1000
          ? 4
          : c.maxWidth >= 560
          ? 2
          : 1;
      final width = (c.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: children
            .map((w) => SizedBox(width: width, child: w))
            .toList(),
      );
    },
  );
}

class AdminPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  const AdminPanel({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AdminStyle.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AdminStyle.muted,
                      ),
                    ),
                  ],
                ],
              ),
              if (action != null) action!,
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(padding: const EdgeInsets.all(22), child: child),
      ],
    ),
  );
}

class AdminEmpty extends StatelessWidget {
  final String message;
  final VoidCallback? retry;
  const AdminEmpty(this.message, {super.key, this.retry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AdminStyle.background,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.inbox_outlined,
            color: AdminStyle.muted,
            size: 28,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AdminStyle.muted,
            height: 1.6,
          ),
        ),
        if (retry != null)
          TextButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
      ],
    ),
  );
}

class AdminStatus extends StatelessWidget {
  final String label;
  const AdminStatus(this.label, {super.key});
  @override
  Widget build(BuildContext context) {
    final color = ['Pago', 'Disponível', 'Entregue'].contains(label)
        ? AdminStyle.green
        : ['Pendente', 'Estoque baixo'].contains(label)
        ? AdminStyle.amber
        : ['Cancelado', 'Sem estoque'].contains(label)
        ? const Color(0xFFB64D58)
        : ['Aceito', 'Fabricado', 'Enviado'].contains(label)
        ? AdminStyle.blue
        : AdminStyle.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
