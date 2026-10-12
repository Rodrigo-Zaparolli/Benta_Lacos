import 'package:flutter/material.dart';
import 'admin_content_editor.dart';

class EditarTrocasDevolucoesPage extends StatelessWidget {
  const EditarTrocasDevolucoesPage({super.key});
  @override
  Widget build(BuildContext context) => const AdminContentEditor(
    documentId: 'trocas',
    title: 'Trocas e devoluções',
    imageSettings: false,
  );
}
