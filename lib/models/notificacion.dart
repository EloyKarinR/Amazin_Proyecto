import 'package:cloud_firestore/cloud_firestore.dart';

class Notificacion {
  final String id;
  final String idUsuario;
  final String titulo;
  final String mensaje;
  final bool leida;
  final DateTime fecha;
  final String idCompra;
  final String idProducto;

  Notificacion({
    required this.id,
    required this.idUsuario,
    required this.titulo,
    required this.mensaje,
    required this.leida,
    required this.fecha,
    required this.idCompra,
    required this.idProducto,
  });

  factory Notificacion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Notificacion(
      id: doc.id,
      idUsuario: data['idUsuario'] ?? '',
      titulo: data['titulo'] ?? '',
      mensaje: data['mensaje'] ?? '',
      leida: data['leida'] ?? false,
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      idCompra: data['idCompra'] ?? '',
      idProducto: data['idProducto'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idUsuario': idUsuario,
      'titulo': titulo,
      'mensaje': mensaje,
      'leida': leida,
      'fecha': Timestamp.fromDate(fecha),
      'idCompra': idCompra,
      'idProducto': idProducto,
    };
  }
} 