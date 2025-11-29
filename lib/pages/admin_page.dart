// lib/pages/admin_page.dart
import 'package:flutter/material.dart';
import '../tema/tema_site.dart';
import '../repository/product_repository.dart';
import '../models/product.dart';
import '../widgets/product_form.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  void initState() {
    super.initState();
    ProductRepository.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    ProductRepository.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _openForm(Product? p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductForm(
        product: p,
        onSave: (prod) {
          if (p == null) {
            ProductRepository.instance.addProduct(prod);
          } else {
            ProductRepository.instance.updateProduct(prod);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ProductRepository.instance.products;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        backgroundColor: TemaSite.corPrimaria,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (_, i) {
            final p = products[i];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: p.imageBytes != null
                      ? Image.memory(
                          p.imageBytes!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : (p.imagePath != null
                            ? Image.asset(
                                p.imagePath!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey.shade200,
                              )),
                ),
                title: Text(p.name),
                subtitle: Text(
                  'R\$ ${p.price.toStringAsFixed(2)} · ${p.color}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: TemaSite.corSecundaria),
                      onPressed: () => _openForm(p),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () =>
                          ProductRepository.instance.deleteProduct(p.id),
                    ),
                  ],
                ),
                onTap: () => _openForm(p),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TemaSite.corPrimaria,
        onPressed: () => _openForm(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
