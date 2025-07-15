import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address.dart';

class AddressService {
  final CollectionReference addressesCollection =
      FirebaseFirestore.instance.collection('addresses');

  // Agregar nueva dirección
  Future<void> addAddress(Address address) async {
    await addressesCollection.add(address.toJson());
  }

  // Obtener todas las direcciones de un usuario
  Future<List<Address>> getUserAddresses(String userId) async {
    final query = await addressesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs
        .map((doc) => Address.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Actualizar dirección
  Future<void> updateAddress(Address address) async {
    await addressesCollection.doc(address.id).update(address.toJson());
  }

  // Eliminar dirección
  Future<void> deleteAddress(String addressId) async {
    await addressesCollection.doc(addressId).delete();
  }

  // Marcar una dirección como predeterminada
  Future<void> setDefaultAddress(String userId, String addressId) async {
    // Obtener todas las direcciones del usuario
    final query = await addressesCollection.where('userId', isEqualTo: userId).get();
    for (var doc in query.docs) {
      await doc.reference.update({'isDefault': doc.id == addressId});
    }
  }

  // Obtener la dirección predeterminada
  Future<Address?> getDefaultAddress(String userId) async {
    final query = await addressesCollection
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return Address.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Cargar países desde el archivo JSON local
  Future<List<Map<String, dynamic>>> loadCountries() async {
    try {
      final String response = await rootBundle.loadString('assets/countries_latam.json');
      final List<dynamic> data = json.decode(response);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error cargando países: $e');
      return [];
    }
  }

  // Cargar ciudades desde el archivo JSON local
  Future<List<Map<String, dynamic>>> loadCities() async {
    try {
      final String response = await rootBundle.loadString('assets/cities_latam.json');
      final List<dynamic> data = json.decode(response);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error cargando ciudades: $e');
      return [];
    }
  }

  // Cargar estados desde el archivo JSON local
  Future<List<Map<String, dynamic>>> loadStates() async {
    try {
      final String response = await rootBundle.loadString('assets/states_latam.json');
      final List<dynamic> data = json.decode(response);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error cargando estados: $e');
      return [];
    }
  }

  // Obtener ciudades por código de país
  Future<List<Map<String, dynamic>>> getCitiesByCountry(String countryCode) async {
    final cities = await loadCities();
    return cities.where((city) => city['countryCode'] == countryCode).toList();
  }

  // Obtener estados por código de país
  Future<List<Map<String, dynamic>>> getStatesByCountry(String countryCode) async {
    final states = await loadStates();
    final countryStates = states.where((state) => state['countryCode'] == countryCode).toList();
    if (countryStates.isNotEmpty) {
      return countryStates.first['states'].cast<Map<String, dynamic>>();
    }
    return [];
  }
} 