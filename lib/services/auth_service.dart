// lib/services/auth_service.dart
// Firebase Authentication Service
// Handles all authentication operations with Firebase Auth

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Authentication errors
class AuthException implements Exception {
  final String message;
  final AuthErrorCode? code;

  AuthException(this.message, {this.code});
}

enum AuthErrorCode {
  emailAlreadyInUse,
  invalidEmail,
  weakPassword,
  userNotFound,
  wrongPassword,
  userDisabled,
  tooManyRequests,
  networkError,
  unknown,
}

class AuthService {
  // Singleton pattern
  static final AuthService instance = AuthService._init();
  AuthService._init();

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Check if email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // ========== REGISTRATION ==========

  /// Register a new user with email and password
  /// Creates Firebase Auth user and Firestore profile document
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    required UserRole role,
    String? area,
  }) async {
    try {
      // Validate input
      if (email.trim().isEmpty) {
        throw AuthException(
          'Email is required',
          code: AuthErrorCode.invalidEmail,
        );
      }
      if (password.length < 6) {
        throw AuthException(
          'Password must be at least 6 characters',
          code: AuthErrorCode.weakPassword,
        );
      }
      if (name.trim().isEmpty) {
        throw AuthException('Name is required');
      }

      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      // Set verification status based on role
      final verificationStatus =
          (role == UserRole.doctor || role == UserRole.driver)
          ? 'pending'
          : 'verified';

      // Create user profile
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email.trim().toLowerCase(),
        name: name.trim(),
        phone: phone?.trim(),
        role: role,
        area: area,
        verificationStatus: verificationStatus,
      );

      // Save to Firestore - use auth.uid as document ID
      await _saveUserToFirestore(userModel);

      // Send email verification
      if (role == UserRole.owner) {
        await credential.user!.sendEmailVerification();
      }

      debugPrint('✅ User registered successfully: ${userModel.email}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getErrorMessage(e.code),
        code: _getErrorCode(e.code),
      );
    } catch (e) {
      throw AuthException('Registration failed: $e');
    }
  }

  // ========== LOGIN ==========

  /// Login with email and password
  /// Only authenticates - does NOT recreate Firestore documents
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      if (email.trim().isEmpty) {
        throw AuthException(
          'Email is required',
          code: AuthErrorCode.invalidEmail,
        );
      }
      if (password.isEmpty) {
        throw AuthException('Password is required');
      }

      // Sign in with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      // Get user profile from Firestore
      final userModel = await _getUserFromFirestore(credential.user!.uid);

      if (userModel == null) {
        // User exists in Auth but not in Firestore
        throw AuthException('User profile not found. Please contact support.');
      }

      debugPrint('✅ User logged in: ${userModel.email}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getErrorMessage(e.code),
        code: _getErrorCode(e.code),
      );
    } catch (e) {
      throw AuthException('Login failed: $e');
    }
  }

  // ========== LOGOUT ==========

  /// Sign out the current user
  Future<void> logout() async {
    try {
      await _auth.signOut();
      debugPrint('✅ User signed out');
    } catch (e) {
      throw AuthException('Logout failed: $e');
    }
  }

  // ========== PASSWORD RESET ==========

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      if (email.trim().isEmpty) {
        throw AuthException('Email is required');
      }

      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      debugPrint('✅ Password reset email sent');
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getErrorMessage(e.code),
        code: _getErrorCode(e.code),
      );
    } catch (e) {
      throw AuthException('Password reset failed: $e');
    }
  }

  // ========== EMAIL VERIFICATION ==========

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      if (currentUser == null) {
        throw AuthException('No user logged in');
      }
      await currentUser!.sendEmailVerification();
      debugPrint('✅ Email verification sent');
    } catch (e) {
      throw AuthException('Failed to send verification: $e');
    }
  }

  /// Reload user to get updated email verification status
  Future<void> reloadUser() async {
    try {
      if (currentUser != null) {
        await currentUser!.reload();
      }
    } catch (e) {
      debugPrint('Error reloading user: $e');
    }
  }

  // ========== PROFILE MANAGEMENT ==========

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? area,
    String? profileImage,
  }) async {
    try {
      if (currentUser == null) {
        throw AuthException('No user logged in');
      }

      final updates = <String, dynamic>{
        'name': name?.trim(),
        'phone': phone?.trim(),
        'area': area?.trim(),
        'profileImage': profileImage?.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Remove null values
      updates.removeWhere((key, value) => value == null || value == '');

      if (updates.isEmpty) return;

      await _updateUserInFirestore(currentUser!.uid, updates);
      debugPrint('✅ Profile updated');
    } catch (e) {
      throw AuthException('Failed to update profile: $e');
    }
  }

  /// Change password
  Future<void> changePassword(String newPassword) async {
    try {
      if (currentUser == null) {
        throw AuthException('No user logged in');
      }
      if (newPassword.length < 6) {
        throw AuthException(
          'Password must be at least 6 characters',
          code: AuthErrorCode.weakPassword,
        );
      }

      await currentUser!.updatePassword(newPassword);
      debugPrint('✅ Password changed');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'Please log in again to change password',
          code: AuthErrorCode.wrongPassword,
        );
      }
      throw AuthException(
        _getErrorMessage(e.code),
        code: _getErrorCode(e.code),
      );
    } catch (e) {
      throw AuthException('Failed to change password: $e');
    }
  }

  // ========== DELETE ACCOUNT ==========

  /// Delete user account and Firestore profile
  Future<void> deleteAccount() async {
    try {
      if (currentUser == null) {
        throw AuthException('No user logged in');
      }

      final userId = currentUser!.uid;

      // Delete Firestore profile
      await _deleteUserFromFirestore(userId);

      // Delete Auth account
      await currentUser!.delete();

      debugPrint('✅ Account deleted');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'Please log in again to delete account',
          code: AuthErrorCode.wrongPassword,
        );
      }
      throw AuthException(
        _getErrorMessage(e.code),
        code: _getErrorCode(e.code),
      );
    } catch (e) {
      throw AuthException('Failed to delete account: $e');
    }
  }

  // ========== FIRESTORE HELPERS ==========

  Future<void> _saveUserToFirestore(UserModel user) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      debugPrint('Error saving user to Firestore: $e');
    }
  }

  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user from Firestore: $e');
      return null;
    }
  }

  Future<void> _updateUserInFirestore(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      debugPrint('Error updating user in Firestore: $e');
    }
  }

  Future<void> _deleteUserFromFirestore(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint('Error deleting user from Firestore: $e');
    }
  }

  // ========== ERROR HANDLING ==========

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'invalid-email':
        return 'Invalid email format';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'Account is disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-error':
        return 'Network error. Please check your connection';
      default:
        return 'An error occurred. Please try again';
    }
  }

  AuthErrorCode? _getErrorCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return AuthErrorCode.emailAlreadyInUse;
      case 'invalid-email':
        return AuthErrorCode.invalidEmail;
      case 'weak-password':
        return AuthErrorCode.weakPassword;
      case 'user-not-found':
        return AuthErrorCode.userNotFound;
      case 'wrong-password':
        return AuthErrorCode.wrongPassword;
      case 'user-disabled':
        return AuthErrorCode.userDisabled;
      case 'too-many-requests':
        return AuthErrorCode.tooManyRequests;
      case 'network-error':
        return AuthErrorCode.networkError;
      default:
        return AuthErrorCode.unknown;
    }
  }
}
