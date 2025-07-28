import 'package:url_launcher/url_launcher.dart';

class PaymentHelper {
  // Check if MoMo app is installed
  static Future<bool> isMoMoAppInstalled() async {
    try {
      final momoUri = Uri.parse('momo://');
      return await canLaunchUrl(momoUri);
    } catch (e) {
      return false;
    }
  }

  // Launch MoMo payment with multiple fallback strategies
  static Future<bool> launchMoMoPayment(String paymentUrl) async {
    try {
      final uri = Uri.parse(paymentUrl);

      // Try to launch with external application first
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }

      // If that fails, try other modes
      await launchUrl(uri, mode: LaunchMode.platformDefault);
      return true;
    } catch (e) {
      print('Failed to launch MoMo payment: $e');
      return false;
    }
  }
}
