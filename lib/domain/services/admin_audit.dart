import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Map<String, dynamic> auditEntry(
  String action, {
  Map<String, dynamic>? details,
}) {
  final user = FirebaseAuth.instance.currentUser;
  return {
    'acao': action,
    'data': Timestamp.now(),
    'usuarioId': user?.uid,
    'autor': user?.email ?? 'Administrador',
    if (details != null) 'detalhes': details,
  };
}
