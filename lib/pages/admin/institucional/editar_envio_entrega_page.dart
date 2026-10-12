import 'package:flutter/material.dart';
import 'admin_content_editor.dart';

class EditarEnvioEntregaPage extends StatelessWidget {
  const EditarEnvioEntregaPage({super.key});
  @override
  Widget build(BuildContext context) => const AdminContentEditor(
    documentId: 'envio',
    title: 'Envio e entrega',
    imageSettings: false,
  );
}
