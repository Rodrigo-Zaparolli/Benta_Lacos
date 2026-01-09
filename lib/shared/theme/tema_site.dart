import 'package:flutter/material.dart';

// =============================================================
// TEMA GLOBAL DO SITE BENTA LAÇOS
// =============================================================
class TemaSite {
  static const Color corPrimaria = Color(0xFFE91E63); // Rosa Pink
  static const Color corSecundaria = Color(0xFF795548); // Marroms
  static const Color corFundoRodape = Color(0xFFF8F4EA); // Bege
  static const Color corTextoRodape = Color(0xFF5D4037); // Marrom Escuro
  static const Color corRastreamento = Color(0xFFE8BFC1); // Rosa pálido
  static const Color corDestaque = Color(0xFF4CAF50); // Verde

  static final ConfigRodape rodape = ConfigRodape();
  static final ConfigProduto produto = ConfigProduto();

  static const String fontePrincipal = 'Montserrat';

  // =============================================================
  // TEMA GLOBAL PARA USAR
  // =============================================================

  static const Color onSecondary = Color.fromARGB(0, 54, 54, 72);
  static const Color onAdminEditor = Color(0xFFE91E63);
  static const Color secondaryAdminEditor = Color(0xFFE91E63);
  static const Color onAdminSalvar = Color(0xFFE91E63);
  static const Color secondaryAdminSalvar = Color(0xFFE91E63);
  static const Color onDestaque = Color(0xFFE91E63); // Usar
  static const Color secondarDestaque = Color(0xFFE91E63); //Usar
  static const String fonteSecondary = 'Montserrat'; //Usar

  // =============================================================
  // SOLUÇÃO DO ERRO: Criamos um getter chamado 'tema' que o main.dart procura
  // =============================================================
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
  final String pathBackground = TemaAdmin.backgroundApp;
}

class TemaAdmin {
  static const String backgroundApp = 'assets/imagens/tela_fundo/dashboard.png';
  static final ConfigAdmin admin = ConfigAdmin();
  static const Color corBackgroundAdmin = Color.fromARGB(255, 144, 177, 140);
  static const Color Primary = Color.fromARGB(255, 255, 255, 255);
  static const Color onPrimary = Color.fromARGB(255, 28, 10, 34);
  // CONFIGURAÇÃO DOS CARD (GESTÃO PRODUTOS)
  static const Color ContainerOne = Color.fromARGB(255, 188, 11, 111);
  static const Color ContainerTwo = Color.fromARGB(255, 80, 2, 87);
  static const Color ContainerThree = Color.fromARGB(255, 100, 5, 37);
  static const Color ContainerFour = Color.fromARGB(255, 67, 160, 71);
  static const Color ContainerFive = Color.fromARGB(255, 154, 39, 174);
  static const Color ContainerSix = Color.fromARGB(255, 230, 81, 0);
  static const Color ContainerSeven = Color.fromARGB(255, 2, 119, 189);
  static const Color ContainerEight = Color.fromARGB(255, 46, 59, 66);
  static const Color ContainerNine = Color.fromARGB(255, 3, 97, 61);
  static const Color ContainerTen = Color.fromARGB(255, 94, 192, 14);
  static const Color ContainerEleven = Color.fromARGB(255, 163, 220, 5);
  static const Color ContainerTwelve = Color.fromARGB(255, 3, 97, 61); //Usar 12
  static const Color ContainerThirteen = Color.fromARGB(255, 3, 97, 61); //
  static const Color ContainerFourteen = Color.fromARGB(255, 3, 97, 61); //
  static const Color ContainerFifteen = Color.fromARGB(255, 3, 97, 61); //

  // CONFIGURAÇÃO DO EDITAR
  static const Color corAdminEditor = Color.fromARGB(255, 128, 48, 225);
  static const Color corAdminSalvar = Color.fromARGB(255, 63, 173, 66);
  static const Color onAdminEditor = Color.fromARGB(255, 54, 100, 200);
  // GESTÃO DE PEDIDOS
  static const Color PedidoPago = Color.fromARGB(255, 76, 175, 80);
  static const Color PedidoEnviado = Color.fromARGB(255, 34, 152, 248);
  static const Color PedidoCancelado = Color.fromARGB(255, 244, 67, 54);
  static const Color PedidoPendente = Color.fromARGB(255, 154, 93, 1);
  static const Color PedidoRS = Color.fromARGB(255, 3, 15, 6);
  static const Color corBackgroundGestao = Color.fromARGB(255, 206, 221, 204);
  static const Color corBackgroundCampo = Color.fromARGB(255, 255, 255, 255);

  // CONFIGURAÇÃO DOS CARD (GESTÃO PDF)
  static const String backgroundPdfApp =
      'assets/imagens/tela_fundo/dashboard.png';

  static const Color corBackgrounPdfdAdmin = Color.fromARGB(255, 144, 177, 140);
  static const Color PdfPrimary = Color.fromARGB(255, 255, 255, 255);
  static const Color PdfonPrimary = Color.fromARGB(255, 28, 10, 34);

  static const Color PdfOne = Color.fromARGB(255, 16, 1, 9);
  static const Color PdfTwo = Color.fromARGB(255, 80, 2, 87);
  static const Color PdfThree = Color.fromARGB(255, 100, 5, 37);
  static const Color PdfFour = Color.fromARGB(255, 67, 160, 71);
  static const Color PdfFive = Color.fromARGB(255, 154, 39, 174);
  static const Color PdfSix = Color.fromARGB(255, 230, 81, 0);
  static const Color PdfSeven = Color.fromARGB(255, 2, 119, 189);
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
