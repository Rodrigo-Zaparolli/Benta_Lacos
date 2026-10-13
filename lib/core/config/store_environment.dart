import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class StoreEnvironment {
  static const isTest = bool.fromEnvironment('STORE_TEST_MODE');
  static FirebaseFirestore get database => FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: '(default)',
  );
  static String collectionName(String name) => isTest ? 'teste_$name' : name;
  static String storagePath(String path) => isTest ? 'teste/$path' : path;
}
