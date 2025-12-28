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

  // SOLUÇÃO DO ERRO: Criamos um getter chamado 'tema' que o main.dart procura
  static ThemeData get tema => temaClaro;

  static final ThemeData temaClaro = ThemeData(
    useMaterial3: true,
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
      centerTitle: true,
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

  final double cardAspectRatio = 3;
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
// CONFIGURAÇÃO DO RODAPÉ
// =============================================================
class ConfigRodape {
  Color? fundoCor = TemaSite.corFundoRodape;
  String? backgroundImage = '';
  Color textoCor = TemaSite.corTextoRodape;
  Color linkCor = TemaSite.corTextoRodape.withOpacity(0.8);
  Color linkHover = TemaSite.corPrimaria;
  Color whatsappCor = const Color(0xFF25D366);
  Color instagramCor = TemaSite.corPrimaria;
  Color headerCor = TemaSite.corSecundaria;
  Color campoRastreioCor = TemaSite.corRastreamento;

  final String fonte = TemaSite.fontePrincipal;

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
// CONFIGURAÇÃO PARA PÁGINAS DE PRODUTO
// =============================================================
class ConfigProduto {
  Color tituloCor = TemaSite.corSecundaria;
  Color precoCor = TemaSite.corPrimaria;
  Color carrinhoBotaoFundo = TemaSite.corPrimaria;
  Color carrinhoBotaoTexto = Colors.white;
  Color abasAtivaCor = TemaSite.corPrimaria;
  Color abasInativaCor = Colors.grey.shade600;
  Color thumbnailBordaCor = TemaSite.corPrimaria;
}

// =============================================================
// CONFIGURAÇÃO EXCLUSIVA PARA RELATÓRIOS
// =============================================================
class ConfigRelatorio {
  // 🎨 Cores base
  final Color fundoPagina = Colors.white;
  final Color fundoCard = Colors.white;
  final Color bordaCard = const Color(0xFFE0E0E0);

  final Color corTitulo = TemaSite.corSecundaria;
  final Color corSubtitulo = const Color(0xFF616161);
  final Color corTexto = const Color(0xFF424242);

  // 🎯 Cores de status
  final Color sucesso = const Color(0xFF4CAF50);
  final Color informativo = const Color(0xFF2196F3);
  final Color aviso = const Color(0xFFFF9800);
  final Color erro = Colors.red;

  // 📐 Layout
  final double paddingPagina = 24;
  final double paddingCard = 16;
  final double borderRadius = 12;

  // 🔤 Tipografia
  final String fonte = TemaSite.fontePrincipal;

  TextStyle tituloRelatorio() => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: corTitulo,
    fontFamily: fonte,
  );

  TextStyle subtitulo() => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: corSubtitulo,
    fontFamily: fonte,
  );

  TextStyle textoPadrao() =>
      TextStyle(fontSize: 14, color: corTexto, fontFamily: fonte);

  TextStyle kpiValor() => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: TemaSite.corPrimaria,
    fontFamily: fonte,
  );

  TextStyle kpiLabel() =>
      TextStyle(fontSize: 13, color: corSubtitulo, fontFamily: fonte);

  // 📊 Estilo para tabelas
  TextStyle tabelaHeader() => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontFamily: fonte,
  );

  TextStyle tabelaCell() =>
      TextStyle(fontSize: 13, color: corTexto, fontFamily: fonte);

  Color tabelaHeaderFundo = TemaSite.corPrimaria;
}
