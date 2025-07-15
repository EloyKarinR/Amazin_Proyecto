import 'package:cloud_firestore/cloud_firestore.dart';

class Seller {
  final String uid;
  final String nombre;
  final String fotoUrl;
  final String telefono;
  final String? direccion;
  final String? nombreTienda;
  final String? descripcion;
  final String? redSocial;
  final String? ciudad;
  final Timestamp fechaRegistro;
  final double? latitud;
  final double? longitud;

  Seller({
    required this.uid,
    required this.nombre,
    required this.fotoUrl,
    required this.telefono,
    this.direccion,
    this.nombreTienda,
    this.descripcion,
    this.redSocial,
    this.ciudad,
    required this.fechaRegistro,
    this.latitud,
    this.longitud,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'fotoUrl': fotoUrl,
      'telefono': telefono,
      'direccion': direccion,
      'nombreTienda': nombreTienda,
      'descripcion': descripcion,
      'redSocial': redSocial,
      'ciudad': ciudad,
      'fechaRegistro': fechaRegistro,
      'latitud': latitud,
      'longitud': longitud,
    };
  }

  factory Seller.fromMap(Map<String, dynamic> map) {
    return Seller(
      uid: map['uid'],
      nombre: map['nombre'],
      fotoUrl: map['fotoUrl'],
      telefono: map['telefono'],
      direccion: map['direccion'],
      nombreTienda: map['nombreTienda'],
      descripcion: map['descripcion'],
      redSocial: map['redSocial'],
      ciudad: map['ciudad'],
      fechaRegistro: map['fechaRegistro'] ?? Timestamp.now(),
      latitud: map['latitud'] != null ? (map['latitud'] as num).toDouble() : null,
      longitud: map['longitud'] != null ? (map['longitud'] as num).toDouble() : null,
    );
  }
} 