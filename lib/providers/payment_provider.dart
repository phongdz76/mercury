import 'package:flutter/foundation.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  List<Payment> _payments = [];
  Payment? _currentPayment;
  bool _isLoading = false;
  String? _error;
  List<PremiumPlan> _premiumPlans = [];

  // Getters
  List<Payment> get payments => _payments;
  Payment? get currentPayment => _currentPayment;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PremiumPlan> get premiumPlans => _premiumPlans;

  PaymentProvider() {
    _loadPremiumPlans();
  }

  void _loadPremiumPlans() {
    _premiumPlans = PaymentService.getPremiumPlans();
    notifyListeners();
  }

  /// Create a new payment
  Future<PaymentResponse?> createPayment({
    required String plan,
    required double amount,
    String paymentMethod = 'momo',
    String? description,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final response = await PaymentService.createMoMoPayment(
        plan: plan,
        amount: amount,
        description: description,
      );

      if (response.success && response.payment != null) {
        _currentPayment = response.payment;
        _payments.add(response.payment!);
        _sortPayments();
      }

      return response;
    } catch (e) {
      _error = 'Failed to create payment: ${e.toString()}';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Load payment history
  Future<void> loadPaymentHistory() async {
    try {
      _setLoading(true);
      _error = null;

      _payments = await PaymentService.getPaymentHistory();
      _sortPayments();
    } catch (e) {
      _error = 'Failed to load payment history: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  /// Get payment by ID
  Future<Payment?> getPayment(String paymentId) async {
    try {
      _setLoading(true);
      _error = null;

      final payment = await PaymentService.getPayment(paymentId);

      // Update local payment if it exists
      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index != -1) {
        _payments[index] = payment;
        _sortPayments();
      } else {
        _payments.add(payment);
        _sortPayments();
      }

      return payment;
    } catch (e) {
      _error = 'Failed to get payment: ${e.toString()}';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Check payment status
  Future<PaymentStatus?> checkPaymentStatus(String paymentId) async {
    try {
      final status = await PaymentService.checkPaymentStatus(paymentId);

      // Update local payment status
      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index != -1) {
        _payments[index] = _payments[index].copyWith(status: status);
        notifyListeners();
      }

      return status;
    } catch (e) {
      _error = 'Failed to check payment status: ${e.toString()}';
      return null;
    }
  }

  /// Update payment status locally (for real-time updates)
  void updatePaymentStatus(String paymentId, PaymentStatus status) {
    final index = _payments.indexWhere((p) => p.id == paymentId);
    if (index != -1) {
      _payments[index] = _payments[index].copyWith(status: status);

      if (_currentPayment?.id == paymentId) {
        _currentPayment = _payments[index];
      }

      notifyListeners();
    }
  }

  /// Get premium plan by ID
  PremiumPlan? getPremiumPlan(String planId) {
    try {
      return _premiumPlans.firstWhere((plan) => plan.id == planId);
    } catch (e) {
      return null;
    }
  }

  /// Get pending payments
  List<Payment> getPendingPayments() {
    return _payments
        .where((payment) => payment.status == PaymentStatus.pending)
        .toList();
  }

  /// Get completed payments
  List<Payment> getCompletedPayments() {
    return _payments
        .where((payment) => payment.status == PaymentStatus.completed)
        .toList();
  }

  /// Get failed payments
  List<Payment> getFailedPayments() {
    return _payments
        .where((payment) => payment.status == PaymentStatus.failed)
        .toList();
  }

  /// Calculate total spent
  double getTotalSpent() {
    return _payments
        .where((payment) => payment.status == PaymentStatus.completed)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  /// Check if user has any pending payments
  bool hasPendingPayments() {
    return _payments.any((payment) => payment.status == PaymentStatus.pending);
  }

  /// Get most recent payment
  Payment? getMostRecentPayment() {
    if (_payments.isEmpty) return null;
    return _payments.first; // Assuming payments are sorted by date
  }

  /// Clear current payment
  void clearCurrentPayment() {
    _currentPayment = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh payment data
  Future<void> refresh() async {
    await loadPaymentHistory();
  }

  /// Sort payments by creation date (newest first)
  void _sortPayments() {
    _payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Format currency for display
  String formatCurrency(double amount, String currency) {
    return PaymentService.formatCurrency(amount, currency);
  }

  /// Get payment status color
  String getPaymentStatusColor(PaymentStatus status) {
    return PaymentService.getPaymentStatusColor(status);
  }

  /// Get payment status text
  String getPaymentStatusText(PaymentStatus status) {
    return PaymentService.getPaymentStatusText(status);
  }

  /// Get payment method display name
  String getPaymentMethodDisplayName(String paymentMethod) {
    return PaymentService.getPaymentMethodDisplayName(paymentMethod);
  }

  /// Validate payment amount
  bool isValidAmount(double amount) {
    return PaymentService.isValidAmount(amount);
  }

  /// Calculate savings for yearly plan
  double calculateYearlySavings() {
    final monthly = getPremiumPlan('monthly');
    final yearly = getPremiumPlan('yearly');

    if (monthly == null || yearly == null) return 0;

    final monthlyYearlyCost = monthly.price * 12;
    return monthlyYearlyCost - yearly.price;
  }

  /// Get savings percentage for yearly plan
  double getYearlySavingsPercentage() {
    final monthly = getPremiumPlan('monthly');
    final yearly = getPremiumPlan('yearly');

    if (monthly == null || yearly == null) return 0;

    final monthlyYearlyCost = monthly.price * 12;
    return PaymentService.calculateDiscountPercentage(
      monthlyYearlyCost,
      yearly.price,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
