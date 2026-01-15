import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';

class PasswordUtils {
  // Password strength levels
  static const int minLength = 8;
  static const int strongLength = 12;

  /// Hash a password using bcrypt
  static String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  /// Verify a password against its hash
  static bool verifyPassword(String password, String hashedPassword) {
    try {
      return BCrypt.checkpw(password, hashedPassword);
    } catch (e) {
      // If verification fails, return false
      return false;
    }
  }

  /// Validate password strength and return validation result
  static PasswordValidationResult validatePassword(String password) {
    List<String> errors = [];
    int score = 0;

    // Length check
    if (password.length < minLength) {
      errors.add('Password must be at least $minLength characters long');
    } else {
      score += 1;
      if (password.length >= strongLength) {
        score += 1;
      }
    }

    // Character variety checks
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasLower) {
      errors.add('Password must contain at least one lowercase letter');
    } else {
      score += 1;
    }

    if (!hasUpper) {
      errors.add('Password must contain at least one uppercase letter');
    } else {
      score += 1;
    }

    if (!hasDigit) {
      errors.add('Password must contain at least one number');
    } else {
      score += 1;
    }

    if (!hasSpecial) {
      errors.add('Password must contain at least one special character');
    } else {
      score += 1;
    }

    // Check for common weak passwords
    List<String> commonPasswords = [
      'password',
      '123456',
      '123456789',
      'qwerty',
      'abc123',
      'password123',
      'admin',
      'letmein',
      'welcome',
      'monkey',
    ];

    if (commonPasswords.contains(password.toLowerCase())) {
      errors.add(
        'This password is too common. Please choose a stronger password',
      );
      score = 0; // Reset score for common passwords
    }

    // Determine strength level
    PasswordStrength strength;
    if (score <= 2) {
      strength = PasswordStrength.weak;
    } else if (score <= 4) {
      strength = PasswordStrength.medium;
    } else {
      strength = PasswordStrength.strong;
    }

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      strength: strength,
      errors: errors,
      score: score,
    );
  }

  /// Get password strength color
  static PasswordStrength getPasswordStrength(String password) {
    return validatePassword(password).strength;
  }

  /// Check if password meets minimum requirements
  static bool isPasswordValid(String password) {
    return validatePassword(password).isValid;
  }
}

enum PasswordStrength { weak, medium, strong }

class PasswordValidationResult {
  final bool isValid;
  final PasswordStrength strength;
  final List<String> errors;
  final int score;

  PasswordValidationResult({
    required this.isValid,
    required this.strength,
    required this.errors,
    required this.score,
  });

  String get strengthText {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
}
