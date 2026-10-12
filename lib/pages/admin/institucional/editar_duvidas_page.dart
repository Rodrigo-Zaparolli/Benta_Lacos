import 'package:flutter/material.dart';
import 'admin_content_editor.dart';

class EditarDuvidasPage extends StatelessWidget {
  const EditarDuvidasPage({super.key});
  @override
  Widget build(BuildContext context) => const AdminContentEditor(
    documentId: 'duvidas',
    title: 'Dúvidas frequentes',
    imageSettings: false,
  );
}
