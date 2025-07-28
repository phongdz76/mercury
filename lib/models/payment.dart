class Payment {
  final String? id;
  final String userId;
  final double amount;
  final String currency;
  final String plan;
  final PaymentStatus status;
  final String paymentMethod;
  final String paymentGateway;
  final String? payUrl;
  final int? premiumDuration;
  final DateTime? expiryDate;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.plan,
    required this.status,
    required this.paymentMethod,
    required this.paymentGateway,
    this.payUrl,
    this.premiumDuration,
    this.expiryDate,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] ?? json['id'],
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? '',
      plan: json['plan'] ?? '',
      status: PaymentStatus.fromString(json['status'] ?? 'pending'),
      paymentMethod: json['paymentMethod'] ?? '',
      paymentGateway: json['paymentGateway'] ?? '',
      payUrl: json['payUrl'],
      premiumDuration: json['premiumDuration'],
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'plan': plan,
      'status': status.toString(),
      'paymentMethod': paymentMethod,
      'paymentGateway': paymentGateway,
      if (payUrl != null) 'payUrl': payUrl,
      if (premiumDuration != null) 'premiumDuration': premiumDuration,
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    String? plan,
    PaymentStatus? status,
    String? paymentMethod,
    String? paymentGateway,
    String? payUrl,
    int? premiumDuration,
    DateTime? expiryDate,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      payUrl: payUrl ?? this.payUrl,
      premiumDuration: premiumDuration ?? this.premiumDuration,
      expiryDate: expiryDate ?? this.expiryDate,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled,
  refunded;

  static PaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  @override
  String toString() {
    return name;
  }
}

class PaymentRequest {
  final double amount;
  final String currency;
  final String plan;
  final String paymentMethod;
  final String paymentGateway;
  final Map<String, dynamic>? metadata;

  PaymentRequest({
    required this.amount,
    required this.currency,
    required this.plan,
    required this.paymentMethod,
    required this.paymentGateway,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'plan': plan,
      'paymentMethod': paymentMethod,
      'paymentGateway': paymentGateway,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

class PaymentResponse {
  final bool success;
  final String message;
  final Payment? payment;
  final String? payUrl;

  PaymentResponse({
    required this.success,
    required this.message,
    this.payment,
    this.payUrl,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      payment: json['data']?['payment'] != null
          ? Payment.fromJson(json['data']['payment'])
          : null,
      payUrl: json['data']?['payment']?['payUrl'],
    );
  }
}

class PremiumPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int durationInDays;
  final List<String> features;
  final bool isPopular;

  PremiumPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationInDays,
    required this.features,
    this.isPopular = false,
  });

  factory PremiumPlan.fromJson(Map<String, dynamic> json) {
    return PremiumPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'VND',
      durationInDays: json['durationInDays'] ?? 30,
      features: List<String>.from(json['features'] ?? []),
      isPopular: json['isPopular'] ?? false,
    );
  }

  // Static premium plans
  static List<PremiumPlan> get defaultPlans => [
    PremiumPlan(
      id: 'monthly',
      name: 'Monthly Premium',
      description: 'Premium features for 1 month',
      price: 99000,
      currency: 'VND',
      durationInDays: 30,
      features: [
        'Unlimited message history',
        'File sharing up to 100MB',
        'HD video calls',
        'Priority support',
        'Custom themes',
      ],
    ),
    PremiumPlan(
      id: 'yearly',
      name: 'Yearly Premium',
      description: 'Premium features for 1 year (Save 20%)',
      price: 950000,
      currency: 'VND',
      durationInDays: 365,
      features: [
        'Unlimited message history',
        'File sharing up to 100MB',
        'HD video calls',
        'Priority support',
        'Custom themes',
        'Advanced analytics',
        '20% discount',
      ],
      isPopular: true,
    ),
  ];
}
