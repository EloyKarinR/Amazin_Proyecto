import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/product.dart';
import '../models/category.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Categorías
  Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      return snapshot.docs.map((doc) => Category.fromJson(doc.data() /* as Map<String, dynamic> */)).toList();
    } catch (e) {
      // print('Error getting categories: $e');
      return [];
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      await _firestore.collection('categories').doc(category.id).set(category.toJson());
    } catch (e) {
      // print('Error adding category: $e');
      rethrow;
    }
  }

  // Productos
  Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs.map((doc) => Product.fromJson(doc.data() /* as Map<String, dynamic> */)).toList();
    } catch (e) {
      // print('Error getting products: $e');
      return [];
    }
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('categoryId', isEqualTo: categoryId)
          .get();
      return snapshot.docs.map((doc) => Product.fromJson(doc.data() /* as Map<String, dynamic> */)).toList();
    } catch (e) {
      // print('Error getting products by category: $e');
      return [];
    }
  }

  Future<String> uploadProductImage(File imageFile) async {
    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = _storage.ref().child('product_images/$fileName.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      // print('Error uploading product image: $e');
      rethrow;
    }
  }

  Future<void> addProduct(Product product, File? imageFile) async {
    try {
      String imageUrl = product.imageUrl;
      if (imageFile != null) {
        imageUrl = await uploadProductImage(imageFile);
      }

      final productWithImage = Product(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        imageUrl: imageUrl,
        categoryId: product.categoryId,
        stock: product.stock,
        rating: product.rating,
        reviewCount: product.reviewCount,
        isFeatured: product.isFeatured,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sellerId: product.sellerId,
      );

      await _firestore.collection('products').doc(product.id).set(productWithImage.toJson());
    } catch (e) {
      // print('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(Product product, File? newImageFile) async {
    try {
      String imageUrl = product.imageUrl;
      if (newImageFile != null) {
        imageUrl = await uploadProductImage(newImageFile);
      }

      final updatedProduct = Product(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        imageUrl: imageUrl,
        categoryId: product.categoryId,
        stock: product.stock,
        rating: product.rating,
        reviewCount: product.reviewCount,
        isFeatured: product.isFeatured,
        createdAt: product.createdAt,
        updatedAt: DateTime.now(),
        sellerId: product.sellerId,
      );

      await _firestore.collection('products').doc(product.id).update(updatedProduct.toJson());
    } catch (e) {
      // print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      // print('Error deleting product: $e');
      rethrow;
    }
  }

  Future<Product?> getProductById(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return Product.fromJson(data);
  }

  Stream<Product?> streamProductById(String id) {
    return _firestore.collection('products').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return Product.fromJson(data);
    });
  }
} 