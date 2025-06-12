import 'package:hive_flutter/hive_flutter.dart';

enum UserRole { comprador, vendedor, ambos }

@HiveType(typeId: 1) // Usamos un typeId diferente al de CartItem (0)
class User extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String email;
  @HiveField(3)
  final String? photoUrl;
  @HiveField(4)
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
  });

  // Método para crear un usuario desde un mapa (útil para Firebase, aunque no se usará directamente con Hive)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      photoUrl: map['photoUrl'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['role']}',
        orElse: () => UserRole.comprador,
      ),
    );
  }

  // Método para convertir un usuario a un mapa (útil para Firebase, aunque no se usará directamente con Hive)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role.toString().split('.').last,
    };
  }

  // Método para crear una copia del usuario con algunos campos modificados
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
    );
  }
} 