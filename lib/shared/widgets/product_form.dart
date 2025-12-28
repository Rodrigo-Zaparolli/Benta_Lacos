import 'package:flutter/material.dart';
import '../theme/tema_site.dart';
import '../../domain/models/product.dart';
import '../utils/currency_input_formatter.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final Future<void> Function(Product) onSave;

  const ProductForm({super.key, this.product, required this.onSave});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isFeatured = false;

  final List<String> _categorias = [
    'Laços',
    'Tiaras',
    'Presilhas',
    'Kits',
    'Faixas',
  ];

  late TextEditingController _nomeController;
  late TextEditingController _precoController;
  late TextEditingController _quantidadeController;
  late TextEditingController _corController;
  late TextEditingController _compositionController;
  late TextEditingController _descricaoController;
  late TextEditingController _imageUrlController;

  // Lista de controllers para a galeria dinâmica
  List<TextEditingController> _galleryControllers = [];

  String? _categoriaSelecionada;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nomeController = TextEditingController(text: p?.name ?? '');
    _precoController = TextEditingController(
      text: p?.price != null
          ? p!.price.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    _quantidadeController = TextEditingController(
      text: p?.quantity?.toString() ?? '0',
    );
    _corController = TextEditingController(text: p?.color ?? '');
    _compositionController = TextEditingController(text: p?.composition ?? '');
    _descricaoController = TextEditingController(text: p?.description ?? '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');

    // Inicializa a galeria com as URLs existentes ou uma lista vazia
    if (p?.galleryUrls != null && p!.galleryUrls!.isNotEmpty) {
      _galleryControllers = p.galleryUrls!
          .map((url) => TextEditingController(text: url))
          .toList();
    }

    // Se a galeria estiver vazia, adicionamos um campo inicial opcional
    if (_galleryControllers.isEmpty) {
      _galleryControllers.add(TextEditingController());
    }

    _categoriaSelecionada = p?.category;
    _isFeatured = p?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _quantidadeController.dispose();
    _corController.dispose();
    _compositionController.dispose();
    _descricaoController.dispose();
    _imageUrlController.dispose();
    for (var controller in _galleryControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addGalleryImage() {
    setState(() {
      _galleryControllers.add(TextEditingController());
    });
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryControllers[index].dispose();
      _galleryControllers.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSelecionada == null) return;

    setState(() => _isSaving = true);

    try {
      String precoLimpo = _precoController.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      double precoConvertido = double.tryParse(precoLimpo) ?? 0.0;

      int quantidadeConvertida = int.tryParse(_quantidadeController.text) ?? 0;

      // Coleta todas as URLs da galeria que não estão vazias
      final List<String> galeria = _galleryControllers
          .map((c) => c.text.trim())
          .where((url) => url.isNotEmpty)
          .toList();

      final product = Product(
        id: widget.product?.id ?? '',
        name: _nomeController.text.trim(),
        price: precoConvertido,
        quantity: quantidadeConvertida,
        category: _categoriaSelecionada!,
        color: _corController.text.trim(),
        composition: _compositionController.text.trim(),
        description: _descricaoController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        galleryUrls: galeria,
        isFeatured: _isFeatured,
      );

      await widget.onSave(product);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Produto salvo com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              Text(
                widget.product == null ? "Cadastrar Produto" : "Editar Produto",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: TemaSite.corPrimaria,
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(
                _nomeController,
                "Nome do Produto",
                Icons.shopping_bag_outlined,
              ),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      _precoController,
                      "Preço",
                      Icons.sell_outlined,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 1,
                    child: _buildTextField(
                      _quantidadeController,
                      "Qtd",
                      Icons.inventory_2_outlined,
                      isOnlyNumbers: true,
                    ),
                  ),
                ],
              ),

              _buildDropdownField(),
              const SizedBox(height: 15),

              // SEÇÃO DE IMAGEM PRINCIPAL COM PREVIEW
              _buildImagePreviewField(
                _imageUrlController,
                "Imagem Principal (URL)",
                Icons.image_outlined,
              ),

              const Divider(height: 30),

              // SEÇÃO DA GALERIA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Imagens da Galeria",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: _addGalleryImage,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text("Adicionar"),
                  ),
                ],
              ),

              ...List.generate(_galleryControllers.length, (index) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildImagePreviewField(
                        _galleryControllers[index],
                        "URL da Imagem ${index + 1}",
                        Icons.link,
                        showValidator: false,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeGalleryImage(index),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                );
              }),

              const Divider(height: 30),

              SwitchListTile(
                title: const Text(
                  "Destaque?",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                activeColor: TemaSite.corPrimaria,
                value: _isFeatured,
                onChanged: (val) => setState(() => _isFeatured = val),
              ),
              _buildTextField(_corController, "Cores", Icons.palette_outlined),
              _buildTextField(
                _compositionController,
                "Material",
                Icons.fact_check_outlined,
              ),
              _buildTextField(
                _descricaoController,
                "Descrição",
                Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() => Container(
    width: 40,
    height: 4,
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(10),
    ),
  );

  // Widget de campo de texto com miniatura de imagem ao lado
  Widget _buildImagePreviewField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool showValidator = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 55,
            height: 55,
            margin: const EdgeInsets.only(right: 10, top: 5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  return value.text.isEmpty
                      ? Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.grey.shade400,
                        )
                      : Image.network(
                          value.text,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                          ),
                        );
                },
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, color: TemaSite.corPrimaria),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: showValidator
                  ? (v) => v == null || v.isEmpty ? "Obrigatório" : null
                  : null,
              onChanged: (_) => setState(() {}), // Atualiza o preview
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool isOnlyNumbers = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: (isNumber || isOnlyNumbers)
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: isNumber ? [CurrencyInputFormatter()] : [],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: TemaSite.corPrimaria),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: (v) => v == null || v.isEmpty ? "Obrigatório" : null,
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _categoriaSelecionada,
      items: _categorias
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      onChanged: (val) => setState(() => _categoriaSelecionada = val),
      decoration: InputDecoration(
        labelText: "Categoria",
        prefixIcon: const Icon(
          Icons.category_outlined,
          color: TemaSite.corPrimaria,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (v) => v == null ? "Selecione" : null,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: TemaSite.corPrimaria,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "SALVAR PRODUTO",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
