import 'package:flutter/material.dart';
import '../constants/file_constants.dart';
import '../constants/app_theme.dart';
import '../screens/premium_purchase_screen.dart';

class FileSizeExceedDialog extends StatelessWidget {
  final String message;
  final bool showUpgradeOption;

  const FileSizeExceedDialog({
    super.key,
    required this.message,
    this.showUpgradeOption = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 24),
          const SizedBox(width: 8),
          const Text('File Size Limit'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (showUpgradeOption) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Premium Benefits:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitItem(
                    'Upload files up to ${FileConstants.premiumSizeLimit}',
                  ),
                  _buildBenefitItem('Unlimited message history'),
                  _buildBenefitItem('HD video calls'),
                  _buildBenefitItem('Priority support'),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (showUpgradeOption) ...[
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PremiumPurchaseScreen(),
                ),
              );
            },
            icon: const Icon(Icons.upgrade),
            label: const Text('Upgrade to Premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.green),
          const SizedBox(width: 6),
          Expanded(child: Text(benefit, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  /// Show dialog for file size exceeded
  static Future<void> show(
    BuildContext context, {
    required String message,
    required bool showUpgradeOption,
  }) {
    return showDialog(
      context: context,
      builder: (context) => FileSizeExceedDialog(
        message: message,
        showUpgradeOption: showUpgradeOption,
      ),
    );
  }
}
