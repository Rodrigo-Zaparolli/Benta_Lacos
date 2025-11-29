// lib/widgets/product_form.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/product.dart';
import '../tema/tema_site.dart';
import '../utils/currency_input_formatter.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const ProductForm({super.key, this.product, required this.onSave});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late double _price;
  late double _oldPrice;
  late String _color;
  late String _description;
  late String _composition;
  late String _imageName;

  Uint8List? _imageBytes;
  late String _imagePath;
  List<Uint8List> _galleryImages = [];

  final _priceController = TextEditingController();
  final _oldPriceController = TextEditingController();
  final _assetController = TextEditingController();
  final _imageNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _compositionController = TextEditingController();
  final _descriptionController = TextEditingController();

  void _initializeState(Product? p) {
    _name = p?.name ?? '';
    _price = p?.price ?? 0.0;
    _oldPrice = p?.oldPrice ?? 0.0;
    _color = p?.color ?? '';
    _description = p?.description ?? '';
    _composition = p?.composition ?? '';
    _imageName = p?.imageName ?? '';

    _imageBytes = p?.imageBytes;
    _imagePath = p?.imagePath ?? '';
    _galleryImages = p?.galleryImages ?? [];

    _priceController.text = _price.toStringAsFixed(2).replaceAll('.', ',');
    _oldPriceController.text = (_oldPrice > 0 ? _oldPrice : 0.0)
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    _assetController.text = _imagePath;
    _imageNameController.text = _imageName;
    _nameController.text = _name;
    _colorController.text = _color;
    _compositionController.text = _composition;
    _descriptionController.text = _description;
  }

  @override
  void initState() {
    super.initState();
    _initializeState(widget.product);
  }

  @override
  void didUpdateWidget(covariant ProductForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.product != oldWidget.product) {
      _initializeState(widget.product);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _oldPriceController.dispose();
    _assetController.dispose();
    _imageNameController.dispose();
    _nameController.dispose();
    _colorController.dispose();
    _compositionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _imageBytes = result.files.single.bytes;
        _imageName = result.files.single.name;
        _imageNameController.text = _imageName;
        _imagePath = '';
        _assetController.text = '';
      });
    }
  }

  Future<void> _pickGalleryImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _galleryImages = result.files
            .map((f) => f.bytes!)
            .whereType<Uint8List>()
            .toList();
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newProduct = Product(
        id: widget.product?.id ?? UniqueKey().toString(),
        name: _name,
        price: _price,
        oldPrice: _oldPrice > 0 ? _oldPrice : null,
        color: _color,
        description: _description,
        composition: _composition,
        imageName: _imageName,
        imageBytes: _imageBytes,
        imagePath: _imagePath.isNotEmpty && _imageBytes == null
            ? _imagePath
            : null,
        galleryImages: _galleryImages.isNotEmpty ? _galleryImages : null,
      );
      widget.onSave(newProduct);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;
    const double spacing = 30.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double totalWidth = constraints.maxWidth;

            // 3 colunas exigem 2 espaçamentos (2 * 30.0 = 60.0).
            final double calculatedFieldWidth =
                (totalWidth - (spacing * 2)) / 3;

            // Subtrai uma pequena margem (2.0) para evitar quebras de arredondamento.
            final double safeFieldWidth = calculatedFieldWidth - 2.0;

            // Se a tela for estreita (abaixo de um limite), usa largura total.
            final double effectiveFieldWidth = (safeFieldWidth > 150)
                ? safeFieldWidth
                : totalWidth;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editing ? 'Editar Produto' : 'Cadastrar Novo Produto',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // ----------------------------------------------------
                // SEÇÃO DE CAMPOS DE TEXTO (3 COLUNAS - WRAP)
                // ----------------------------------------------------
                Wrap(
                  spacing: spacing,
                  runSpacing: 20.0,
                  children: [
                    // Nome do Produto (Campo 1)
                    SizedBox(
                      width: effectiveFieldWidth,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Produto',
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'O nome é obrigatório.' : null,
                        onSaved: (v) => _name = v!.trim(),
                      ),
                    ),
                    // Preço (Campo 2)
                    SizedBox(
                      width: effectiveFieldWidth,
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Preço (R\$)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: (v) =>
                            v!.isEmpty ? 'O preço é obrigatório.' : null,
                        onSaved: (v) {
                          final cleanedValue = v!.replaceAll(',', '.');
                          _price = double.tryParse(cleanedValue) ?? 0.0;
                        },
                      ),
                    ),
                    // Preço Antigo (Campo 3)
                    SizedBox(
                      width: effectiveFieldWidth,
                      child: TextFormField(
                        controller: _oldPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Preço Antigo (Opcional)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [CurrencyInputFormatter()],
                        onSaved: (v) {
                          final cleanedValue = v!.replaceAll(',', '.');
                          _oldPrice = double.tryParse(cleanedValue) ?? 0.0;
                        },
                      ),
                    ),
                    // Cor (Campo 4)
                    SizedBox(
                      width: effectiveFieldWidth,
                      child: TextFormField(
                        controller: _colorController,
                        decoration: const InputDecoration(labelText: 'Cor'),
                        validator: (v) =>
                            v!.isEmpty ? 'A cor é obrigatória.' : null,
                        onSaved: (v) => _color = v!.trim(),
                      ),
                    ),
                    // Composição (Campo 5)
                    SizedBox(
                      width: effectiveFieldWidth,
                      child: TextFormField(
                        controller: _compositionController,
                        decoration: const InputDecoration(
                          labelText: 'Composição',
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'A composição é obrigatória.' : null,
                        onSaved: (v) => _composition = v!.trim(),
                      ),
                    ),
                    // Caminho da Imagem (Asset/URL) (Campo 6)
                    SizedBox(
                      width: effectiveFieldWidth,
                      child: TextFormField(
                        controller: _assetController,
                        decoration: const InputDecoration(
                          labelText: 'Caminho Imagem (Asset/URL)',
                        ),
                        onSaved: (v) => _imagePath = v!.trim(),
                      ),
                    ),
                    // Nome da Imagem (Campo 7)
                    SizedBox(
                      width: effectiveFieldWidth,
                      child: TextFormField(
                        controller: _imageNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da Imagem',
                        ),
                        onSaved: (v) => _imageName = v!.trim(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Descrição (Full-Width)
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição do Produto',
                  ),
                  maxLines: 4,
                  validator: (v) =>
                      v!.isEmpty ? 'A descrição é obrigatória.' : null,
                  onSaved: (v) => _description = v!.trim(),
                ),

                const SizedBox(height: 30),
                const Divider(),

                // ----------------------------------------------------
                // SEÇÃO DE IMAGEM PRINCIPAL
                // ----------------------------------------------------
                const SizedBox(height: 20),
                const Text(
                  'Imagem Principal (Destaque)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 200,
                      width: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _imageBytes != null
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : _imagePath.isNotEmpty
                            ? Image.network(
                                _imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Center(child: Text('URL Inválida')),
                              )
                            : const Center(child: Text('Principal')),
                      ),
                    ),

                    const SizedBox(width: 30),

                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Selecionar Principal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TemaSite.corPrimaria,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                const Divider(),

                // ----------------------------------------------------
                // SEÇÃO DE GALERIA (IMAGENS SECUNDÁRIAS)
                // ----------------------------------------------------
                const SizedBox(height: 20),
                const Text(
                  'Galeria de Imagens Secundárias',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickGalleryImages,
                      icon: const Icon(Icons.collections),
                      label: Text(
                        _galleryImages.isEmpty
                            ? 'Selecionar Galeria'
                            : 'Mudar Galeria (${_galleryImages.length})',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TemaSite.corDestaque,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_galleryImages.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: TextButton(
                          onPressed: () => setState(() => _galleryImages = []),
                          child: Text(
                            'Remover Galeria',
                            style: TextStyle(color: TemaSite.corSecundaria),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // MINIATURAS DA GALERIA
                Wrap(
                  spacing: 15.0,
                  runSpacing: 15.0,
                  children: _galleryImages.map((bytes) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(bytes, fit: BoxFit.cover),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),

                // BOTÃO DE SUBMIT
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: Text(editing ? 'Salvar' : 'Cadastrar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaSite.corPrimaria,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
