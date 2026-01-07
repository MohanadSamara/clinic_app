// lib/services/email_service.dart
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

// EmailJS Configuration - FREE Email Service
// CRITICAL SETUP INSTRUCTIONS:
// 1. Sign up at https://www.emailjs.com/ (free account - 200 emails/month free)
// 2. Create an email service (Gmail, Outlook, Yahoo, etc.)
// 3. IMPORTANT: In your email SERVICE settings, set the recipient email address
// 4. Create an email template with these variables:
//    - {{verification_code}}: The 6-digit verification code
// 5. Replace the credentials below with your actual EmailJS values
// 6. Test the integration - if not configured, it falls back to demo mode
//
// ERROR "recipients address is empty" means: You need to set the recipient email
// in your EmailJS SERVICE configuration, not in the template parameters!

const String _emailJsServiceId = 'service_v3hwr1n'; // Your EmailJS service ID
const String _emailJsTemplateId =
    'template_38xcnsn'; // Your EmailJS template ID
const String _emailJsPublicKey = '_AG0cxQBNoMhgym53'; // Your EmailJS public key
const String _emailJsUrl = 'https://api.emailjs.com/api/v1.0/email/send';

class EmailService {
  static const String _verificationCodesKey = 'verification_codes';

  // Generate a 6-digit verification code
  static String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send verification email using EmailJS (free service)
  static Future<bool> sendVerificationEmail(String email, String code) async {
    try {
      // Check if EmailJS is configured with real credentials
      final isConfigured =
          _emailJsServiceId.isNotEmpty &&
          _emailJsTemplateId.isNotEmpty &&
          _emailJsPublicKey.isNotEmpty &&
          _emailJsServiceId != 'your_service_id' &&
          _emailJsTemplateId != 'your_template_id' &&
          _emailJsPublicKey != 'your_public_key';

      if (!isConfigured) {
        // Fallback to demo mode if not configured
        print('📧 EmailJS not configured - using demo mode');
        print('📧 Verification email would be sent to $email');
        print('🔢 Verification code: $code');
        print(
          '⚠️  Configure EmailJS credentials in email_service.dart for real emails',
        );

        // Store the verification code temporarily
        await _storeVerificationCode(email, code);
        return true;
      }

      // Prepare EmailJS payload
      // Note: Recipient email is configured in EmailJS service dashboard
      final payload = {
        'service_id': _emailJsServiceId,
        'template_id': _emailJsTemplateId,
        'user_id': _emailJsPublicKey,
        'template_params': {'verification_code': code},
      };

      // Send email via EmailJS
      final response = await http.post(
        Uri.parse(_emailJsUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost', // Required for CORS
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('📧 Verification email sent successfully to $email');
        // Store the verification code temporarily
        await _storeVerificationCode(email, code);
        return true;
      } else {
        print(
          '❌ Failed to send email: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error sending verification email: $e');
      return false;
    }
  }

  // Store verification code in shared preferences (temporary storage)
  static Future<void> _storeVerificationCode(String email, String code) async {
    // For simplicity, we'll use a simple in-memory map
    // In production, you might want to use secure storage or a backend
    _verificationCodes[email] = {
      'code': code,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Verify the entered code
  static Future<bool> verifyCode(String email, String enteredCode) async {
    final storedData = _verificationCodes[email];
    if (storedData == null) {
      return false;
    }

    final storedCode = storedData['code'] as String;
    final timestamp = DateTime.parse(storedData['timestamp'] as String);

    // Check if code is expired (15 minutes)
    if (DateTime.now().difference(timestamp).inMinutes > 15) {
      _verificationCodes.remove(email);
      return false;
    }

    final isValid = storedCode == enteredCode;
    if (isValid) {
      // Remove the code after successful verification
      _verificationCodes.remove(email);
    }

    return isValid;
  }

  // Resend verification code
  static Future<String?> resendVerificationCode(String email) async {
    final code = _generateVerificationCode();
    final success = await sendVerificationEmail(email, code);
    return success ? code : null;
  }

  // In-memory storage for demo purposes
  // In production, use secure storage or backend
  static final Map<String, Map<String, dynamic>> _verificationCodes = {};

  // Generate and send verification code for email
  static Future<String?> sendVerificationCode(String email) async {
    final code = _generateVerificationCode();
    final success = await sendVerificationEmail(email, code);
    return success ? code : null;
  }

  // Check if email has a pending verification
  static bool hasPendingVerification(String email) {
    return _verificationCodes.containsKey(email);
  }

  // Clear all verification codes (for testing/cleanup)
  static void clearAllCodes() {
    _verificationCodes.clear();
  }
}
