// lib/produtos/laco.dart
import 'dart:typed_data';
import 'package:benta_lacos/models/product.dart';
import 'package:benta_lacos/models/providers/cart_provider.dart';
import 'package:benta_lacos/secoes/carrossel/carrossel_veja.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' show ReadContext;
import 'package:url_launcher/url_launcher.dart';
import '../tema/tema_site.dart';
import '../secoes/cabecalho/cabecalho.dart';
import '../secoes/rodape/rodape.dart';
import '../widgets/background_fundo.dart';

// ======================================================
// Detalhes do Produto
// (mantive seu componente original com pequenas formatações)
// ======================================================
class DetalhesProdutoSection extends StatelessWidget {
  final Product product;
  const DetalhesProdutoSection({super.key, required this.product});

  Widget _buildDescricaoContent(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalhes do Produto:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          product.description,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        if (product.composition.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Composição:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            product.composition,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = screenWidth >= 1200
        ? 90
        : screenWidth >= 800
        ? 50
        : 20;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: _buildDescricaoContent(product),
    );
  }
}

// ======================================================
// Meios de Envio
// (mantive como estava)
// ======================================================
class MeiosEnvioSection extends StatefulWidget {
  const MeiosEnvioSection({super.key});

  @override
  State<MeiosEnvioSection> createState() => _MeiosEnvioSectionState();
}

class _MeiosEnvioSectionState extends State<MeiosEnvioSection> {
  final TextEditingController _cepController = TextEditingController();

  Future<void> _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível abrir: $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _calculateShipping() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Calculando frete para CEP ${_cepController.text}... (Simulação)',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _openCepSearch() {
    final url = Uri.parse(
      'https://buscacepinter.correios.com.br/app/endereco/index.php',
    );
    _launchUrl(url);
  }

  @override
  void dispose() {
    _cepController.dispose();
    super.dispose();
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
                height: 50,
                child: TextField(
                  controller: _cepController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Seu CEP',
                    hintStyle: TextStyle(color: Colors.black45, fontSize: 16),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _calculateShipping,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black54),
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                ),
                child: const Text(
                  'Calcular',
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TextButton(
          onPressed: _openCepSearch,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Não sei meu CEP',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================
// Opções de Compra
// (mantive, apenas pequenos ajustes internos)
// ======================================================
class OpcoesCompra extends StatefulWidget {
  final Product product;
  const OpcoesCompra({super.key, required this.product});

  @override
  State<OpcoesCompra> createState() => _OpcoesCompraState();
}

class _OpcoesCompraState extends State<OpcoesCompra> {
  late String _corSelecionada;
  int _quantidade = 1;
  bool _isShippingExpanded = false;

  @override
  void initState() {
    super.initState();
    _corSelecionada = widget.product.color;
  }

  Widget _buildShippingHeader(Color color) {
    return TextButton(
      onPressed: () =>
          setState(() => _isShippingExpanded = !_isShippingExpanded),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: Colors.black54),
              const SizedBox(width: 8),
              const Text(
                'Meios de envio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          Icon(
            _isShippingExpanded ? Icons.remove : Icons.add,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = TemaSite.produto;
    final product = widget.product;
    final double precoPix = product.price * 0.95;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: config.tituloCor,
          ),
        ),
        const SizedBox(height: 8),
        if (product.oldPrice != null)
          Text(
            "De R\$ ${product.oldPrice!.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'R\$ ${product.price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 32,
            color: config.precoCor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text.rich(
            TextSpan(
              text: 'R\$ ${precoPix.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              children: [
                TextSpan(
                  text: ' (5% de desconto pagando com Pix)',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Cor', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              decoration: BoxDecoration(
                border: Border.all(color: config.abasAtivaCor, width: 2),
                borderRadius: BorderRadius.circular(20),
                color: config.abasAtivaCor.withOpacity(0.1),
              ),
              child: Text(
                product.color,
                style: TextStyle(
                  color: config.abasAtivaCor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        LayoutBuilder(
          builder: (context, constraints) {
            final isVeryNarrow = constraints.maxWidth < 300;

            Widget quantityField = SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: _quantidade.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  int? newQuantity = int.tryParse(value);
                  if (newQuantity != null && newQuantity > 0) {
                    setState(() {
                      _quantidade = newQuantity;
                    });
                  }
                },
              ),
            );

            Widget buyButton = Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // 1. ADICIONA AO CARRINHO VIA PROVIDER
                  context.read<CartProvider>().addItem(product, _quantidade);

                  // 2. ABRE A GAVETA LATERAL DO CARRINHO (END DRAWER)
                  Scaffold.of(context).openEndDrawer();

                  // 3. Feedback rápido
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Adicionado ao carrinho!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.carrinhoBotaoFundo,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(
                  'COMPRAR',
                  style: TextStyle(
                    color: config.carrinhoBotaoTexto,
                    fontSize: 16,
                  ),
                ),
              ),
            );

            if (isVeryNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerLeft, child: quantityField),
                  const SizedBox(height: 10),
                  buyButton,
                ],
              );
            }
            return Row(
              children: [quantityField, const SizedBox(width: 10), buyButton],
            );
          },
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        _buildShippingHeader(config.abasAtivaCor),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isShippingExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(height: 0, width: double.infinity),
          secondChild: const Padding(
            padding: EdgeInsets.only(top: 15.0),
            child: MeiosEnvioSection(),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ======================================================
// LacoPage Completa (AJUSTADA)
// ======================================================
class LacoPage extends StatefulWidget {
  final Product product;
  const LacoPage({super.key, required this.product});

  @override
  State<LacoPage> createState() => _LacoPageState();
}

class _LacoPageState extends State<LacoPage> {
  bool _isChatBubbleVisible = false;
  static const String _whatsappNumber = '5554999999999';
  late final String _preFilledMessage;

  // Lista unificada: pode conter Product (índice 0) e Uint8List para galeria
  List<dynamic> _productImagesData = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _preFilledMessage =
        'Olá! Tenho interesse no produto ${widget.product.name}. Poderia me ajudar com uma dúvida?';

    // Adiciona a fonte principal (o objeto Product) como primeiro item (se existir)
    if (widget.product.imageBytes != null ||
        (widget.product.imagePath != null &&
            widget.product.imagePath!.isNotEmpty) ||
        (widget.product.imageName != null &&
            widget.product.imageName!.isNotEmpty)) {
      _productImagesData.add(widget.product);
    }

    // Adiciona imagens da galeria (Uint8List) se houver
    if (widget.product.galleryImages != null &&
        widget.product.galleryImages!.isNotEmpty) {
      _productImagesData.addAll(widget.product.galleryImages!);
    }

    // Evita lista vazia
    if (_productImagesData.isEmpty) {
      _productImagesData.add('placeholder');
    }
  }

  Future<void> _launchWhatsapp() async {
    final url = Uri.parse(
      'https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent(_preFilledMessage)}',
    );
    final bool launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o WhatsApp.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _isChatBubbleVisible = false);
  }

  Widget _buildChatBubble() {
    final theme = TemaSite.produto;
    return Positioned(
      right: 20,
      bottom: 100,
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(15.0),
        shadowColor: Colors.black54,
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.carrinhoBotaoFundo.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15.0),
                    topRight: Radius.circular(15.0),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Loja Benta Laços',
                        style: TextStyle(
                          color: theme.carrinhoBotaoTexto,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _isChatBubbleVisible = false),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.tituloCor.withOpacity(0.4),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: theme.carrinhoBotaoTexto,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        'Este lindo produto ${widget.product.name} pode ser seu! Se você tiver alguma dúvida, pergunte-nos.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _launchWhatsapp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.carrinhoBotaoFundo.withOpacity(
                          0.95,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            color: theme.carrinhoBotaoTexto,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ajuda',
                            style: TextStyle(
                              color: theme.carrinhoBotaoTexto,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsappButton() {
    final theme = TemaSite.produto;
    return Positioned(
      right: 20,
      bottom: 20,
      child: FloatingActionButton(
        onPressed: () =>
            setState(() => _isChatBubbleVisible = !_isChatBubbleVisible),
        backgroundColor: const Color(0xFF25D366),
        elevation: 8.0,
        shape: const CircleBorder(),
        child: Icon(
          Icons.question_answer,
          color: theme.carrinhoBotaoTexto,
          size: 30,
        ),
      ),
    );
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_not_supported,
        size: 30,
        color: Colors.grey,
      ),
    );
  }

  // Retorna Widget de imagem a partir do "data" (Product | Uint8List | placeholder)
  Widget _buildImageContentByIndex(int index, double size) {
    if (index >= _productImagesData.length || _productImagesData.isEmpty) {
      return _placeholder(size);
    }

    final data = _productImagesData[index];

    // Caso: Product (índice 0) -> extrair imageBytes, imagePath (url), imageName (asset)
    if (data is Product) {
      if (data.imageBytes != null && data.imageBytes!.isNotEmpty) {
        return Image.memory(
          data.imageBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      } else if (data.imagePath != null && data.imagePath!.isNotEmpty) {
        return Image.network(
          data.imagePath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      } else if (data.imageName != null && data.imageName!.isNotEmpty) {
        // Tenta duas pastas possíveis conforme seu projeto (ajuste se necessário)
        return Image.asset(
          'assets/imagens/${data.imageName!}',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            // fallback para outra pasta
            return Image.asset(
              'assets/images/${data.imageName!}',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(size),
            );
          },
        );
      }
    }

    // Caso: Uint8List (galeria)
    if (data is Uint8List) {
      return Image.memory(data, width: size, height: size, fit: BoxFit.cover);
    }

    // Caso: string 'placeholder' ou outro
    return _placeholder(size);
  }

  // Miniatura clicável com highlight e longPress para abrir popup
  Widget _buildThumbnailWidget(int index, double size) {
    final isSelected = _selectedIndex == index;
    final themeColor = TemaSite.produto.abasAtivaCor;

    Widget imageContainer = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? (themeColor ?? Colors.pink)
              : Colors.grey.shade300,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildImageContentByIndex(index, size),
      ),
    );

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      onLongPress: () {
        // abre popup mostrado com zoom
        _openImagePopupByIndex(index);
      },
      child: imageContainer,
    );
  }

  // Abre Dialog com InteractiveViewer para imagem baseada no índice
  void _openImagePopupByIndex(int index) {
    if (index >= _productImagesData.length) return;
    final data = _productImagesData[index];

    Widget imageWidget;

    if (data is Product) {
      if (data.imageBytes != null && data.imageBytes!.isNotEmpty) {
        imageWidget = Image.memory(data.imageBytes!, fit: BoxFit.contain);
      } else if (data.imagePath != null && data.imagePath!.isNotEmpty) {
        imageWidget = Image.network(data.imagePath!, fit: BoxFit.contain);
      } else if (data.imageName != null && data.imageName!.isNotEmpty) {
        imageWidget = Image.asset(
          'assets/imagens/${data.imageName!}',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Image.asset(
              'assets/images/${data.imageName!}',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _placeholder(200),
            );
          },
        );
      } else {
        imageWidget = _placeholder(200);
      }
    } else if (data is Uint8List) {
      imageWidget = Image.memory(data, fit: BoxFit.contain);
    } else {
      imageWidget = _placeholder(200);
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(color: Colors.white, child: imageWidget),
            ),
          ),
        ),
      ),
    );
  }

  // Construção da seção de imagens (miniaturas + principal), responsiva
  Widget _buildImageSection(BuildContext context, double screenWidth) {
    const kBreakpoint = 800.0;
    final isSmallScreen = screenWidth < kBreakpoint;
    double mainHeight = isSmallScreen ? screenWidth * 0.85 : 500;
    double thumbSize = isSmallScreen ? 60 : 80;

    // Constrói miniaturas
    final List<Widget> thumbnailWidgets = [];
    for (int i = 0; i < _productImagesData.length; i++) {
      thumbnailWidgets.add(_buildThumbnailWidget(i, thumbSize));
    }

    // Imagem principal renderizada a partir do índice seletado
    Widget mainImage = GestureDetector(
      onTap: () => _openImagePopupByIndex(_selectedIndex),
      child: Container(
        width: mainHeight,
        height: mainHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _buildImageContentByIndex(_selectedIndex, mainHeight),
        ),
      ),
    );

    // MOBILE: principal acima e miniaturas horizontal abaixo
    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mainImage,
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: thumbnailWidgets
                  .expand((w) => [w, const SizedBox(width: 10)])
                  .toList(),
            ),
          ),
        ],
      );
    }

    // DESKTOP: miniaturas em coluna à esquerda + main image à direita
    Widget thumbnailColumn = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: thumbnailWidgets
            .expand((w) => [w, const SizedBox(height: 10)])
            .toList(),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Miniaturas fixas à esquerda (com uma largura mínima)
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: thumbSize),
          child: thumbnailColumn,
        ),
        const SizedBox(width: 15),
        // Imagem principal (expande)
        Expanded(child: mainImage),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    const kBreakpoint = 800.0;
    final isSmallScreen = screenWidth < kBreakpoint;
    final double horizontalPadding = isSmallScreen ? 16 : 32;

    return Scaffold(
      body: Stack(
        children: [
          BackgroundFundo(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Cabecalho(),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 20,
                    ),
                    child: screenWidth >= kBreakpoint
                        ? Center(
                            child: SizedBox(
                              width: 1100,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Seção de Imagem: ocupa 3/5 do espaço
                                  Flexible(
                                    flex: 3,
                                    child: _buildImageSection(
                                      context,
                                      screenWidth,
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                  // Seção de Compra: ocupa 2/5
                                  Flexible(
                                    flex: 2,
                                    child: OpcoesCompra(
                                      product: widget.product,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildImageSection(context, screenWidth),
                              const SizedBox(height: 20),
                              OpcoesCompra(product: widget.product),
                            ],
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 20,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 1100,
                        child: DetalhesProdutoSection(product: widget.product),
                      ),
                    ),
                  ),
                  const SuggestedProductsCarousel(),
                  const SizedBox(height: 30),
                  const Rodape(),
                ],
              ),
            ),
          ),
          if (_isChatBubbleVisible) _buildChatBubble(),
          _buildWhatsappButton(),
        ],
      ),
    );
  }
}
