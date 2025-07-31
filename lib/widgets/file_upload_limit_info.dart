import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../constants/file_constants.dart';
import '../constants/app_theme.dart';
import '../screens/premium_purchase_screen.dart';

class FileUploadLimitInfo extends StatelessWidget {
  const FileUploadLimitInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final user = chatProvider.currentUser;
        final isPremium = user?.isPremium ?? false;
        final maxSizeLabel = FileConstants.getFileSizeLabel(isPremium);

        if (isPremium) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Premium: Upload files up to $maxSizeLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Free: Upload limit $maxSizeLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PremiumPurchaseScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Upgrade',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

class CompactFileUploadLimitInfo extends StatelessWidget {
  const CompactFileUploadLimitInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final user = chatProvider.currentUser;
        final isPremium = user?.isPremium ?? false;
        final maxSizeLabel = FileConstants.getFileSizeLabel(isPremium);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            'Max: $maxSizeLabel${!isPremium ? ' (Free)' : ' (Premium)'}',
            style: TextStyle(
              fontSize: 10,
              color: isPremium ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}
