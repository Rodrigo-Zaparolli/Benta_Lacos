import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../tema/tema_site.dart';
import '../../models/product.dart';
import '../../utils/currency_input_formatter.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const ProductForm({super.key, this.product, required this.onSave});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();

  // Categorias atualizadas conforme solicitado
  final List<String> _categorias = [
    'Laços',
    'Tiaras',
    'Presilhas',
    'Kits',
    'Faixas',
  ];

  late TextEditingController _nomeController;
  late TextEditingController _precoController;
  late TextEditingController _corController;
  late TextEditingController _compositionController;
  late TextEditingController _descricaoController;

  String? _categoriaSelecionada;
  Uint8List? _imageBytes;
  String? _imageName;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nomeController = TextEditingController(text: p?.name ?? '');
    _precoController = TextEditingController(
      text: p?.price.toStringAsFixed(2).replaceAll('.', ',') ?? '',
    );
    _corController = TextEditingController(text: p?.color ?? '');
    _compositionController = TextEditingController(text: p?.composition ?? '');
    _descricaoController = TextEditingController(text: p?.description ?? '');
    _categoriaSelecionada = p?.category;
    _imageBytes = p?.imageBytes;
    _imageName = p?.imageName;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _corController.dispose();
    _compositionController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      setState(() {
        _imageBytes = result.files.single.bytes;
        _imageName = result.files.single.name;
      });
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final double precoConvertido =
          double.tryParse(
            _precoController.text.replaceAll('.', '').replaceAll(',', '.'),
          ) ??
          0.0;

      final product = Product(
        id:
            widget.product?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nomeController.text.trim(),
        price: precoConvertido,
        category: _categoriaSelecionada,
        color: _corController.text.trim(),
        composition: _compositionController.text.trim(),
        description: _descricaoController.text.trim(),
        imageBytes: _imageBytes,
        imageName: _imageName,
      );
      widget.onSave(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(),
              _buildTitle(), // Título: Novo Produto
              const SizedBox(height: 25),
              _buildTextField(
                _nomeController,
                "Nome do Produto",
                Icons.shopping_bag_outlined,
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      _precoController,
                      "Preço Venda",
                      Icons.sell_outlined,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(child: _buildDropdownField()), // Campo de Categoria
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _corController,
                      "Cor Principal",
                      Icons.palette_outlined,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      _compositionController,
                      "Material/Fita",
                      Icons.straighten_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _descricaoController,
                "Descrição Detalhada",
                Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 25),
              const Text(
                "Imagens do Produto",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              _buildImageSelector(),
              const SizedBox(height: 30),
              _buildSaveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );

  Widget _buildTitle() => Row(
    children: [
      const Text("🛍️", style: TextStyle(fontSize: 24)),
      const SizedBox(width: 10),
      Text(
        widget.product == null ? "Novo Produto" : "Editar Produto",
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber ? [CurrencyInputFormatter()] : [],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: TemaSite.corPrimaria, size: 22),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "Obrigatório" : null,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _categoriaSelecionada,
      decoration: InputDecoration(
        labelText: "Categoria",
        prefixIcon: Icon(
          Icons.category_outlined,
          color: TemaSite.corPrimaria,
          size: 22,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: _categorias
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      onChanged: (val) => setState(() => _categoriaSelecionada = val),
      validator: (value) => value == null ? "Selecione" : null,
    );
  }

  Widget _buildImageSelector() {
    return Row(
      children: [
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                  )
                : const Icon(
                    Icons.add_a_photo_outlined,
                    color: Colors.grey,
                    size: 30,
                  ),
          ),
        ),
        const SizedBox(width: 15),
        const Expanded(
          child: Text(
            "Toque no quadrado para selecionar a foto principal.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: TemaSite.corPrimaria,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: const Text(
          "SALVAR PRODUTO",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
