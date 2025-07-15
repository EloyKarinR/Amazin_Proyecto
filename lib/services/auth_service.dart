import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registro con email y contraseña
  Future<app_user.User> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      // Crear usuario en Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crear documento de usuario en Firestore
      final app_user.User user = app_user.User(
        id: result.user!.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.id).set(user.toJson());

      return user;
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  // Inicio de sesión con email y contraseña
  Future<app_user.User> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore.collection('users').doc(result.user!.uid).get();
      if (!doc.exists) {
        throw Exception('Usuario no encontrado');
      }

      return app_user.User.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // Actualizar perfil de usuario
  Future<void> updateUserProfile(app_user.User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }
} 