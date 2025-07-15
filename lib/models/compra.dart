import 'package:cloud_firestore/cloud_firestore.dart';

class Compra {
  final String id;
  final String idProducto;
  final String idUsuario;
  final DateTime fechaCompra;
  final String estado;
  final int cantidad;
  final double precio;
  final String imageUrl;

  Compra({
    required this.id,
    required this.idProducto,
    required this.idUsuario,
    required this.fechaCompra,
    required this.estado,
    required this.cantidad,
    required this.precio,
    required this.imageUrl,
  });

  factory Compra.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Compra(
      id: doc.id,
      idProducto: data['idProducto'] ?? '',
      idUsuario: data['idUsuario'] ?? '',
      fechaCompra: (data['fechaCompra'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estado: data['estado'] ?? 'pendiente',
      cantidad: data['cantidad'] ?? 1,
      precio: (data['precio'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idProducto': idProducto,
      'idUsuario': idUsuario,
      'fechaCompra': Timestamp.fromDate(fechaCompra),
      'estado': estado,
      'cantidad': cantidad,
      'precio': precio,
      'imageUrl': imageUrl,
    };
  }
} 