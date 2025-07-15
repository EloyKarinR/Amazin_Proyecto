import 'package:cloud_firestore/cloud_firestore.dart';

class Comentario {
  final String id;
  final String idUsuario;
  final String nombreUsuario;
  final int calificacion; // 1-5
  final String comentario;
  final DateTime fecha;
  final bool compraVerificada;

  Comentario({
    required this.id,
    required this.idUsuario,
    required this.nombreUsuario,
    required this.calificacion,
    required this.comentario,
    required this.fecha,
    this.compraVerificada = false,
  });

  factory Comentario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comentario(
      id: doc.id,
      idUsuario: data['idUsuario'] ?? '',
      nombreUsuario: data['nombreUsuario'] ?? '',
      calificacion: data['calificacion'] ?? 0,
      comentario: data['comentario'] ?? '',
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      compraVerificada: data['compraVerificada'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idUsuario': idUsuario,
      'nombreUsuario': nombreUsuario,
      'calificacion': calificacion,
      'comentario': comentario,
      'fecha': Timestamp.fromDate(fecha),
      'compraVerificada': compraVerificada,
    };
  }
} 