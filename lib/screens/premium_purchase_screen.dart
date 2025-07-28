import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment.dart';
import '../providers/payment_provider.dart';
import '../constants/app_theme.dart';

class PremiumPurchaseScreen extends StatefulWidget {
  const PremiumPurchaseScreen({super.key});

  @override
  State<PremiumPurchaseScreen> createState() => _PremiumPurchaseScreenState();
}

class _PremiumPurchaseScreenState extends State<PremiumPurchaseScreen> {
  PremiumPlan? _selectedPlan;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );
    if (paymentProvider.premiumPlans.isNotEmpty) {
      _selectedPlan = paymentProvider.premiumPlans.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Subscription'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium benefits header
                _buildPremiumHeader(),
                const SizedBox(height: 24),

                // Premium features
                _buildPremiumFeatures(),
                const SizedBox(height: 32),

                // Plan selection
                _buildPlanSelection(paymentProvider),
                const SizedBox(height: 32),

                // Purchase button
                _buildPurchaseButton(paymentProvider),
                const SizedBox(height: 16),

                // Terms and conditions
                _buildTermsAndConditions(),

                if (paymentProvider.error != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(paymentProvider.error!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star, color: Colors.amber, size: 32),
          SizedBox(height: 8),
          Text(
            'Upgrade to Premium',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Unlock all premium features and enhance your chat experience',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatures() {
    final features = [
      {
        'icon': Icons.history,
        'title': 'Unlimited Message History',
        'description': 'Access all your messages anytime',
      },
      {
        'icon': Icons.attach_file,
        'title': 'Large File Sharing',
        'description': 'Share files up to 100MB',
      },
      {
        'icon': Icons.video_call,
        'title': 'HD Video Calls',
        'description': 'Crystal clear video quality',
      },
      {
        'icon': Icons.support_agent,
        'title': 'Priority Support',
        'description': '24/7 premium customer support',
      },
      {
        'icon': Icons.palette,
        'title': 'Custom Themes',
        'description': 'Personalize your chat interface',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Premium Features',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...features.map(
          (feature) => _buildFeatureItem(
            feature['icon'] as IconData,
            feature['title'] as String,
            feature['description'] as String,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelection(PaymentProvider paymentProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Plan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...paymentProvider.premiumPlans.map(
          (plan) => _buildPlanCard(plan, paymentProvider),
        ),
      ],
    );
  }

  Widget _buildPlanCard(PremiumPlan plan, PaymentProvider paymentProvider) {
    final isSelected = _selectedPlan?.id == plan.id;
    final savings = plan.id == 'yearly'
        ? paymentProvider.getYearlySavingsPercentage()
        : 0.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: plan.id,
              groupValue: _selectedPlan?.id,
              onChanged: (value) {
                setState(() {
                  _selectedPlan = plan;
                });
              },
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (plan.isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Most Popular',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  if (savings > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Save ${savings.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  paymentProvider.formatCurrency(plan.price, plan.currency),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '/${plan.durationInDays} days',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(PaymentProvider paymentProvider) {
    final isLoading = _isProcessing || paymentProvider.isLoading;
    final canPurchase = _selectedPlan != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canPurchase ? () => _handlePurchase(paymentProvider) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _selectedPlan != null
                    ? 'Purchase ${paymentProvider.formatCurrency(_selectedPlan!.price, _selectedPlan!.currency)}'
                    : 'Select a Plan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Column(
      children: [
        const Text(
          'By purchasing, you agree to our Terms of Service and Privacy Policy.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                // Open Terms of Service
              },
              child: const Text(
                'Terms of Service',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const Text(' • ', style: TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: () {
                // Open Privacy Policy
              },
              child: const Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: const TextStyle(color: Colors.red)),
          ),
          IconButton(
            onPressed: () {
              Provider.of<PaymentProvider>(context, listen: false).clearError();
            },
            icon: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(PaymentProvider paymentProvider) async {
    if (_selectedPlan == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      paymentProvider.clearError();

      final response = await paymentProvider.createPayment(
        plan: _selectedPlan!.id,
        amount: _selectedPlan!.price,
        description: _selectedPlan!.description,
      );

      if (response != null && response.success && response.payUrl != null) {
        // Show success dialog and redirect to payment
        await _showPaymentRedirectDialog(response);
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?.message ?? 'Failed to create payment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _showPaymentRedirectDialog(PaymentResponse response) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your payment has been created successfully.'),
              const SizedBox(height: 16),
              const Text(
                'You will be redirected to MoMo to complete the payment.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan: ${_selectedPlan!.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Amount: ${Provider.of<PaymentProvider>(context, listen: false).formatCurrency(_selectedPlan!.price, _selectedPlan!.currency)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _openPaymentUrl(response.payUrl!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pay with MoMo'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openPaymentUrl(String payUrl) async {
    try {
      final uri = Uri.parse(payUrl);

      // Debug: Print the URL being launched
      print('Attempting to launch URL: $payUrl');
      print('Parsed URI: $uri');

      // Try multiple launch modes for better compatibility
      bool launched = false;

      // First, try to launch with external application
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          print('Successfully launched with external application');
        }
      } catch (e) {
        print('External application launch failed: $e');
      }

      // If external launch failed, try platform default
      if (!launched) {
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
          launched = true;
          print('Successfully launched with platform default');
        } catch (e) {
          print('Platform default launch failed: $e');
        }
      }

      // If platform default failed, try in-app web view
      if (!launched) {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
          launched = true;
          print('Successfully launched with in-app web view');
        } catch (e) {
          print('In-app web view launch failed: $e');
        }
      }

      if (launched) {
        // Show a dialog explaining what happens next
        _showPaymentInProgressDialog();
      } else {
        throw Exception('Could not launch payment URL with any method');
      }
    } catch (e) {
      print('URL launch error: $e');

      // Show manual payment dialog as fallback
      _showManualPaymentDialog(payUrl);
    }
  }

  void _showManualPaymentDialog(String payUrl) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Manual Payment Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Unable to automatically open the payment link. Please copy the link below and open it manually in your browser or MoMo app:',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      payUrl,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: payUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment URL copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy URL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showPaymentInProgressDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('I\'ve Opened the Link'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentInProgressDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment in Progress'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.payment, size: 48, color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Complete your payment in the MoMo app.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Your premium subscription will be activated automatically after successful payment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
