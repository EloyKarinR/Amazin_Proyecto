import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seller.dart';

class SellerService {
  final CollectionReference sellersCollection = FirebaseFirestore.instance.collection('sellers');

  Future<void> createSeller(Seller seller) async {
    await sellersCollection.doc(seller.uid).set(seller.toMap());
  }

  Future<Seller?> getSellerByUid(String uid) async {
    final doc = await sellersCollection.doc(uid).get();
    if (doc.exists) {
      return Seller.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<bool> isSeller(String uid) async {
    final doc = await sellersCollection.doc(uid).get();
    return doc.exists;
  }
} 