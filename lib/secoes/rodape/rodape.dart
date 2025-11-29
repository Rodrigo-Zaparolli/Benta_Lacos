import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../tema/tema_site.dart';
import '../../widgets/hover_link.dart';

class Rodape extends StatelessWidget {
  const Rodape({super.key});

  // =============================
  // MÉTODOS PARA ABRIR LINKS
  // =============================
  Future<void> _abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Não foi possível abrir o link: $url");
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r"[()\s-]"), "");
    final String message = Uri.encodeComponent(
      "Olá! Gostaria de saber mais sobre os produtos da Benta Laços.",
    );

    final url = "https://wa.me/55$cleaned?text=$message";

    await _abrirLink(url);
  }

  Future<void> _launchEmail(String email) async {
    final url = "mailto:$email";
    await _abrirLink(url);
  }

  // =============================
  // HELPER PARA LINKS DE NAVEGAÇÃO
  // =============================
  Widget _buildLink(ConfigRodape rodape, String text, String route) {
    // Usando rodape.textoCor por padrão, mas com opacidade como no tema
    final baseStyle = rodape.bodyStyle(color: rodape.linkCor);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: HoverLink(
        child: Text(text, style: baseStyle),
        color: rodape.linkCor,
        hoverColor: rodape.linkHover,
        onTap: () {
          // Implementar navegação (ex: Navigator.pushNamed(context, route);)
          debugPrint("Navegar para: $route");
        },
      ),
    );
  }

  // =============================
  // HELPER: ÍCONE DE CONTATO RÁPIDO (Círculo, Texto e Ícone)
  // =============================
  Widget _buildQuickContactItem({
    required ConfigRodape rodape,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    required Color iconColor,
    required Color borderColor,
  }) {
    // 🔥 ADIÇÃO DO MouseRegion: Envolve o GestureDetector para controlar o cursor
    return MouseRegion(
      cursor:
          SystemMouseCursors.click, // Isso define o cursor como a "mãozinha"
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Usando headerCor para o título
                Text(
                  title,
                  style: rodape.headerStyle(
                    fontSize: 14,
                    color: rodape.headerCor,
                  ),
                ),
                Text(
                  subtitle,
                  style: rodape.bodyStyle(fontSize: 16, color: rodape.textoCor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =============================
  // ÍCONE DE REDES SOCIAIS (Apenas ícone com hover)
  // =============================
  Widget _buildSocialIcon(
    ConfigRodape rodape, {
    required IconData icon,
    required String url,
    required Color color,
    required Color hoverColor,
  }) {
    Color currentColor = color;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => currentColor = hoverColor),
          onExit: (_) => setState(() => currentColor = color),
          child: GestureDetector(
            onTap: () => _abrirLink(url),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Usando cor de fundo suave baseada na cor do ícone
                color: currentColor.withOpacity(0.1),
              ),
              child: Center(child: FaIcon(icon, color: currentColor, size: 20)),
            ),
          ),
        );
      },
    );
  }

  // =============================
  // ÍCONE DE PAGAMENTO
  // =============================
  Widget _buildPaymentIcon(String assetPath) {
    // Mantido simples para apenas exibir o asset
    return Container(
      width: 45,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Image.asset(assetPath, fit: BoxFit.contain),
    );
  }

  // =============================
  // CONTEÚDO PRINCIPAL DO RODAPÉ (4 COLUNAS RESPONSIVAS)
  // =============================
  Widget _buildFooterContent(BuildContext context, ConfigRodape rodape) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 1200 ? 150.0 : 40.0;
    final isDesktop = screenWidth > 800;

    // COLUNA 1: INSTITUCIONAL
    final institucionalColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Institucional', style: rodape.headerStyle()),
        const SizedBox(height: 20),
        _buildLink(rodape, 'Nossa História', '/nossa-historia'),
        _buildLink(rodape, 'Contato', '/contato'),
      ],
    );

    // COLUNA 2: INFORMAÇÕES
    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informações', style: rodape.headerStyle()),
        const SizedBox(height: 20),
        _buildLink(rodape, 'Trocas e Devoluções', '/trocas'),
        _buildLink(rodape, 'Política de Privacidade', '/privacidade'),
        _buildLink(rodape, 'Envios e Entregas', '/envios'),
      ],
    );

    // COLUNA 3: MINHA CONTA
    final accountColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Minha Conta', style: rodape.headerStyle()),
        const SizedBox(height: 20),
        _buildLink(rodape, 'Faça seu Login', '/login'),
        _buildLink(rodape, 'Minha Conta', '/minha-conta'),
        _buildLink(rodape, 'Meus Pedidos', '/meus-pedidos'),
      ],
    );

    // COLUNA 4: CONTATO RÁPIDO (Superior Direito)
    final quickContactColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildQuickContactItem(
          rodape: rodape,
          icon: FontAwesomeIcons.whatsapp,
          title: 'Fale No WhatsApp',
          subtitle: '(54) 99926-4865',
          iconColor: rodape.whatsappCor,
          borderColor: rodape.whatsappCor,
          onTap: () => _launchWhatsApp('54999264865'),
        ),
        const SizedBox(height: 25),
        _buildQuickContactItem(
          rodape: rodape,
          icon: Icons.email_outlined,
          title: 'Via E-Mail',
          subtitle: 'contatobentalacos@gmail.com',
          iconColor: rodape.textoCor,
          borderColor: rodape.textoCor.withOpacity(0.5),
          onTap: () => _launchEmail('contatobentalacos@gmail.com'),
        ),
        const SizedBox(height: 5),

        // Redes Sociais no Contato Rápido (parte superior)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildSocialIcon(
              rodape,
              icon: FontAwesomeIcons.instagram,
              url: 'https://instagram.com/bentalacos',
              color: rodape.instagramCor,
              hoverColor: rodape.linkHover,
            ),
            const SizedBox(width: 15),
            _buildSocialIcon(
              rodape,
              icon: FontAwesomeIcons.facebookF,
              url: 'https://facebook.com/bentalacos',
              color: rodape.instagramCor,
              hoverColor: rodape.linkHover,
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 20.0,
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(flex: 1, child: institucionalColumn),
                Expanded(flex: 1, child: infoColumn),
                Expanded(flex: 1, child: accountColumn),
                Expanded(flex: 1, child: quickContactColumn),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                institucionalColumn,
                const SizedBox(height: 10),
                infoColumn,
                const SizedBox(height: 10),
                accountColumn,
                const SizedBox(height: 10),
                quickContactColumn,
              ],
            ),
    );
  }

  // =============================
  // BARRA INFERIOR (PAGAMENTOS E RASTREAMENTO)
  // =============================
  Widget _buildBottomBar(BuildContext context, ConfigRodape rodape) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 1200 ? 150.0 : 5.0;
    final isDesktop = screenWidth > 800;
    // Puxando a cor do tema
    final mainColor = rodape.headerCor;

    // 1. MEIOS DE PAGAMENTO
    final paymentIcons = [
      _buildPaymentIcon('assets/imagens/payments/visa.png'),
      _buildPaymentIcon('assets/imagens/payments/mastercard.png'),
      _buildPaymentIcon('assets/imagens/payments/hipercard.png'),
      _buildPaymentIcon('assets/imagens/payments/pix.png'),
    ];

    final paymentSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meios de pagamento', style: rodape.headerStyle(color: mainColor)),
        const SizedBox(height: 15),
        Wrap(spacing: 5.0, runSpacing: 5.0, children: paymentIcons),
      ],
    );

    // 2. ONDE ESTÁ MEU PEDIDO? (RASTREAMENTO)
    final trackingSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FontAwesomeIcons.truckFast, color: mainColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Onde está meu pedido?',
              style: rodape.headerStyle(color: mainColor),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          width: 350,
          height: 40,
          decoration: BoxDecoration(
            // Usando cor de hover do tema para o fundo do campo de busca
            color: rodape.linkHover.withOpacity(0.3),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Digite o código de rastreamento',
                    // Usando textoCor do tema para o hint
                    hintStyle: rodape.bodyStyle(
                      color: rodape.textoCor.withOpacity(0.7),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  // Usando textoCor do tema para o texto
                  style: rodape.bodyStyle(color: rodape.textoCor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.search,
                  color: rodape.textoCor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // 🔥 REMOVIDO: A seção SEGURANÇA foi removida a pedido do usuário.

    // Conteúdo da barra inferior (Apenas Pagamentos e Rastreamento)
    final bottomContent = isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            // Mantém spaceBetween para Pagamentos na esquerda e Rastreamento na direita
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 4,
                child: paymentSection,
              ), // Dá peso para Pagamentos
              const SizedBox(width: 30),
              Expanded(
                flex: 3,
                child: trackingSection,
              ), // Dá peso para Rastreamento
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              paymentSection,
              const SizedBox(height: 5),
              trackingSection,
            ],
          );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: bottomContent,
    );
  }

  // =============================
  // BARRA FINAL (COPYRIGHT)
  // =============================
  Widget _buildCopyrightBar(BuildContext context, ConfigRodape rodape) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 1200 ? 150.0 : 40.0;

    final copyrightText = Text(
      '© ${DateTime.now().year} Benta Laços. Todos os direitos reservados.',
      // Puxando a cor do tema para o texto do copyright
      style: rodape.bodyStyle(
        fontSize: 12,
        color: rodape.textoCor.withOpacity(0.7),
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 15,
      ),
      child: Center(child: copyrightText),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rodape = TemaSite.rodape;

    // LÓGICA DE FUNDO DINÂMICA (Puxando de tema_site.dart)
    Decoration? backgroundDecoration;
    if (rodape.backgroundImage != null && rodape.backgroundImage!.isNotEmpty) {
      backgroundDecoration = BoxDecoration(
        image: DecorationImage(
          image: AssetImage(rodape.backgroundImage!),
          fit: BoxFit.cover,
        ),
      );
    } else if (rodape.fundoCor != null) {
      backgroundDecoration = BoxDecoration(color: rodape.fundoCor);
    }

    return Container(
      width: double.infinity,
      decoration: backgroundDecoration,
      child: Column(
        children: [
          // 1. CONTEÚDO PRINCIPAL DO RODAPÉ (4 COLUNAS)
          _buildFooterContent(context, rodape),

          const SizedBox(height: 5),

          // 2. BARRA INFERIOR (PAGAMENTOS E RASTREAMENTO)
          _buildBottomBar(context, rodape),

          const SizedBox(height: 5),

          // 3. BARRA DE COPYRIGHT
          _buildCopyrightBar(context, rodape),
        ],
      ),
    );
  }
}
