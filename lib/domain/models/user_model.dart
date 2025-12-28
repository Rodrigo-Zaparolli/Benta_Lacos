// lib/models/user_model.dart

class UserModel {
  final String id; // ID do documento (uid do Firebase Auth)
  final String name; // Nome completo
  final String email; // Email do usuário
  final String cpf; // CPF (opcional conforme regra de negócio)
  final String phone; // Telefone / WhatsApp
  final String cep; // CEP
  final String address; // Endereço (rua + número)
  final String neighborhood; // Bairro
  final String city; // Cidade
  final String state; // Estado (UF)

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.cpf,
    required this.phone,
    required this.cep,
    required this.address,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  /// Constrói o usuário a partir do Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      cpf: map['cpf'] ?? '',
      phone: map['phone'] ?? '',
      cep: map['cep'] ?? '',
      address: map['address'] ?? '',
      neighborhood: map['neighborhood'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
    );
  }

  /// Converte o usuário para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'cpf': cpf,
      'phone': phone,
      'cep': cep,
      'address': address,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
    };
  }
}
