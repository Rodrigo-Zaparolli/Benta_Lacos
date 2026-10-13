import 'package:benta_lacos/core/config/store_environment.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/models/product_model.dart';
import '../utils/currency_input_formatter.dart';

class _Photo {
  String? url;
  final Uint8List? bytes;
  final String extension;
  _Photo({this.url, this.bytes, this.extension = 'jpg'});
}

class ProductForm extends StatefulWidget {
  final Product? product;
  final Future<void> Function(Product) onSave;
  const ProductForm({super.key, this.product, required this.onSave});
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _price = TextEditingController(),
      _quantity = TextEditingController(),
      _productionDays = TextEditingController(),
      _capacity = TextEditingController(),
      _color = TextEditingController(),
      _composition = TextEditingController(),
      _description = TextEditingController();
  final _photos = <_Photo>[];
  late final String _id;
  String? _category;
  bool _featured = false, _saving = false;
  bool _madeToOrder = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _id =
        p?.id ??
        StoreEnvironment.database
            .collection(StoreEnvironment.collectionName('produtos'))
            .doc()
            .id;
    _name.text = p?.name ?? '';
    _price.text = p?.price.toStringAsFixed(2).replaceAll('.', ',') ?? '';
    _quantity.text = '${p?.quantity ?? 0}';
    _productionDays.text = '${p?.productionDays ?? 7}';
    _capacity.text = '${p?.orderCapacity ?? 10}';
    _madeToOrder = p?.madeToOrder ?? false;
    _color.text = p?.color ?? '';
    _composition.text = p?.composition ?? '';
    _description.text = p?.description ?? '';
    _category = p?.category;
    _featured = p?.isFeatured ?? false;
    for (final url in [
      if (p?.imageUrl?.isNotEmpty == true) p!.imageUrl!,
      ...?p?.galleryUrls,
    ].toSet()) {
      if (url.isNotEmpty) _photos.add(_Photo(url: url));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _price,
      _quantity,
      _productionDays,
      _capacity,
      _color,
      _composition,
      _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _parsedPrice => double.tryParse(
    _price.text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim(),
  );
  Future<void> _pickPhotos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: true,
        withData: true,
      );
      if (result == null || !mounted) return;
      final photos = <_Photo>[];
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null || bytes.length > 5 * 1024 * 1024)
          throw StateError('Cada foto deve ter até 5 MB.');
        final jpg = bytes.length > 2 && bytes[0] == 255 && bytes[1] == 216;
        final png =
            bytes.length > 8 &&
            bytes[0] == 137 &&
            bytes[1] == 80 &&
            bytes[2] == 78 &&
            bytes[3] == 71;
        final webp =
            bytes.length > 12 &&
            String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
            String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP';
        if (!jpg && !png && !webp)
          throw StateError('Selecione fotos JPG, PNG ou WebP válidas.');
        photos.add(
          _Photo(
            bytes: bytes,
            extension: png
                ? 'png'
                : webp
                ? 'webp'
                : 'jpg',
          ),
        );
      }
      setState(() {
        _photos.addAll(photos);
        _error = null;
      });
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is StateError
              ? e.message
              : 'Não foi possível selecionar as fotos.',
        );
    }
  }

  Future<void> _addUrl() async {
    final c = TextEditingController();
    final url = await showDialog<String>(
      useRootNavigator: false,
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar foto por endereço'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: 'URL https://'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final uri = Uri.tryParse(c.text.trim());
              if (uri != null &&
                  ['http', 'https'].contains(uri.scheme) &&
                  uri.host.isNotEmpty)
                Navigator.pop(ctx, c.text.trim());
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    c.dispose();
    if (url != null && mounted) setState(() => _photos.add(_Photo(url: url)));
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_photos.isEmpty) {
      setState(() => _error = 'Adicione pelo menos uma foto do produto.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      for (var i = 0; i < _photos.length; i++) {
        final photo = _photos[i];
        if (photo.url != null) continue;
        final ref = FirebaseStorage.instance.ref(
          StoreEnvironment.storagePath(
            'produtos/$_id/${DateTime.now().microsecondsSinceEpoch}_$i.${photo.extension}',
          ),
        );
        await ref.putData(
          photo.bytes!,
          SettableMetadata(
            contentType: photo.extension == 'jpg'
                ? 'image/jpeg'
                : 'image/${photo.extension}',
          ),
        );
        photo.url = await ref.getDownloadURL();
      }
      final base =
          widget.product ??
          Product(
            id: _id,
            name: '',
            price: 0,
            description: '',
            color: '',
            composition: '',
          );
      final product = base.copyWith(
        name: _name.text.trim(),
        price: _parsedPrice,
        quantity: int.parse(_quantity.text),
        madeToOrder: _madeToOrder,
        productionDays: int.tryParse(_productionDays.text) ?? 7,
        orderCapacity: int.tryParse(_capacity.text) ?? 10,
        category: _category,
        color: _color.text.trim(),
        composition: _composition.text.trim(),
        description: _description.text.trim(),
        isFeatured: _featured,
        imageUrl: _photos.first.url,
        galleryUrls: _photos.skip(1).map((p) => p.url!).toList(),
      );
      await widget.onSave(product);
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is StateError
              ? e.message
              : 'Não foi possível salvar. Verifique sua conexão e as permissões de upload e tente novamente.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController c, {
    int lines = 1,
    bool required = false,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (v) => required && (v ?? '').trim().isEmpty
              ? 'Preencha este campo'
              : null,
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AbsorbPointer(
      absorbing: _saving,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.product == null
                          ? 'Cadastrar produto'
                          : 'Editar produto',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar formulário',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _field('Nome do produto', _name, required: true),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [CurrencyInputFormatter()],
                decoration: const InputDecoration(labelText: 'Preço em reais'),
                validator: (_) =>
                    _parsedPrice == null ||
                        !_parsedPrice!.isFinite ||
                        _parsedPrice! <= 0
                    ? 'Informe um preço maior que zero'
                    : null,
              ),
              const SizedBox(height: 16),
              _field(
                'Unidades prontas em estoque',
                _quantity,
                validator: (v) =>
                    int.tryParse(v ?? '') == null || int.parse(v!) < 0
                    ? 'Informe uma quantidade inteira a partir de zero'
                    : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fabricar sob encomenda'),
                subtitle: const Text('Aceitar pedidos sem estoque pronto.'),
                value: _madeToOrder,
                onChanged: (value) => setState(() => _madeToOrder = value),
              ),
              if (_madeToOrder) ...[
                _field(
                  'Prazo de fabricação em dias corridos',
                  _productionDays,
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                      ? 'Informe pelo menos 1 dia'
                      : null,
                ),
                _field(
                  'Máximo de unidades por pedido',
                  _capacity,
                  validator: (v) =>
                      (int.tryParse(v ?? '') ?? 0) < 1 ||
                          (int.tryParse(v ?? '') ?? 0) > 100
                      ? 'Informe de 1 a 100 unidades'
                      : null,
                ),
              ],
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items:
                    {
                          if (_category != null) _category!,
                          'Laços',
                          'Tiaras',
                          'Presilhas',
                          'Kits',
                          'Faixas',
                        }
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) => _category = v,
                validator: (v) => v == null ? 'Selecione a categoria' : null,
              ),
              const SizedBox(height: 16),
              _field('Cor', _color),
              _field('Composição', _composition),
              _field('Descrição', _description, lines: 4),
              const Text(
                'Fotos do produto',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'A primeira foto será a capa. Arraste para organizar. JPG, PNG ou WebP, até 5 MB por foto.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: _saving
                    ? (_, __) {}
                    : (a, b) => setState(() {
                        if (b > a) b--;
                        final photo = _photos.removeAt(a);
                        _photos.insert(b, photo);
                      }),
                children: List.generate(_photos.length, (i) {
                  final p = _photos[i];
                  return ListTile(
                    key: ObjectKey(p),
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 64,
                      height: 64,
                      child: p.bytes != null
                          ? Image.memory(
                              p.bytes!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined),
                            )
                          : Image.network(
                              p.url!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                    ),
                    title: Text(i == 0 ? 'Foto de capa' : 'Foto ${i + 1}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Remover foto',
                          onPressed: _saving
                              ? null
                              : () => setState(() => _photos.removeAt(i)),
                          icon: const Icon(Icons.delete_outline),
                        ),
                        ReorderableDragStartListener(
                          index: i,
                          enabled: !_saving,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.drag_handle),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickPhotos,
                    icon: const Icon(Icons.upload_outlined),
                    label: const Text('Selecionar fotos'),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _addUrl,
                    child: const Text('Adicionar por URL'),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Destacar na página inicial'),
                value: _featured,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _featured = v),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                ),
                child: Text(
                  _saving ? 'Salvando produto e fotos...' : 'Salvar produto',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
