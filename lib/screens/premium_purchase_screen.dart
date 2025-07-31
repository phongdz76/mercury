import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment.dart';
import '../providers/payment_provider.dart';

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star_rounded, color: colorScheme.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            'Upgrade to Premium',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock all premium features and enhance your chat experience',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatures() {
    final features = [
      {
        'icon': Icons.history_rounded,
        'title': 'Unlimited Message History',
        'description': 'Access all your messages anytime',
      },
      {
        'icon': Icons.attach_file_rounded,
        'title': 'Large File Sharing',
        'description': 'Share files up to 100MB',
      },
      {
        'icon': Icons.video_call_rounded,
        'title': 'HD Video Calls',
        'description': 'Crystal clear video quality',
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': 'Priority Support',
        'description': '24/7 premium customer support',
      },
      {
        'icon': Icons.palette_rounded,
        'title': 'Custom Themes',
        'description': 'Personalize your chat interface',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Features',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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
        Text(
          'Choose Your Plan',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...paymentProvider.premiumPlans.map(
          (plan) => _buildPlanCard(plan, paymentProvider),
        ),
      ],
    );
  }

  Widget _buildPlanCard(PremiumPlan plan, PaymentProvider paymentProvider) {
    final colorScheme = Theme.of(context).colorScheme;
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
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : colorScheme.surface,
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
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (plan.isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Most Popular',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.onTertiaryContainer,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (savings > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Save ${savings.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.tertiary,
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  '/${plan.durationInDays} days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(PaymentProvider paymentProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = _isProcessing || paymentProvider.isLoading;
    final canPurchase = _selectedPlan != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: canPurchase ? () => _handlePurchase(paymentProvider) : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _selectedPlan != null
                    ? 'Purchase ${paymentProvider.formatCurrency(_selectedPlan!.price, _selectedPlan!.currency)}'
                    : 'Select a Plan',
                //on text color
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          'By purchasing, you agree to our Terms of Service and Privacy Policy.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
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
              child: Text(
                'Terms of Service',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.primary),
              ),
            ),
            Text(
              ' • ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: () {
                // Open Privacy Policy
              },
              child: Text(
                'Privacy Policy',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_rounded, color: colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Provider.of<PaymentProvider>(context, listen: false).clearError();
            },
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onErrorContainer,
            ),
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
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _openPaymentUrl(response.payUrl!);
              },
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
              style: FilledButton.styleFrom(),
              child: const Text('I\'ve Opened the Link'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentInProgressDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment in Progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.payment_rounded, size: 48, color: colorScheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Complete your payment in the MoMo app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your premium subscription will be activated automatically after successful payment.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
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
