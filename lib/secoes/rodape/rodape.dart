import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../tema/tema_site.dart';
import '../../widgets/hover_link.dart';

class Rodape extends StatelessWidget {
  const Rodape({super.key});

  // ==============================
  // MÉTODOS PARA ABRIR LINKS
  // ==============================
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
    final url = "https://wa.me/55$cleaned";
    await _abrirLink(url);
  }

  Future<void> _launchEmail(String email) async {
    final url = "mailto:$email";
    await _abrirLink(url);
  }

  @override
  Widget build(BuildContext context) {
    final rodape = TemaSite.rodape;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: rodape.backgroundColor,
        image: rodape.backgroundImage != null
            ? DecorationImage(
                image: AssetImage(rodape.backgroundImage!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.35),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Wrap(
          spacing: 60,
          runSpacing: 40,
          alignment: WrapAlignment.center,
          children: [
            // ===================== ATENDIMENTO =====================
            _buildSection('Atendimento:', [
              Text('Horário de Funcionamento', style: rodape.bodyStyle()),
              const SizedBox(height: 8),
              Text('Segunda a Sexta:', style: rodape.headerStyle(fontSize: 16)),
              Text('9hrs às 18hrs', style: rodape.bodyStyle()),
              const SizedBox(height: 4),
              Text('Sábado:', style: rodape.headerStyle(fontSize: 16)),
              Text('9hrs às 15:00', style: rodape.bodyStyle()),
            ]),

            // ===================== FALE CONOSCO =====================
            _buildSection('Fale conosco:', [
              // Telefone
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildContactRow(
                  icon: Icons.phone,
                  text: '(54) 99999-9999',
                  color: rodape.textoCor,
                ),
              ),

              const SizedBox(height: 10),

              // WhatsApp
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildContactRow(
                  icon: FontAwesomeIcons.whatsapp,
                  text: '(54) 99999-9999',
                  color: rodape.whatsappCor,
                  onTap: () => _launchWhatsApp('(54) 99999-9999'),
                  hoverColor: rodape.linkHover,
                ),
              ),

              const SizedBox(height: 10),

              // E-mail
              Container(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                ), // aumentar largura conforme quiser
                child: HoverLink(
                  onTap: () => _launchEmail('atendimento@bentalacos.com.br'),
                  color: rodape.textoCor,
                  hoverColor: rodape.linkHover,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.email, size: 22),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'atendimento@bentalacos.com.br',
                          style: TextStyle(fontSize: 16),
                          softWrap: false,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Instagram
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildContactRow(
                  icon: FontAwesomeIcons.instagram,
                  text: '@bentalacos',
                  color: rodape.instagramCor,
                  onTap: () =>
                      _abrirLink('https://www.instagram.com/bentalacos/'),
                  hoverColor: rodape.linkHover,
                ),
              ),
            ]),

            // ===================== PAGAMENTOS =====================
            _buildSection('Formas de Pagamento:', [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildPaymentIcon('assets/imagens/payments/visa.png'),
                  _buildPaymentIcon('assets/imagens/payments/mastercard.png'),
                  _buildPaymentIcon('assets/imagens/payments/pix.png'),
                ],
              ),
            ]),

            // ===================== LOCAL =====================
            _buildSection('Local:', [
              Text('Rua Ernesto Pandolfo, nº 636', style: rodape.bodyStyle()),
              Text('Apto 104 · 95320-000', style: rodape.bodyStyle()),
              Text('Brasil · Nova Prata / RS', style: rodape.bodyStyle()),
            ]),
          ],
        ),
      ),
    );
  }

  // ==============================
  // SEÇÕES
  // ==============================
  Widget _buildSection(String title, List<Widget> children) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: TemaSite.rodape.headerStyle()),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  // ==============================
  // CONTATOS COM HOVER
  // ==============================
  Widget _buildContactRow({
    required IconData icon,
    required String text,
    required Color color,
    VoidCallback? onTap,
    Color? hoverColor,
    Widget? child, // adiciona isso
  }) {
    Color currentColor = color;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => currentColor = hoverColor ?? color),
          onExit: (_) => setState(() => currentColor = color),
          child: GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: currentColor, size: 22),
                const SizedBox(width: 12),
                if (child != null)
                  child
                else
                  Text(
                    text,
                    style: TextStyle(color: currentColor, fontSize: 16),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==============================
  // PAGAMENTOS
  // ==============================
  Widget _buildPaymentIcon(String assetPath) {
    return Container(
      width: 45,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      child: Image.asset(assetPath, fit: BoxFit.contain),
    );
  }
}
