import 'package:flutter/material.dart';
import 'admin_content_editor.dart';

class EditarPoliticaPage extends StatelessWidget {
  const EditarPoliticaPage({super.key});
  @override
  Widget build(BuildContext context) => const AdminContentEditor(
    documentId: 'politica',
    title: 'Política de privacidade',
    imageSettings: false,
  );
}
