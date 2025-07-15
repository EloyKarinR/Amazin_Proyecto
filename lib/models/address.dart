import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String userId;
  final String country;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;
  final String? deliveryInstructions;
  final DateTime createdAt;

  Address({
    required this.id,
    required this.userId,
    required this.country,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false,
    this.deliveryInstructions,
    required this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json, String id) {
    return Address(
      id: id,
      userId: json['userId'] ?? '',
      country: json['country'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      isDefault: json['isDefault'] ?? false,
      deliveryInstructions: json['deliveryInstructions'],
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'country': country,
      'fullName': fullName,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'isDefault': isDefault,
      'deliveryInstructions': deliveryInstructions,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
} 