import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_method.dart';

class PaymentMethodService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection('payment_methods');

  // Agregar método de pago
  Future<void> addPaymentMethod(PaymentMethod method) async {
    final doc = await _collection.add(method.toJson());
    // Si es predeterminado, actualizar los demás
    if (method.isDefault) {
      await setDefaultPaymentMethod(method.userId, doc.id);
    }
  }

  // Obtener métodos de pago de un usuario
  Future<List<PaymentMethod>> getUserPaymentMethods(String userId) async {
    final query = await _collection.where('userId', isEqualTo: userId).get();
    return query.docs.map((doc) => PaymentMethod.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  // Eliminar método de pago
  Future<void> deletePaymentMethod(String id) async {
    await _collection.doc(id).delete();
  }

  // Marcar como predeterminado
  Future<void> setDefaultPaymentMethod(String userId, String methodId) async {
    final query = await _collection.where('userId', isEqualTo: userId).get();
    for (final doc in query.docs) {
      await doc.reference.update({'isDefault': doc.id == methodId});
    }
  }

  // Obtener el método de pago predeterminado
  Future<PaymentMethod?> getDefaultPaymentMethod(String userId) async {
    final query = await _collection
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return PaymentMethod.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }
} 