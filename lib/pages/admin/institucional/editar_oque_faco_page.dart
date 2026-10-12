import 'package:flutter/material.dart';
import 'admin_content_editor.dart';

class EditarOQueFacoPage extends StatelessWidget {
  const EditarOQueFacoPage({super.key});
  @override
  Widget build(BuildContext context) => const AdminContentEditor(
    documentId: 'oque_faco',
    title: 'O que faço',
    imageSettings: true,
  );
}
