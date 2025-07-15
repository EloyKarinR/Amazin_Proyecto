import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;
  bool _isAuthenticating = true;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAuthenticating => _isAuthenticating;

  AuthProvider() {
    _authStateSubscription = firebase_auth.FirebaseAuth.instance.authStateChanges().listen((firebase_auth.User? firebaseUser) {
      if (firebaseUser != null) {
        // Si hay un usuario de Firebase autenticado, crea nuestro User local
        _user = User(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Usuario',
          email: firebaseUser.email ?? '',
          photoUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        // Si no hay usuario autenticado, establece _user a null
        _user = null;
      }
      _isLoading = false;

      // Solo establecer _isAuthenticating en false y notificar la primera vez
      if (_isAuthenticating) {
        _isAuthenticating = false;
        notifyListeners();
      } else {
        // Para cambios de estado posteriores (login/logout), solo notificar si el usuario cambió
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel(); // Cancela la suscripción al stream cuando el provider se desecha
    super.dispose();
  }

  // Método para iniciar sesión
  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Si el inicio de sesión es exitoso, actualiza el usuario
      _user = User(
        id: credential.user!.uid,
        name: credential.user!.displayName ?? 'Usuario', // Usar displayName o un nombre por defecto
        email: credential.user!.email!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _isLoading = false;
      notifyListeners();
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para registrar un nuevo usuario
  Future<void> register(String name, String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await firebase_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar el perfil del usuario con el nombre si lo deseas
      await credential.user!.updateDisplayName(name);

      // Si el registro es exitoso, actualiza el usuario
      _user = User(
        id: credential.user!.uid,
        name: name,
        email: credential.user!.email!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _isLoading = false;
      notifyListeners();
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para cerrar sesión
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await firebase_auth.FirebaseAuth.instance.signOut();
      
      _user = null;
      _isLoading = false;
      notifyListeners();
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para limpiar errores
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Método para iniciar sesión con Google
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Forzar la selección de cuenta, borrando la sesión previa de Google Sign-In
      await GoogleSignIn().signOut();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Si el usuario cancela el inicio de sesión, googleUser será null
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Obtener los detalles de autenticación de la solicitud
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Crear una nueva credencial de Firebase usando los tokens de Google
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase con la credencial de Google
      final userCredential = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
      
      // Actualizar el usuario con la información completa de Google
      _user = User(
        id: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? googleUser.displayName ?? 'Usuario',
        email: userCredential.user!.email ?? googleUser.email,
        photoUrl: userCredential.user!.photoURL ?? googleUser.photoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _isLoading = false;
      notifyListeners();
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para actualizar el nombre de usuario
  Future<void> updateUserName(String newName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final firebase_auth.User? currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _user = _user?.copyWith(name: newName); 
        notifyListeners(); 

        await currentUser.updateDisplayName(newName); 

      } else {
        _error = 'Usuario no autenticado para actualizar el nombre.';
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = e.message; 
    } catch (e) {
      _error = 'Error interno al actualizar perfil. El cambio se guardó, pero hubo un problema de sincronización local.';
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  // Método para actualizar la foto de perfil
  Future<void> updateProfilePhoto(XFile imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final firebase_auth.User? currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final storageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('${currentUser.uid}.jpg');

        await storageRef.putFile(File(imageFile.path));

        final photoUrl = await storageRef.getDownloadURL();

        await currentUser.updatePhotoURL(photoUrl);

        _user = _user?.copyWith(photoUrl: photoUrl);
        
        _isLoading = false;
        notifyListeners();
      } else {
        _error = 'Usuario no autenticado para actualizar la foto de perfil.';
        _isLoading = false;
        notifyListeners();
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}