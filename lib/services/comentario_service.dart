import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comentario.dart';

class ComentarioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtener comentarios de un producto (stream para actualizaciones en tiempo real)
  Stream<List<Comentario>> getComentarios(String idProducto) {
    return _db
        .collection('products')
        .doc(idProducto)
        .collection('comentarios')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comentario.fromFirestore(doc))
            .toList());
  }

  // Agregar un nuevo comentario a un producto
  Future<void> agregarComentario(String idProducto, Comentario comentario) async {
    final productoRef = _db.collection('products').doc(idProducto);
    await productoRef.collection('comentarios').add(comentario.toMap());
    // Recalcular promedio y cantidad de reseñas
    final snapshot = await productoRef.collection('comentarios').get();
    final comentarios = snapshot.docs.map((doc) => Comentario.fromFirestore(doc)).toList();
    if (comentarios.isNotEmpty) {
      final suma = comentarios.fold<double>(0, (a, b) => a + b.calificacion);
      final promedio = suma / comentarios.length;
      await productoRef.update({
        'rating': promedio,
        'reviewCount': comentarios.length,
      });
    }
  }
} 