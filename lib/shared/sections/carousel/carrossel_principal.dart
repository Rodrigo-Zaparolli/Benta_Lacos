import 'package:flutter/material.dart';
import '../../theme/tema_site.dart';

class CarrosselPrincipal extends StatelessWidget {
  const CarrosselPrincipal({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: const Color(0xFFF7E9E2),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 750;
            final text = Padding(
              padding: EdgeInsets.all(mobile ? 24 : 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'BENTA LAÇOS',
                    style: TextStyle(
                      letterSpacing: 3,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TemaSite.corPrimaria,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carinho que acompanha cada descoberta.',
                    style: TextStyle(
                      fontSize: mobile ? 30 : 42,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                      color: TemaSite.corTextoRodape,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Laços e acessórios infantis feitos à mão, para dar um toque especial aos pequenos momentos.',
                    style: TextStyle(fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/colecao'),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Conhecer a coleção'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                    ),
                  ),
                ],
              ),
            );
            final images = Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1891 / 493,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/imagens/carousel/banner1.jpeg',
                        fit: BoxFit.contain,
                        semanticLabel: 'Personagem e flores da Benta Laços',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: mobile ? 180 : 260,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/imagens/produtos/lacos/lacos.png',
                        fit: BoxFit.contain,
                        semanticLabel: 'Laços da coleção Benta',
                      ),
                    ),
                  ),
                ],
              ),
            );
            return mobile
                ? Column(children: [text, images])
                : Row(
                    children: [
                      Expanded(child: text),
                      Expanded(child: images),
                    ],
                  );
          },
        ),
      ),
    ),
  );
}
