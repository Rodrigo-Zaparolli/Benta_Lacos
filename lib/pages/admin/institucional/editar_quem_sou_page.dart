import 'package:flutter/material.dart';
import 'admin_content_editor.dart';

class EditarQuemSouPage extends StatelessWidget {
  const EditarQuemSouPage({super.key});
  @override
  Widget build(BuildContext context) => const AdminContentEditor(
    documentId: 'quem_sou',
    title: 'Quem sou',
    imageSettings: true,
  );
}
