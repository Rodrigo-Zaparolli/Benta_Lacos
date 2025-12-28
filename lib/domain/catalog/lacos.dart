// lib/produtos/laco.dart
import 'package:benta_lacos/domain/models/product.dart';
import 'package:benta_lacos/domain/providers/cart_provider.dart';
import 'package:benta_lacos/shared/sections/carousel/carrossel_veja.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/theme/tema_site.dart';
import '../../shared/sections/header/cabecalho.dart';
import '../../shared/sections/footer/rodape.dart';
import '../../shared/widgets/background_fundo.dart';

// ======================================================
// COMPONENTE: MEIOS DE ENVIO (AJUSTADO)
// ======================================================
class MeiosEnvioSection extends StatefulWidget {
  const MeiosEnvioSection({super.key});

  @override
  State<MeiosEnvioSection> createState() => _MeiosEnvioSectionState();
}

class _MeiosEnvioSectionState extends State<MeiosEnvioSection> {
  final TextEditingController _cepController = TextEditingController();
  bool _carregando = false;

  // [AJUSTE]: Lista para armazenar e exibir as opções de frete calculadas
  List<Map<String, dynamic>> _opcoesFrete = [];

  void _calcularFrete() {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um CEP válido com 8 dígitos.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _carregando = true;
      _opcoesFrete = []; // Limpa resultados anteriores antes de nova busca
    });

    // [AJUSTE]: Simulação de valores reais (PAC e SEDEX)
    // Futuramente, você poderá substituir este delay por uma chamada de API real
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _opcoesFrete = [
          {
            'tipo': 'PAC',
            'valor': 24.90,
            'prazo': '7 a 10 dias úteis',
            'icone': Icons.inventory_2_outlined,
          },
          {
            'tipo': 'SEDEX',
            'valor': 48.50,
            'prazo': '2 a 4 dias úteis',
            'icone': Icons.bolt_rounded,
          },
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: TextField(
                  controller: _cepController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Seu CEP (00000000)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _carregando ? null : _calcularFrete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Calcular'),
            ),
          ],
        ),

        // [AJUSTE]: Widget que constrói visualmente a lista de preços de frete
        if (_opcoesFrete.isNotEmpty) ...[
          const SizedBox(height: 15),
          ..._opcoesFrete.map(
            (frete) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(frete['icone'], color: TemaSite.corPrimaria, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          frete['tipo'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          frete['prazo'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'R\$ ${frete['valor'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        TextButton(
          onPressed: () async {
            final url = Uri.parse('https://buscacepinter.correios.com.br/');
            if (await canLaunchUrl(url)) await launchUrl(url);
          },
          child: const Text(
            'Não sei meu CEP',
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================
// PÁGINA PRINCIPAL DO PRODUTO
// ======================================================
class LacoPage extends StatefulWidget {
  final Product product;
  const LacoPage({super.key, required this.product});

  @override
  State<LacoPage> createState() => _LacoPageState();
}

class _LacoPageState extends State<LacoPage> {
  int _selectedIndex = 0;
  bool _isShippingExpanded = false;
  int _quantidade = 1;

  void _showZoomImage(List<String> imagens) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 900),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imagens[_selectedIndex],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final config = TemaSite.produto;

    List<String> imagens = [
      if (widget.product.imageUrl != null) widget.product.imageUrl!,
      ...?widget.product.galleryUrls,
    ];

    return Scaffold(
      body: BackgroundFundo(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Cabecalho(),
              const SizedBox(height: 30),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMiniaturasColuna(imagens),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 3,
                              child: _buildImagemPrincipal(imagens),
                            ),
                            const SizedBox(width: 50),
                            Expanded(flex: 2, child: _buildInfoCompra(config)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildImagemPrincipal(imagens),
                            const SizedBox(height: 15),
                            _buildMiniaturasLinha(imagens),
                            const SizedBox(height: 30),
                            _buildInfoCompra(config),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 50),
              _buildDetalhesSection(config),
              const SuggestedProductsCarousel(),
              const Rodape(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniaturasColuna(List<String> imagens) {
    return SizedBox(
      width: 80,
      child: Column(
        children: List.generate(
          imagens.length,
          (index) => _itemMiniatura(imagens, index),
        ),
      ),
    );
  }

  Widget _buildMiniaturasLinha(List<String> imagens) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imagens.length,
        itemBuilder: (context, index) => _itemMiniatura(imagens, index),
      ),
    );
  }

  Widget _itemMiniatura(List<String> imagens, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.only(bottom: 10, right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedIndex == index
                ? TemaSite.corPrimaria
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(imagens[index], fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildImagemPrincipal(List<String> imagens) {
    return GestureDetector(
      onTap: () => _showZoomImage(imagens),
      child: Container(
        height: 500,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: imagens.isNotEmpty
              ? Image.network(imagens[_selectedIndex], fit: BoxFit.contain)
              : const Icon(Icons.image_not_supported, size: 100),
        ),
      ),
    );
  }

  Widget _buildInfoCompra(ConfigProduto config) {
    double percentualDesconto = widget.product.discountPix ?? 0;
    double precoPix = widget.product.price * (1 - (percentualDesconto / 100));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: config.tituloCor,
          ),
        ),
        const SizedBox(height: 10),
        if (widget.product.oldPrice != null)
          Text(
            "De R\$ ${widget.product.oldPrice!.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
              fontSize: 16,
            ),
          ),
        Text(
          "R\$ ${widget.product.price.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: config.precoCor,
          ),
        ),
        if (percentualDesconto > 0)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "R\$ ${precoPix.toStringAsFixed(2)} no PIX ($percentualDesconto% de desconto)",
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 30),
        Row(
          children: [
            _buildQtdSelector(),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<CartProvider>().addItem(
                    widget.product,
                    _quantidade,
                  );
                  Scaffold.of(context).openEndDrawer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.carrinhoBotaoFundo,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "COMPRAR",
                  style: TextStyle(
                    color: config.carrinhoBotaoTexto,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Divider(),
        _buildShippingHeader(),
      ],
    );
  }

  Widget _buildDetalhesSection(ConfigProduto config) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100),
        margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: config.abasAtivaCor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes do Produto:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: config.tituloCor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.product.description,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            if (widget.product.composition.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Composição:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: config.tituloCor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.product.composition,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQtdSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () =>
                setState(() => _quantidade > 1 ? _quantidade-- : null),
            icon: const Icon(Icons.remove),
          ),
          Text(
            "$_quantidade",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => setState(() => _quantidade++),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingHeader() {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.local_shipping_outlined),
          title: const Text(
            "Meios de envio",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Icon(_isShippingExpanded ? Icons.remove : Icons.add),
          onTap: () =>
              setState(() => _isShippingExpanded = !_isShippingExpanded),
        ),
        if (_isShippingExpanded) const MeiosEnvioSection(),
      ],
    );
  }
}
