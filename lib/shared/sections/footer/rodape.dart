import 'package:benta_lacos/pages/cliente/login_page.dart';
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
import 'package:benta_lacos/pages/institucional/trocas_devolucoes_page.dart';
import 'package:benta_lacos/pages/cliente/meus_pedidos_page.dart'; // ✅ Verifique se este é o caminho real

class Rodape extends StatelessWidget {
  const Rodape({super.key});

  Future<void> _abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r"[()\s-]"), "");
    final String message = Uri.encodeComponent(
      "Olá! Gostaria de falar sobre os produtos da Benta Laços.",
    );
    await _abrirLink("https://wa.me/55$cleaned?text=$message");
  }

  @override
  Widget build(BuildContext context) {
    final rodape = TemaSite.rodape;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 950;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('institucional')
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
                  const SizedBox(height: 15),
                  _buildPaymentIcons(),
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
                  // ✅ Ajuste para o nome da classe correto no seu arquivo de entregas
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuemSouPage()),
                  );
                }, rodape),
                _link("Oque Faço", () {
                  // ✅ Ajuste para o nome da classe correto no seu arquivo de entregas
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
                  // ✅ Se não houver login, manda para LoginPage ou PerfilPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MinhaContaPage()),
                  );
                }, rodape),
                _link("Meus Pedidos", () {
                  // ✅ NAVEGAÇÃO DIRETA (Troquei pushNamed por MaterialPageRoute)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MeusPedidosPage()),
                  );
                }, rodape),
                _link("Entregas", () {
                  // ✅ Ajuste para o nome da classe correto no seu arquivo de entregas
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EnvioEntregaPage()),
                  );
                }, rodape),
                _link("Trocas", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrocasDevolucoesPage(),
                    ),
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
                  _buildTrackingInput(rodape),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactCard(ConfigRodape rodape, String whatsapp, String email) {
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
          _contactTile(
            FontAwesomeIcons.whatsapp,
            whatsapp,
            () => _launchWhatsApp(whatsapp),
            Colors.green,
          ),
          const SizedBox(height: 8),
          // ✅ E-mail agora dinâmico do Firebase
          _contactTile(
            Icons.mail_outline,
            email,
            () => _abrirLink("mailto:$email"),
            rodape.headerCor,
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ---

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

  Widget _contactTile(
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

  Widget _socialIcon(IconData icon, String url, ConfigRodape rodape) {
    return InkWell(
      onTap: () => _abrirLink(url),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: rodape.headerCor),
      ),
    );
  }

  Widget _buildPaymentIcons() {
    return Row(
      children: [
        Icon(FontAwesomeIcons.ccVisa, size: 24, color: Colors.blue[900]),
        const SizedBox(width: 10),
        Icon(
          FontAwesomeIcons.ccMastercard,
          size: 24,
          color: Colors.orange[800],
        ),
        const SizedBox(width: 10),
        Icon(FontAwesomeIcons.pix, size: 20, color: Colors.teal),
      ],
    );
  }

  Widget _buildTrackingInput(ConfigRodape rodape) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: rodape.headerCor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Icon(
            FontAwesomeIcons.truck,
            size: 12,
            color: rodape.headerCor.withOpacity(0.3),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Rastrear pedido...",
                hintStyle: rodape.bodyStyle(fontSize: 12, color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: rodape.headerCor,
            child: const Icon(Icons.search, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyright(ConfigRodape rodape) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      alignment: Alignment.center,
      child: Text(
        "© 2025 Benta Laços. Feito com amor em cada ponto.",
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
        _buildTrackingInput(rodape),
        const SizedBox(height: 20),
        _buildContactCard(rodape, whatsapp, email),
      ],
    );
  }
}
