import 'dart:convert';
import 'package:benta_lacos/shared/sections/footer/rodape.dart';
import 'package:benta_lacos/shared/sections/header/cabecalho.dart';
import 'package:benta_lacos/shared/widgets/background_fundo.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class PoliticaPrivacidadePage extends StatelessWidget {
  const PoliticaPrivacidadePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundFundo(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Cabecalho(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('institucional')
                      .doc('politica')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data?.data() == null) {
                      return const Center(
                        child: Text(
                          'Conteúdo não disponível no momento.',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final String? conteudoJson = data['conteudo_json'];
                    final String conteudoFallback = data['conteudo'] ?? '';

                    return Container(
                      constraints: const BoxConstraints(maxWidth: 900),
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Política de Privacidade",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A4A4A),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Divider(height: 30),
                          const SizedBox(height: 15),
                          _buildConteudo(conteudoJson, conteudoFallback),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Rodape(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConteudo(String? jsonStr, String fallback) {
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final document = quill.Document.fromJson(jsonDecode(jsonStr));
        final controller = quill.QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        );

        // 🟢 AJUSTE PARA VERSÕES ANTERIORES (V8 ou V9)
        return quill.QuillEditor.basic(
          controller: controller,
          //readOnly: true, // Nas versões antigas, o readOnly é direto no construtor
        );
      } catch (e) {
        debugPrint('Erro ao renderizar conteúdo Quill: $e');
      }
    }

    return Text(
      fallback,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, height: 1.5),
    );
  }
}
