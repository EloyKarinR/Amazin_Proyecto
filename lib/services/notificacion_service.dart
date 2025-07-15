import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notificacion.dart';

class NotificacionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> crearNotificacion(Notificacion notificacion) async {
    await _db
        .collection('usuarios')
        .doc(notificacion.idUsuario)
        .collection('notificaciones')
        .add(notificacion.toMap());
  }

  Stream<List<Notificacion>> getNotificacionesUsuario(String idUsuario) {
    return _db
        .collection('usuarios')
        .doc(idUsuario)
        .collection('notificaciones')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Notificacion.fromFirestore(doc))
            .toList());
  }

  Future<void> marcarComoLeida(String idUsuario, String idNotificacion) async {
    await _db
        .collection('usuarios')
        .doc(idUsuario)
        .collection('notificaciones')
        .doc(idNotificacion)
        .update({'leida': true});
  }

  Future<int> contarNoLeidas(String idUsuario) async {
    final query = await _db
        .collection('usuarios')
        .doc(idUsuario)
        .collection('notificaciones')
        .where('leida', isEqualTo: false)
        .get();
    return query.docs.length;
  }
} 