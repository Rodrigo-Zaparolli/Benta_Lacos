import 'package:flutter/material.dart';

// =============================================================
// TEMA GLOBAL DO SITE BENTA LAÇOS
// =============================================================
class TemaSite {
  static const String backgroundApp = 'assets/imagens/tela_fundo/dashboard.png';

  static const Color corPrimaria = Color(0xFFE91E63); // Rosa Pink
  static const Color corSecundaria = Color(0xFF795548); // Marrom
  static const Color corDestaque = Color(0xFF4CAF50); // Verde

  static const Color corFundoRodape = Color(0xFFF8F4EA); // Bege
  static const Color corTextoRodape = Color(0xFF5D4037); // Marrom Escuro
  static const Color corRastreamento = Color(0xFFE8BFC1); // Rosa pálido

  static const String fontePrincipal = 'Montserrat';

  static final ConfigRodape rodape = ConfigRodape();
  static final ConfigProduto produto = ConfigProduto();
  static final ConfigAdmin admin = ConfigAdmin();

  static final ThemeData temaClaro = ThemeData(
    primaryColor: corPrimaria,
    colorScheme: const ColorScheme.light(
      primary: corPrimaria,
      secondary: corSecundaria,
      error: Colors.red,
    ),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: fontePrincipal,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: corPrimaria,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: corPrimaria, width: 2),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: corPrimaria,
      elevation: 4,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
  );
}

// =============================================================
// 🔥 CONFIGURAÇÃO DO PAINEL ADMINISTRATIVO (DASHBOARD)
// =============================================================
class ConfigAdmin {
  final double fonteTituloAppBar = 22.0;
  final double fonteSecao = 20.0;
  final double fonteCardTitulo = 12.0;
  final double fonteCardValor = 16.0;

  final String pathBackground = TemaSite.backgroundApp;

  // AspectRatio para layout horizontal (Ícone ao lado do texto)
  final double cardAspectRatio = 2.2;
  final Color corCardFundo = Colors.white;

  TextStyle styleTituloSecao() => TextStyle(
    fontSize: fonteSecao,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF424242),
    fontFamily: TemaSite.fontePrincipal,
  );

  TextStyle styleCardValor() => TextStyle(
    fontSize: fonteCardValor,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontFamily: TemaSite.fontePrincipal,
  );
}

// =============================================================
// CONFIGURAÇÃO DO RODAPÉ (Restaurado para corrigir erros)
// =============================================================
class ConfigRodape {
  Color? fundoCor = TemaSite.corFundoRodape;
  String? backgroundImage = ''; // Adicionado campo que faltava
  Color textoCor = TemaSite.corTextoRodape;
  Color linkCor = TemaSite.corTextoRodape.withOpacity(0.8);
  Color linkHover = TemaSite.corPrimaria;
  Color whatsappCor = const Color(0xFF25D366); // Cor padrão WhatsApp
  Color instagramCor = TemaSite.corPrimaria;
  Color headerCor = TemaSite.corSecundaria;
  Color campoRastreioCor = TemaSite.corRastreamento;

  final String fonte = TemaSite.fontePrincipal;

  // Método que faltava no seu console
  TextStyle bodyStyle({Color? color, double fontSize = 14}) => TextStyle(
    fontSize: fontSize,
    color: color ?? textoCor,
    fontFamily: fonte,
  );

  TextStyle headerStyle({double fontSize = 20, Color? color}) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    color: color ?? headerCor,
    fontFamily: fonte,
  );
}

// =============================================================
// CONFIGURAÇÃO PARA PÁGINAS DE PRODUTO (Restaurado)
// =============================================================
class ConfigProduto {
  Color tituloCor = TemaSite.corSecundaria;
  Color precoCor = TemaSite.corPrimaria;
  Color carrinhoBotaoFundo = TemaSite.corPrimaria;
  Color carrinhoBotaoTexto = Colors.white;
  Color abasAtivaCor = TemaSite.corPrimaria; // Usado em laco.dart
  Color abasInativaCor = Colors.grey.shade600;
  Color thumbnailBordaCor = TemaSite.corPrimaria;
}
