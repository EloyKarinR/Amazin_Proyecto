import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/compra.dart';

class CompraService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Registrar una nueva compra para un usuario
  Future<void> registrarCompra(String idUsuario, Compra compra) async {
    await _db
        .collection('usuarios')
        .doc(idUsuario)
        .collection('compras')
        .add(compra.toMap());
    
    // Descontar stock del producto y registrar venta para el vendedor
    final productoRef = _db.collection('products').doc(compra.idProducto);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(productoRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final stockActual = (data['stock'] ?? 0) as int;
      final nuevoStock = stockActual - compra.cantidad;
      transaction.update(productoRef, {'stock': nuevoStock < 0 ? 0 : nuevoStock});
      
      // Registrar venta para el vendedor
      final sellerId = data['sellerId'] as String?;
      if (sellerId != null) {
        final ventaRef = _db.collection('ventas_vendedores').doc();
        transaction.set(ventaRef, {
          'sellerId': sellerId,
          'productId': compra.idProducto,
          'userId': idUsuario,
          'monto': compra.precio * compra.cantidad,
          'cantidad': compra.cantidad,
          'fecha': compra.fechaCompra,
          'productName': data['name'] ?? '',
          'productImage': data['imageUrl'] ?? '',
        });
      }
    });
  }

  // Obtener todas las compras de un usuario
  Stream<List<Compra>> getComprasUsuario(String idUsuario) {
    return _db
        .collection('usuarios')
        .doc(idUsuario)
        .collection('compras')
        .orderBy('fechaCompra', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Compra.fromFirestore(doc))
            .toList());
  }

  // Verificar si el usuario ha comprado un producto específico y su estado
  Future<bool> usuarioHaCompradoProducto(String idUsuario, String idProducto) async {
    final query = await _db
        .collection('usuarios')
        .doc(idUsuario)
        .collection('compras')
        .where('idProducto', isEqualTo: idProducto)
        .where('estado', isEqualTo: 'entregado')
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // Actualizar el estado de una compra
  Future<void> actualizarEstadoCompra(String idUsuario, String idCompra, String nuevoEstado) async {
    await _db
        .collection('usuarios')
        .doc(idUsuario)
        .collection('compras')
        .doc(idCompra)
        .update({'estado': nuevoEstado});
  }

  // Eliminar una compra
  Future<void> eliminarCompra(String idUsuario, String idCompra) async {
    await _db
        .collection('usuarios')
        .doc(idUsuario)
        .collection('compras')
        .doc(idCompra)
        .delete();
  }

  // Eliminar todas las compras de un usuario
  Future<void> limpiarHistorialCompras(String idUsuario) async {
    final compras = await _db
        .collection('usuarios')
        .doc(idUsuario)
        .collection('compras')
        .get();
    for (final doc in compras.docs) {
      await doc.reference.delete();
    }
  }
} 