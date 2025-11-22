import 'package:flutter/material.dart';

class TemaSite {
  // ---------------------------
  // CONFIGURAÇÃO DO RODAPÉ
  // ---------------------------
  static final ConfigRodape rodape = ConfigRodape();

  // ---------------------------
  // FONTES
  // ---------------------------
  static const String fontePrincipal = 'Montserrat';

  // ---------------------------
  // ThemeData para MaterialApp
  // ---------------------------
  static final ThemeData temaClaro = ThemeData(
    primaryColor: Colors.pink,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: fontePrincipal,
  );

  static final ThemeData temaEscuro = ThemeData(
    primaryColor: Colors.pink,
    scaffoldBackgroundColor: Colors.black,
    fontFamily: fontePrincipal,
  );
}

// ============================
// CONFIGURAÇÃO DO RODAPÉ
// ============================
class ConfigRodape {
  // Fundo
  Color backgroundColor = const Color(0xFFC4B8AD);
  String? backgroundImage;

  // Texto
  Color textoCor = Colors.white;
  Color linkCor = Colors.white70;
  Color linkHover = Colors.black;

  // Ícones de contato
  Color whatsappCor = Colors.white;
  Color instagramCor = Colors.white;

  // Fonte
  String fonte = TemaSite.fontePrincipal;

  // Estilos
  TextStyle headerStyle({double fontSize = 20}) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    color: textoCor,
    fontFamily: fonte,
  );

  TextStyle bodyStyle({Color? color, double fontSize = 14}) => TextStyle(
    fontSize: fontSize,
    color: color ?? textoCor,
    fontFamily: fonte,
  );
}
