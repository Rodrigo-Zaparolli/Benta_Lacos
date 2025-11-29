import 'package:flutter/material.dart';

class HoverLink extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color; // cor inicial
  final Color hoverColor; // cor ao passar o mouse

  const HoverLink({
    super.key,
    required this.child,
    this.onTap,
    this.color = Colors.white,
    this.hoverColor = Colors.blue,
    // 🔥 REMOVIDOS OS PARÂMETROS REDUNDANTES QUE CAUSAVAM O ERRO:
    // required TextStyle hoverStyle,
    // required TextStyle style,
    // required String text,
  });

  @override
  State<HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<HoverLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovering ? widget.hoverColor : widget.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: IconTheme(
          data: IconThemeData(color: color),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: color),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
