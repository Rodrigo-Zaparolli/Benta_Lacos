import 'package:benta_lacos/core/config/store_environment.dart';
import '../../utils/store_format.dart';
import 'package:benta_lacos/pages/cliente/minha_conta.dart';
import 'package:benta_lacos/pages/institucional/nossa_historia_page.dart';
import 'package:benta_lacos/pages/institucional/oque_faco_page.dart';
import 'package:benta_lacos/pages/institucional/quem_sou_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/tema_site.dart';
import '../../widgets/hover_link.dart';

// --- IMPORTAÇÕES DAS PÁGINAS ---
import 'package:benta_lacos/pages/institucional/duvidas_page.dart';
import 'package:benta_lacos/pages/institucional/envio_entrega_page.dart';
import 'package:benta_lacos/pages/cliente/meus_pedidos_page.dart';

class Rodape extends StatelessWidget {
  const Rodape({super.key});

  Future<void> _abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleaned = whatsappPhone(phone);
    final String message = Uri.encodeComponent(
      "Olá! Gostaria de falar sobre os produtos da Benta Laços.",
    );
    await _abrirLink("https://wa.me/$cleaned?text=$message");
  }

  @override
  Widget build(BuildContext context) {
    final rodape = TemaSite.rodape;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 950;

    return StreamBuilder<DocumentSnapshot>(
      stream: StoreEnvironment.database
          .collection(StoreEnvironment.collectionName('institucional'))
          .doc('contato')
          .snapshots(),
      builder: (context, snapshot) {
        String whatsapp = "(54) 99926-4865";
        String email = "contatobentalacos@gmail.com";

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          whatsapp = data['whatsapp'] ?? whatsapp;
          email = data['email'] ?? email;
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(color: rodape.fundoCor),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 1, color: rodape.headerCor.withOpacity(0.05)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth > 1200 ? 120 : 20,
                  vertical: 30,
                ),
                child: isDesktop
                    ? _buildDesktopLayout(context, rodape, whatsapp, email)
                    : _buildMobileLayout(context, rodape, whatsapp, email),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/envio-entrega'),
                    child: const Text('Envio e entrega'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/trocas-devolucoes'),
                    child: const Text('Trocas e devoluções'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/politica-privacidade'),
                    child: const Text('Privacidade'),
                  ),
                ],
              ),
              _buildCopyright(rodape),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ConfigRodape rodape,
    String whatsapp,
    String email,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Benta Laços",
                    style: rodape.headerStyle(
                      fontSize: 26,
                      color: rodape.headerCor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 250,
                    child: Text(
                      "Acessórios infantis feitos à mão com amor.\nCada detalhe é um laço de amor",
                      style: rodape.bodyStyle(
                        fontSize: 13,
                        color: rodape.textoCor.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _socialIcon(
                        FontAwesomeIcons.instagram,
                        'https://instagram.com/bentalacos',
                        rodape,
                      ),
                      const SizedBox(width: 10),
                      _socialIcon(
                        FontAwesomeIcons.facebookF,
                        'https://facebook.com/bentalacos',
                        rodape,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildLinkColumn("Institucional", [
                _link("Nossa História", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NossaHistoriaPage(),
                    ),
                  );
                }, rodape),
                _link("Quem Sou", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuemSouPage()),
                  );
                }, rodape),
                _link("O que faço", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OQueFacoPage()),
                  );
                }, rodape),
              ], rodape),
            ),
            Expanded(
              flex: 2,
              child: _buildLinkColumn("Atendimento", [
                _link("Minha Conta", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MinhaContaPage()),
                  );
                }, rodape),
                _link("Meus Pedidos", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MeusPedidosPage()),
                  );
                }, rodape),
                _link("Entregas", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EnvioEntregaPage()),
                  );
                }, rodape),
                _link("Dúvidas", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DuvidasPage()),
                  );
                }, rodape),
              ], rodape),
            ),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _buildContactCard(rodape, whatsapp, email),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactCard(ConfigRodape rodape, String whatsapp, String email) {
    final String whatsappFixo = whatsapp;
    final String emailFixo = email;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Atendimento exclusivo",
            style: rodape.headerStyle(fontSize: 14),
          ),
          const SizedBox(height: 10),

          _contactTileFa(
            FontAwesomeIcons.whatsapp,
            whatsappFixo,
            () => _launchWhatsApp(whatsappFixo),
            Colors.green,
          ),
          const SizedBox(height: 8),

          _contactTileMaterial(
            Icons.mail_outline,
            emailFixo,
            () => _abrirLink("mailto:$emailFixo"),
            rodape.headerCor,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkColumn(
    String title,
    List<Widget> links,
    ConfigRodape rodape,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: rodape
              .headerStyle(fontSize: 14)
              .copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...links,
      ],
    );
  }

  Widget _link(String label, VoidCallback onTap, ConfigRodape rodape) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: HoverLink(
        onTap: onTap,
        color: rodape.linkCor,
        hoverColor: rodape.linkHover,
        child: Text(label, style: rodape.bodyStyle(fontSize: 13)),
      ),
    );
  }

  Widget _contactTileFa(
    dynamic icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            FaIcon(icon, size: 12, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTileMaterial(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialIcon(dynamic icon, String url, ConfigRodape rodape) {
    return InkWell(
      onTap: () => _abrirLink(url),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: FaIcon(icon, size: 14, color: rodape.headerCor),
      ),
    );
  }

  Widget _buildCopyright(ConfigRodape rodape) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      alignment: Alignment.center,
      child: Text(
        "© ${DateTime.now().year} Benta Laços. Feito com amor em cada ponto.",
        style: rodape.bodyStyle(
          fontSize: 11,
          color: rodape.textoCor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ConfigRodape rodape,
    String whatsapp,
    String email,
  ) {
    return Column(
      children: [
        Text("Benta Laços", style: rodape.headerStyle(fontSize: 22)),
        const SizedBox(height: 15),
        const SizedBox(height: 20),
        _buildContactCard(rodape, whatsapp, email),
      ],
    );
  }
}
