import 'package:flutter/material.dart';
import 'admin_content_editor.dart';

class EditarHistoriaPage extends StatelessWidget {
  const EditarHistoriaPage({super.key});
  @override
  Widget build(BuildContext context) => const AdminContentEditor(
    documentId: 'nossa_historia',
    title: 'História da marca',
    imageSettings: true,
  );
}
