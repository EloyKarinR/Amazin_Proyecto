// Modelo para métodos de pago
class PaymentMethod {
  final String id;
  final String userId;
  final String type; // 'credit_card', 'google_pay', 'paypal'
  final String? cardHolder;
  final String? cardNumber;
  final String? expiryDate;
  final String? paypalEmail;
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    this.cardHolder,
    this.cardNumber,
    this.expiryDate,
    this.paypalEmail,
    this.isDefault = false,
    required this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json, String id) {
    return PaymentMethod(
      id: id,
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      cardHolder: json['cardHolder'],
      cardNumber: json['cardNumber'],
      expiryDate: json['expiryDate'],
      paypalEmail: json['paypalEmail'],
      isDefault: json['isDefault'] ?? false,
      createdAt: (json['createdAt'] is DateTime)
          ? json['createdAt']
          : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'cardHolder': cardHolder,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'paypalEmail': paypalEmail,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 