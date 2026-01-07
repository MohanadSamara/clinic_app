// lib/services/email_service.dart
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// EmailJS Configuration - FREE Email Service
// CRITICAL SETUP INSTRUCTIONS:
// 1. Sign up at https://www.emailjs.com/ (free account - 200 emails/month free)
// 2. Create an email service (Gmail, Outlook, Yahoo, etc.)
// 3. IMPORTANT: In your email SERVICE settings, set the recipient email address
// 4. Create an email template with these variables:
//    - {{verification_code}}: The 6-digit verification code
//    - {{to_email}}: The recipient's email address
// 5. Replace the credentials below with your actual EmailJS values
// 6. Test the integration - if not configured, it falls back to demo mode
//
// ERROR "recipients address is empty" means: You need to set the recipient email
// in your EmailJS SERVICE configuration, or pass it in template_params!

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
          _emailJsServiceId != 'service_v3hwr1n' &&
          _emailJsTemplateId != 'template_38xcnsn' &&
          _emailJsPublicKey != '_AG0cxQBNoMhgym53';

      if (!isConfigured) {
        // Fallback to demo mode if not configured
        // Store the verification code temporarily
        await _storeVerificationCode(email, code);
        return true;
      }

      // Prepare EmailJS payload
      // The recipient must be set in the EmailJS template as {{to_email}}
      final payload = {
        'service_id': _emailJsServiceId,
        'template_id': _emailJsTemplateId,
        'user_id': _emailJsPublicKey,
        'template_params': {'verification_code': code, 'to_email': email},
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

  // Store verification code in shared preferences (persistent storage)
  static Future<void> _storeVerificationCode(String email, String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedJson = prefs.getString(_verificationCodesKey);
      Map<String, dynamic> codes = {};

      if (storedJson != null) {
        codes = jsonDecode(storedJson) as Map<String, dynamic>;
      }

      codes[email] = {
        'code': code,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_verificationCodesKey, jsonEncode(codes));
    } catch (e) {
      print('❌ Error storing verification code: $e');
      // Fallback to in-memory if SharedPreferences fails
      _inMemoryCodes[email] = {
        'code': code,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Verify the entered code
  static Future<bool> verifyCode(String email, String enteredCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedJson = prefs.getString(_verificationCodesKey);
      Map<String, dynamic> codes = {};

      if (storedJson != null) {
        codes = jsonDecode(storedJson) as Map<String, dynamic>;
      }

      // Check in-memory fallback too
      final storedData = codes[email] ?? _inMemoryCodes[email];

      if (storedData == null) {
        return false;
      }

      final storedCode = storedData['code'] as String;
      final timestamp = DateTime.parse(storedData['timestamp'] as String);

      // Check if code is expired (15 minutes)
      if (DateTime.now().difference(timestamp).inMinutes > 15) {
        codes.remove(email);
        _inMemoryCodes.remove(email);
        await prefs.setString(_verificationCodesKey, jsonEncode(codes));
        return false;
      }

      final isValid = storedCode == enteredCode;
      if (isValid) {
        // Remove the code after successful verification
        codes.remove(email);
        _inMemoryCodes.remove(email);
        await prefs.setString(_verificationCodesKey, jsonEncode(codes));
      }

      return isValid;
    } catch (e) {
      print('❌ Error verifying code: $e');
      // Fallback to in-memory check
      final storedData = _inMemoryCodes[email];
      if (storedData != null) {
        final storedCode = storedData['code'] as String;
        final timestamp = DateTime.parse(storedData['timestamp'] as String);
        if (DateTime.now().difference(timestamp).inMinutes <= 15) {
          final isValid = storedCode == enteredCode;
          if (isValid) _inMemoryCodes.remove(email);
          return isValid;
        }
      }
      return false;
    }
  }

  // Resend verification code
  static Future<String?> resendVerificationCode(String email) async {
    return await sendVerificationCode(email);
  }

  // In-memory storage for fallback
  static final Map<String, Map<String, dynamic>> _inMemoryCodes = {};

  // Generate and send verification code for email
  static Future<String?> sendVerificationCode(String email) async {
    final code = _generateVerificationCode();
    final success = await sendVerificationEmail(email, code);
    return success ? code : null;
  }

  // Check if email has a pending verification
  static Future<bool> hasPendingVerification(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedJson = prefs.getString(_verificationCodesKey);
      if (storedJson != null) {
        final codes = jsonDecode(storedJson) as Map<String, dynamic>;
        if (codes.containsKey(email)) return true;
      }
    } catch (_) {}
    return _inMemoryCodes.containsKey(email);
  }

  // Clear all verification codes (for testing/cleanup)
  static Future<void> clearAllCodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_verificationCodesKey);
    } catch (_) {}
    _inMemoryCodes.clear();
  }
}
