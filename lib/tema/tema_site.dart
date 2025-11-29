import 'package:flutter/material.dart';

// =============================================================
// TEMA GLOBAL DO SITE BENTA LAÇOS
// =============================================================
class TemaSite {
  // -----------------------------------------------------------
  // PALETA DE CORES PRINCIPAL
  // -----------------------------------------------------------
  static const Color corPrimaria = Color(0xFFE91E63); // Rosa Pink
  static const Color corSecundaria = Color(0xFF795548); // Marrom
  static const Color corDestaque = Color(0xFF4CAF50); // Verde destaque

  // 🔥 NOVO: Cores para o Rodapé Claro (Bege)
  static const Color corFundoRodape = Color(0xFFF8F4EA); // Bege Claro
  static const Color corTextoRodape = Color(
    0xFF5D4037,
  ); // Marrom Escuro para Contraste
  static const Color corRastreamento = Color(
    0xFFE8BFC1,
  ); // Rosa pálido para o campo de busca

  // -----------------------------------------------------------
  // FONTES
  // -----------------------------------------------------------
  static const String fontePrincipal = 'Montserrat';

  // -----------------------------------------------------------
  // CONFIGURAÇÕES DE SEÇÕES
  // -----------------------------------------------------------
  static final ConfigRodape rodape = ConfigRodape();
  static final ConfigProduto produto = ConfigProduto();

  // -----------------------------------------------------------
  // THEME DATA GLOBAL
  // -----------------------------------------------------------
  static final ThemeData temaClaro = ThemeData(
    primaryColor: corPrimaria,

    colorScheme: const ColorScheme.light(
      primary: corPrimaria,
      secondary: corSecundaria,
      error: Colors.red,
    ),

    scaffoldBackgroundColor: Colors.white,
    fontFamily: fontePrincipal,

    // Botões padrão
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: corPrimaria,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
    ),

    // Campos de Texto
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: corPrimaria, width: 2),
      ),
    ),

    // AppBar
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

  static ThemeData? tema; // Tema alternativo (caso use dark mode futuramente)
}

// =============================================================
// CONFIGURAÇÃO DO RODAPÉ
// =============================================================

class ConfigRodape {
  // Fundo
  // 🔥 Ajustado para o Bege Claro
  Color? fundoCor = TemaSite.corFundoRodape;
  String? backgroundImage;

  // Texto
  // 🔥 Ajustado para Marrom Escuro
  Color textoCor = TemaSite.corTextoRodape;
  // 🔥 Link base usa cor de texto padrão
  Color linkCor = TemaSite.corTextoRodape.withOpacity(0.8);
  // 🔥 Hover usa a cor primária para destaque
  Color linkHover = TemaSite.corPrimaria;

  // Ícones
  Color whatsappCor = TemaSite.corTextoRodape; // Marrom escuro para ícones
  Color instagramCor = TemaSite.corPrimaria; // Rosa Pink para redes sociais
  Color headerCor = TemaSite.corSecundaria; // Marrom para títulos
  Color campoRastreioCor =
      TemaSite.corRastreamento; // Rosa para campo de rastreio

  // Fonte
  final String fonte = TemaSite.fontePrincipal;

  // Tipografia
  TextStyle headerStyle({double fontSize = 20, Color? color}) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    color: color ?? headerCor, // Usando headerCor
    fontFamily: fonte,
  );

  TextStyle bodyStyle({Color? color, double fontSize = 14}) => TextStyle(
    fontSize: fontSize,
    color: color ?? textoCor,
    fontFamily: fonte,
  );
}

// =============================================================
// CONFIGURAÇÃO PARA PÁGINAS DE PRODUTO (ex: laco_page.dart)
// =============================================================
class ConfigProduto {
  // Títulos
  Color tituloCor = TemaSite.corSecundaria;
  Color precoCor = TemaSite.corPrimaria;

  // Botão: adicionar ao carrinho
  Color carrinhoBotaoFundo = TemaSite.corPrimaria;
  Color carrinhoBotaoTexto = Colors.white;

  // Botão: consultar frete
  Color freteBotaoFundo = TemaSite.corSecundaria;
  Color freteBotaoTexto = Colors.white;

  // Resultado do frete
  Color freteResultadoCor = TemaSite.corSecundaria;

  // Abas (detalhes / descrição)
  Color abasIndicadorCor = Colors.blue;
  Color abasAtivaCor = TemaSite.corSecundaria.withOpacity(0.8);
  Color abasInativaCor = Colors.grey.shade600;

  // Thumbnails (borda das imagens pequenas)
  Color thumbnailBordaCor = TemaSite.corPrimaria;
}
