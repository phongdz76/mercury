import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment.dart';
import '../constants/app_constants.dart';
import 'base_service.dart';

class PaymentService extends BaseService {
  static const String paymentsEndpoint = '/payments';

  /// Create a new payment
  static Future<PaymentResponse> createPayment(PaymentRequest request) async {
    try {
      final headers = await BaseService.getHeaders();
      final url = Uri.parse('${ApiConstants.baseUrl}$paymentsEndpoint');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final paymentResponse = PaymentResponse.fromJson(data);
        return paymentResponse;
      } else {
        throw Exception(data['message'] ?? 'Failed to create payment');
      }
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  /// Get payment by ID
  static Future<Payment> getPayment(String paymentId) async {
    try {
      final headers = await BaseService.getHeaders();
      final url = Uri.parse(
        '${ApiConstants.baseUrl}$paymentsEndpoint/$paymentId',
      );

      final response = await http.get(url, headers: headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Payment.fromJson(data['data']['payment']);
      } else {
        throw Exception(data['message'] ?? 'Failed to get payment');
      }
    } catch (e) {
      throw Exception('Failed to get payment: $e');
    }
  }

  /// Get user's payment history
  static Future<List<Payment>> getPaymentHistory() async {
    try {
      final headers = await BaseService.getHeaders();
      final url = Uri.parse('${ApiConstants.baseUrl}$paymentsEndpoint');

      final response = await http.get(url, headers: headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final payments = data['data']['payments'] as List;
        return payments.map((payment) => Payment.fromJson(payment)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to get payment history');
      }
    } catch (e) {
      throw Exception('Failed to get payment history: $e');
    }
  }

  /// Check payment status
  static Future<PaymentStatus> checkPaymentStatus(String paymentId) async {
    try {
      final payment = await getPayment(paymentId);
      return payment.status;
    } catch (e) {
      throw Exception('Failed to check payment status: $e');
    }
  }

  /// Create MoMo payment
  static Future<PaymentResponse> createMoMoPayment({
    required String plan,
    required double amount,
    String? description,
  }) async {
    final request = PaymentRequest(
      amount: amount,
      currency: 'VND',
      plan: plan,
      paymentMethod: 'momo',
      paymentGateway: 'momo',
      metadata: {if (description != null) 'description': description},
    );

    return await createPayment(request);
  }

  /// Get available premium plans
  static List<PremiumPlan> getPremiumPlans() {
    return PremiumPlan.defaultPlans;
  }

  /// Format currency for display
  static String formatCurrency(double amount, String currency) {
    switch (currency.toUpperCase()) {
      case 'VND':
        return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫';
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }

  /// Get payment status color
  static String getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return '#4CAF50'; // Green
      case PaymentStatus.pending:
        return '#FF9800'; // Orange
      case PaymentStatus.failed:
        return '#F44336'; // Red
      case PaymentStatus.cancelled:
        return '#9E9E9E'; // Grey
      case PaymentStatus.refunded:
        return '#2196F3'; // Blue
    }
  }

  /// Get payment status display text
  static String getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  /// Calculate discount percentage
  static double calculateDiscountPercentage(
    double originalPrice,
    double discountedPrice,
  ) {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - discountedPrice) / originalPrice) * 100;
  }

  /// Validate payment amount
  static bool isValidAmount(double amount) {
    return amount > 0 && amount <= 50000000; // Max 50M VND
  }

  /// Get payment method display name
  static String getPaymentMethodDisplayName(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'momo':
        return 'MoMo Wallet';
      case 'vnpay':
        return 'VNPay';
      case 'zalopay':
        return 'ZaloPay';
      case 'bank':
        return 'Bank Transfer';
      case 'credit_card':
        return 'Credit Card';
      default:
        return paymentMethod;
    }
  }
}
