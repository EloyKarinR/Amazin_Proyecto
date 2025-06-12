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
          role: UserRole.comprador,
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
        role: UserRole.comprador, // Puedes obtener el rol de Firebase si lo almacenas allí
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
  Future<void> register(String name, String email, String password, UserRole role) async {
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
        role: role,
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
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Iniciar el flujo de inicio de sesión interactivo de Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Si el usuario cancela el inicio de sesión, googleUser será null
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return; // Salir si el usuario canceló
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
        role: UserRole.comprador,
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
    notifyListeners(); // Notifica para mostrar el estado de carga

    try {
      final firebase_auth.User? currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // *** IMPORTANTE: Actualizar el usuario local ANTES de la llamada a Firebase,
        // ya que la llamada a Firebase puede lanzar un error de Pigeon que no nos impide
        // actualizar el backend, pero sí rompe el flujo local de UI.
        _user = _user?.copyWith(name: newName); // Actualiza el usuario local instantáneamente
        notifyListeners(); // Notifica a los oyentes para que la UI se actualice AL INSTANTE

        await currentUser.updateDisplayName(newName); // Esto puede lanzar el error de Pigeon internamente

      } else {
        _error = 'Usuario no autenticado para actualizar el nombre.';
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = e.message; // Captura errores específicos de autenticación de Firebase
      // Si hay un error de Firebase Auth, podrías revertir el cambio local aquí si lo necesitas
      // o simplemente dejar que el error se propague para informar al usuario.
    } catch (e) {
      // Esto capturará el error de Pigeon u otros errores inesperados.
      // Ya que sabemos que el backend de Firebase SÍ se actualiza, mantenemos el _user local actualizado.
      _error = 'Error interno al actualizar perfil. El cambio se guardó, pero hubo un problema de sincronización local.';
    } finally {
      _isLoading = false;
      notifyListeners(); // Notificación final para asegurar que el estado de carga se desactive y la UI esté actualizada.
    }
  }

  // Método para actualizar la foto de perfil
  Future<void> updateProfilePhoto(XFile imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notifica para mostrar el estado de carga

    print('DEBUG FOTO: Iniciando updateProfilePhoto.');
    try {
      final firebase_auth.User? currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('DEBUG FOTO: Usuario actual UID: ${currentUser.uid}');
        final storageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('user_photos')
            .child('${currentUser.uid}.jpg'); // Nombre del archivo basado en UID

        print('DEBUG FOTO: Subiendo archivo a: ${storageRef.fullPath}');
        await storageRef.putFile(File(imageFile.path));
        print('DEBUG FOTO: Archivo subido con éxito. Obteniendo URL...');

        final photoUrl = await storageRef.getDownloadURL();
        print('DEBUG FOTO: URL de descarga obtenida: $photoUrl');

        await currentUser.updatePhotoURL(photoUrl);
        print('DEBUG FOTO: photoURL de Firebase actualizado.');

        // Actualizar el usuario local en el provider
        _user = _user?.copyWith(photoUrl: photoUrl);
        notifyListeners(); // Notifica a los oyentes para que la UI se actualice AL INSTANTE
        print('DEBUG FOTO: Usuario local y UI notificados.');

      } else {
        _error = 'Usuario no autenticado para actualizar la foto.';
        print('DEBUG FOTO: Error: Usuario no autenticado.');
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = e.message;
      print('DEBUG FOTO: FirebaseAuthException: ${e.message}');
    } on firebase_storage.FirebaseException catch (e) {
      _error = 'Error al subir la imagen a Storage: ${e.message}';
      print('DEBUG FOTO: FirebaseStorageException: ${e.message}');
    } catch (e) {
      _error = 'Error inesperado al actualizar la foto: ${e.toString()}';
      print('DEBUG FOTO: Error general (catch all): ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('DEBUG FOTO: Finalizando updateProfilePhoto.');
    }
  }
} 