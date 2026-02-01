// lib/providers/auth_provider.dart
// Migrated to Supabase database (PostgreSQL) - 2026-01-31
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../services/supabase_complete_service.dart';
import '../models/user.dart';
import '../firebase_options.dart';
import '../utils/password_utils.dart';
import '../services/email_service.dart';

/// AuthProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: users, doctor_verification_documents, driver_verification_documents
///
/// All database operations now use Supabase client exclusively.
/// SQLite and Firestore have been completely removed.
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  // Supabase service instance for database operations
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  // Temporary data for social login role selection
  Map<String, dynamic>? _pendingSocialUser;

  // Temporary registration data (stored until verification is complete) - UNIFIED for all roles
  Map<String, dynamic>? _pendingRegistration;

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _pendingRegistrationKey = 'pending_registration';

  // Web profile image storage
  static Future<void> _saveWebProfileImage(
    String userId,
    List<int> imageData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = base64Encode(imageData);
    await prefs.setString('web_profile_image_$userId', encoded);
  }

  static Future<List<int>?> _loadWebProfileImage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('web_profile_image_$userId');
    if (encoded != null) {
      return base64Decode(encoded);
    }
    return null;
  }

  static Future<void> _deleteWebProfileImage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('web_profile_image_$userId');
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Update current user
  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }

  // Initialize auth state from shared preferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      if (userData != null) {
        final userMap = jsonDecode(userData) as Map<String, dynamic>;
        _user = User.fromMap(userMap);
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      // Clear corrupted data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'owner',
    String? area,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Validate input
      if (name.trim().isEmpty) throw Exception('Name is required');
      if (email.trim().isEmpty) throw Exception('Email is required');
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Invalid email format');
      }

      // Validate password strength
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      // Check if email exists in Supabase
      final existing = await _supabaseService.getUserByEmail(email);
      if (existing != null) {
        throw Exception('Email already exists');
      }

      final now = DateTime.now();
      final u = User(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: password,
        phone: phone?.trim(),
        role: role,
        area: area,
        verificationStatus: role == 'doctor' ? 'pending' : 'verified',
      );

      final id = await _supabaseService.insertUser(u.toMap());
      // Use the actual UUID string from Supabase, not hashCode
      _user = User.fromMap(u.toMap()..['id'] = id);

      // Save to secure storage
      await _saveUserToStorage(_user!);

      _isLoading = false;
      notifyListeners();

      return id; // Return the UUID string
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Validate input
      if (email.trim().isEmpty) throw Exception('Email is required');
      if (password.isEmpty) throw Exception('Password is required');

      // Get user by email from Supabase
      final userData = await _supabaseService.getUserByEmail(
        email.trim().toLowerCase(),
      );
      if (userData == null) {
        throw Exception(
          'No account found with this email. Please register first.',
        );
      }

      // Verify password (using plain text comparison)
      final storedPassword = userData['password'] as String;
      bool passwordValid = storedPassword == password;

      if (!passwordValid) {
        throw Exception(
          'Invalid password. Please check your password and try again.',
        );
      }

      final res = userData;

      // Set user from database result
      final user = User.fromMap(res);
      _user = user;

      // Save to secure storage
      await _saveUserToStorage(_user!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _user = null;
    _isLoading = false;

    // Sign out from Firebase
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Firebase sign out error: $e');
    }

    // Clear shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);

    notifyListeners();
  }

  /// Register with Firebase Auth and sync to Supabase (cloud database)
  Future<String?> registerWithFirebase({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'owner',
    String? area,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Validate input
      if (name.trim().isEmpty) throw Exception('Name is required');
      if (email.trim().isEmpty) throw Exception('Email is required');
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Invalid email format');
      }

      // Validate password strength
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      // Create user in Firebase Auth
      final firebaseUserCredential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim().toLowerCase(),
            password: password,
          );

      // Determine verification status based on role
      final verificationStatus = (role == 'doctor' || role == 'driver')
          ? 'pending'
          : 'verified';

      // Create user object
      final u = User(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: password,
        phone: phone?.trim(),
        role: role,
        area: area,
        verificationStatus: verificationStatus,
      );

      // Save to Supabase database
      final id = await _supabaseService.insertUser(u.toMap());
      // Use the actual UUID string from Supabase, not hashCode
      _user = User.fromMap(u.toMap()..['id'] = id);

      // Save to secure storage
      await _saveUserToStorage(_user!);

      _isLoading = false;
      notifyListeners();

      return id; // Return the UUID string
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  /// Login with Firebase Auth and sync with Supabase database
  Future<void> loginWithFirebase({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Validate input
      if (email.trim().isEmpty) throw Exception('Email is required');
      if (password.isEmpty) throw Exception('Password is required');

      // Sign in with Firebase Auth
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email.trim().toLowerCase(),
            password: password,
          );

      // Get user from Supabase database
      User? user;

      // Try Supabase database first
      final supabaseUserData = await _supabaseService.getUserByEmail(
        email.trim().toLowerCase(),
      );

      if (supabaseUserData != null) {
        user = User.fromMap(supabaseUserData);
      } else {
        // Create user from Firebase Auth data if not in Supabase
        user = User(
          name: userCredential.user?.displayName ?? email.split('@')[0],
          email: email.trim().toLowerCase(),
          password: password,
          role: 'owner',
          verificationStatus: 'verified',
        );

        final id = await _supabaseService.insertUser(user.toMap());
        // Use the actual UUID string from Supabase, not hashCode
        user = User.fromMap(user.toMap()..['id'] = id);
      }

      _user = user;

      // Save to secure storage
      await _saveUserToStorage(_user!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  // Social Authentication Methods
  Future<void> signInWithGoogle({String? role}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (kIsWeb) {
        // Web implementation using Firebase Auth popup
        final firebase_auth.GoogleAuthProvider googleProvider =
            firebase_auth.GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        final firebase_auth.UserCredential userCredential = await firebase_auth
            .FirebaseAuth
            .instance
            .signInWithPopup(googleProvider);

        await _handleSocialLogin(
          firebaseUser: userCredential.user!,
          provider: 'google',
          providerId: userCredential.user!.uid,
          role: role,
        );
      } else {
        // Mobile implementation using Google Sign In
        // Disconnect first to force account selection
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.disconnect();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Google sign in cancelled');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final firebase_auth.UserCredential userCredential = await firebase_auth
            .FirebaseAuth
            .instance
            .signInWithCredential(credential);

        await _handleSocialLogin(
          firebaseUser: userCredential.user!,
          provider: 'google',
          providerId: userCredential.user!.uid,
          role: role,
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signInWithFacebook() async {
    _isLoading = true;
    notifyListeners();

    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        throw Exception('Facebook sign in failed: ${result.message}');
      }

      final credential = firebase_auth.FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      final firebase_auth.UserCredential userCredential = await firebase_auth
          .FirebaseAuth
          .instance
          .signInWithCredential(credential);

      await _handleSocialLogin(
        firebaseUser: userCredential.user!,
        provider: 'facebook',
        providerId: userCredential.user!.uid,
        role: null,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Switch Google Account
  Future<void> switchGoogleAccount() async {
    final currentRole = _user?.role;
    _isLoading = true;
    notifyListeners();

    try {
      // Sign out from Firebase first
      await firebase_auth.FirebaseAuth.instance.signOut();

      // Then sign in with Google, forcing account selection
      await signInWithGoogle(role: currentRole);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _handleSocialLogin({
    required firebase_auth.User firebaseUser,
    required String provider,
    required String providerId,
    String? role,
  }) async {
    try {
      // Check if user already exists in Supabase
      final existingUser = await _supabaseService.getUserByEmail(
        firebaseUser.email!,
      );

      if (existingUser != null) {
        // Existing user: update with social auth info if needed
        User localUser = User.fromMap(existingUser);
        if (localUser.provider == null) {
          // Update user to include social auth in Supabase
          await _supabaseService.updateUser(localUser.id.toString(), {
            'provider': provider,
            'provider_id': providerId,
          });
          localUser = localUser.copyWith(
            provider: provider,
            providerId: providerId,
          );
        }

        _user = localUser;
        await _saveUserToStorage(_user!);
        _isLoading = false;
        notifyListeners();
      } else {
        // New user
        if (role != null) {
          // For switching, create user with provided role
          final localUser = User(
            name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
            email: firebaseUser.email!,
            password: '', // Social users don't have passwords
            role: role,
            provider: provider,
            providerId: providerId,
            verificationStatus: role == 'doctor' ? 'pending' : 'verified',
          );

          final id = await _supabaseService.insertUser(localUser.toMap());
          // Use the actual UUID string from Supabase, not hashCode
          _user = User.fromMap(localUser.toMap()..['id'] = id);
          await _saveUserToStorage(_user!);
          _isLoading = false;
          notifyListeners();
        } else {
          // Store pending data for role selection
          _pendingSocialUser = {
            'name':
                firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
            'email': firebaseUser.email!,
            'provider': provider,
            'provider_id': providerId,
          };
          _isLoading = false;
          // Do not notify listeners for pending state to avoid UI rebuild issues
        }
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? area,
    String? currentPassword,
    String? newPassword,
    String? profileImagePath,
    List<int>? profileImageBytes,
  }) async {
    if (_user == null) throw Exception('Not authenticated');

    try {
      final updates = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        updates['name'] = name.trim();
      }
      if (phone != null) {
        updates['phone'] = phone.trim().isEmpty ? null : phone.trim();
      }
      if (area != null) {
        updates['area'] = area.trim().isEmpty ? null : area.trim();
      }
      if (kIsWeb && profileImageBytes != null) {
        // For web, store image bytes
        await _saveWebProfileImage(_user!.id!.toString(), profileImageBytes);
        updates['profile_image'] = 'web_profile_image_${_user!.id}';
      } else if (!kIsWeb && profileImagePath != null) {
        // For mobile/desktop, store file path
        updates['profile_image'] = profileImagePath.trim().isEmpty
            ? null
            : profileImagePath.trim();
      } else if (profileImageBytes == null && profileImagePath == null) {
        // Clear profile image
        if (kIsWeb) {
          await _deleteWebProfileImage(_user!.id!.toString());
        }
        updates['profile_image'] = null;
      }

      // Handle password change
      if (newPassword != null && newPassword.isNotEmpty) {
        // Validate new password strength
        final passwordValidation = PasswordUtils.validatePassword(newPassword);
        if (!passwordValidation.isValid) {
          throw Exception(
            'New password: ${passwordValidation.errors.join('. ')}',
          );
        }

        // Verify current password if provided
        if (currentPassword != null && currentPassword.isNotEmpty) {
          bool currentPasswordValid = false;
          if (_user!.password.startsWith('\$2')) {
            // Hashed password
            currentPasswordValid = PasswordUtils.verifyPassword(
              currentPassword,
              _user!.password,
            );
          } else {
            // Plain text password
            currentPasswordValid = currentPassword == _user!.password;
          }
          if (!currentPasswordValid) {
            throw Exception('Current password is incorrect');
          }
        }

        updates['password'] = PasswordUtils.hashPassword(newPassword);
      }

      if (updates.isNotEmpty) {
        await _supabaseService.updateUser(_user!.id.toString(), updates);
        final updatedUser = _user!.copyWith(
          name: updates['name'] ?? _user!.name,
          phone: updates['phone'] ?? _user!.phone,
          area: updates['area'] ?? _user!.area,
          password: updates['password'] ?? _user!.password,
          profileImage: updates['profile_image'] ?? _user!.profileImage,
        );
        _user = updatedUser;
        await _saveUserToStorage(_user!);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveUserToStorage(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }

  // Check if user has specific role
  bool hasRole(String role) {
    return _user?.role.toLowerCase() == role.toLowerCase();
  }

  // Check if user has any of the specified roles
  bool hasAnyRole(List<String> roles) {
    if (_user == null) return false;
    return roles.any((role) => _user!.role.toLowerCase() == role.toLowerCase());
  }

  // Get user permissions based on role
  Map<String, dynamic> getPermissions() {
    if (_user == null) return {};

    // Default permissions based on role
    switch (_user!.role.toLowerCase()) {
      case 'admin':
        return {
          'manage_users': true,
          'manage_doctors': true,
          'manage_services': true,
          'view_reports': true,
          'manage_inventory': true,
        };
      case 'doctor':
        return {
          'manage_appointments': true,
          'manage_medical_records': true,
          'manage_inventory': true,
          'view_reports': true,
        };
      case 'owner':
      default:
        return {
          'book_appointments': true,
          'manage_pets': true,
          'view_appointments': true,
        };
    }
  }

  // Complete social registration with selected role
  Future<void> completeSocialRegistration({
    required String name,
    required String email,
    required String role,
    required String provider,
    required String providerId,
    String? area,
  }) async {
    if (_pendingSocialUser == null) {
      throw Exception('No pending social registration');
    }

    try {
      // Check if user already exists in Supabase
      final existingUser = await _supabaseService.getUserByEmail(email);

      if (existingUser != null) {
        // Update existing user with new role and social auth info
        final updates = <String, dynamic>{'role': role};
        if (existingUser['provider'] == null) {
          updates['provider'] = provider;
          updates['provider_id'] = providerId;
        }
        await _supabaseService.updateUser(existingUser['id'], updates);
        _user = User.fromMap(
          existingUser,
        ).copyWith(role: role, provider: provider, providerId: providerId);
      } else {
        // Create new user
        final localUser = User(
          name: name,
          email: email,
          password: '', // Social users don't have passwords
          role: role,
          provider: provider,
          providerId: providerId,
          area: area,
          verificationStatus: role == 'doctor' ? 'pending' : 'verified',
        );

        final id = await _supabaseService.insertUser(localUser.toMap());
        // Use the actual UUID string from Supabase, not hashCode
        _user = User.fromMap(localUser.toMap()..['id'] = id);
      }

      await _saveUserToStorage(_user!);
      _pendingSocialUser = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Check if role selection is needed
  bool get needsRoleSelection => _pendingSocialUser != null;

  // Get pending social user data
  Map<String, dynamic>? get pendingSocialUser => _pendingSocialUser;

  // ===== Unified Registration Methods =====

  /// Store registration data temporarily (without saving to database) - UNIFIED for all roles
  /// This method stores pending registration data for all user types (owner, doctor, driver, admin)
  Future<void> storePendingRegistration({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String role,
    String? area,
    Map<String, dynamic>? documents,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Preserve existing pending password if caller passed an empty string
    String? existingPassword;
    final existingString = prefs.getString(_pendingRegistrationKey);
    if (existingString != null) {
      try {
        final existingMap = jsonDecode(existingString) as Map<String, dynamic>;
        existingPassword = existingMap['password'] as String?;
      } catch (_) {
        existingPassword = null;
      }
    }

    // Determine which password to store: prefer provided non-empty, else keep existing
    final passwordToStore = (password.isNotEmpty)
        ? password
        : (existingPassword ?? '');

    // Store simple data as JSON to handle special characters in passwords
    final simpleData = {
      'name': name,
      'email': email.toLowerCase(),
      'password': passwordToStore,
      'phone': phone ?? '',
      'role': role,
      'area': area ?? '',
      'created_at': DateTime.now().toIso8601String(),
    };

    // Store documents as JSON (but exclude file bytes for storage)
    final documentsForStorage = <String, dynamic>{};
    if (documents != null) {
      for (final entry in documents.entries) {
        final docData = Map<String, dynamic>.from(entry.value);
        // Remove file bytes - they'll be lost on restart
        docData.remove('file_data');
        documentsForStorage[entry.key] = docData;
      }
    }

    await prefs.setString(_pendingRegistrationKey, jsonEncode(simpleData));
    await prefs.setString(
      '${_pendingRegistrationKey}_documents',
      jsonEncode(documentsForStorage),
    );

    _pendingRegistration = {...simpleData, 'documents': documents ?? {}};
  }

  // Legacy methods for backward compatibility (to be deprecated)
  Future<void> storePendingDoctorRegistration({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String area,
    required Map<String, dynamic> documents,
  }) async {
    await storePendingRegistration(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: 'doctor',
      area: area,
      documents: documents,
    );
  }

  Future<void> storePendingDriverRegistration({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String area,
    required Map<String, dynamic> documents,
  }) async {
    await storePendingRegistration(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: 'driver',
      area: area,
      documents: documents,
    );
  }

  // Unified getters for pending registration
  Map<String, dynamic>? get pendingRegistration => _pendingRegistration;

  bool get hasPendingRegistration => _pendingRegistration != null;

  // Legacy getters for backward compatibility
  Map<String, dynamic>? get pendingDoctorRegistration =>
      hasPendingRegistration && _pendingRegistration!['role'] == 'doctor'
      ? _pendingRegistration
      : null;

  bool get hasPendingDoctorRegistration =>
      hasPendingRegistration && _pendingRegistration!['role'] == 'doctor';

  Map<String, dynamic>? get pendingDriverRegistration =>
      hasPendingRegistration && _pendingRegistration!['role'] == 'driver'
      ? _pendingRegistration
      : null;

  bool get hasPendingDriverRegistration =>
      hasPendingRegistration && _pendingRegistration!['role'] == 'driver';

  /// Complete registration (called after OTP verification and document upload)
  /// This is the unified method for completing registration for all user types
  Future<String?> completeRegistration() async {
    if (_pendingRegistration == null) {
      throw Exception('No pending registration');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final data = _pendingRegistration!;
      final email = data['email'] as String;
      final role = data['role'] as String;

      // Check if email already exists in Supabase (only verified users should block registration)
      final existing = await _supabaseService.getUserByEmail(email);
      if (existing != null) {
        final existingUser = User.fromMap(existing);
        if (existingUser.verificationStatus == 'verified') {
          throw Exception('Email already exists');
        }
        // If unverified, we'll update this record
      }

      // Determine verification status based on role
      // - Doctors and Drivers need document verification
      // - Owners and Admins are verified immediately after OTP
      final verificationStatus = (role == 'doctor' || role == 'driver')
          ? 'pending' // Will be set to 'verified' after document verification
          : 'verified';

      final u = User(
        name: data['name'] as String,
        email: email,
        password: data['password'] as String,
        phone: (data['phone'] as String?)?.isEmpty == true
            ? null
            : data['phone'] as String?,
        role: role,
        area: data['area'] as String?,
        verificationStatus: verificationStatus,
      );

      final id = await _supabaseService.insertUser(u.toMap());
      // Use the actual UUID string from Supabase, not hashCode
      _user = User.fromMap(u.toMap()..['id'] = id);

      // Save documents based on role
      final documents = data['documents'] as Map<String, dynamic>;
      if (documents.isNotEmpty) {
        if (role == 'doctor') {
          for (final entry in documents.entries) {
            final doc = entry.value;
            if (doc['fileName'] != null) {
              final documentData = {
                'doctor_id': id,
                'document_type': doc['document_type'],
                'file_name': doc['fileName'],
                'file_path': doc['file_path'],
                'upload_date': DateTime.now().toIso8601String(),
                'status': 'approved',
                'document_number': doc['documentNumber'] ?? '',
                'expiry_date': doc['expiry_date'],
                'issuing_authority': doc['issuingAuthority'] ?? '',
                'verification_code': doc['verificationCode'] ?? '',
              };
              await _supabaseService.insertDoctorVerificationDocument(
                documentData,
              );
            }
          }
        } else if (role == 'driver') {
          for (final entry in documents.entries) {
            final doc = entry.value;
            if (doc['fileName'] != null) {
              final documentData = {
                'driver_id': id,
                'document_type': doc['document_type'],
                'document_number': doc['documentNumber'] ?? '',
                'file_name': doc['fileName'],
                'file_path': doc['file_path'],
                'upload_date': DateTime.now().toIso8601String(),
                'expiry_date': doc['expiry_date'],
                'issue_date': doc['issue_date'],
                'issuing_authority': doc['issuingAuthority'] ?? '',
                'status': 'approved',
                'verification_code': doc['verificationCode'] ?? '',
                'vehicle_class': doc['vehicleClass'] ?? '',
              };
              await _supabaseService.insertDriverVerificationDocument(
                documentData,
              );
            }
          }
        }
      }

      // Clear pending registration
      await clearPendingRegistration();

      // Save user to storage
      await _saveUserToStorage(_user!);

      _isLoading = false;
      notifyListeners();

      return id; // Return the UUID string
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Legacy completion methods for backward compatibility
  Future<String?> completeDoctorRegistration() async {
    if (_pendingRegistration == null ||
        _pendingRegistration!['role'] != 'doctor') {
      throw Exception('No pending doctor registration');
    }
    return await completeRegistration();
  }

  Future<String?> completeDriverRegistration() async {
    if (_pendingRegistration == null ||
        _pendingRegistration!['role'] != 'driver') {
      throw Exception('No pending driver registration');
    }
    return await completeRegistration();
  }

  // Unified clear method
  Future<void> clearPendingRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingRegistrationKey);
    await prefs.remove('${_pendingRegistrationKey}_documents');
    _pendingRegistration = null;
  }

  // Legacy clear methods for backward compatibility
  Future<void> clearPendingDoctorRegistration() async {
    await clearPendingRegistration();
  }

  Future<void> clearPendingDriverRegistration() async {
    await clearPendingRegistration();
  }

  // Unified load method
  Future<void> loadPendingRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_pendingRegistrationKey);
      if (dataString != null) {
        Map<String, dynamic> dataMap;
        try {
          dataMap = jsonDecode(dataString);
        } catch (e) {
          // Fallback for old string format
          dataMap = <String, dynamic>{};
          for (final pair in dataString.split(',')) {
            final parts = pair.split(':');
            if (parts.length >= 2) {
              final key = parts[0];
              final value = parts.sublist(1).join(':');
              dataMap[key] = value;
            }
          }
        }

        // Load documents from JSON
        final docsString = prefs.getString(
          '${_pendingRegistrationKey}_documents',
        );
        if (docsString != null) {
          try {
            dataMap['documents'] = jsonDecode(docsString);
          } catch (e) {
            dataMap['documents'] = {};
          }
        } else {
          dataMap['documents'] = {};
        }

        _pendingRegistration = dataMap;
      }
    } catch (e) {
      debugPrint('Error loading pending registration: $e');
    }
  }

  // Legacy load methods for backward compatibility
  Future<void> loadPendingDoctorRegistration() async {
    await loadPendingRegistration();
  }

  Future<void> loadPendingDriverRegistration() async {
    await loadPendingRegistration();
  }

  // Get profile image bytes for web
  Future<Uint8List?> getProfileImageBytes() async {
    if (!kIsWeb || _user == null || _user!.profileImage == null) return null;

    if (_user!.profileImage!.startsWith('web_profile_image_')) {
      final bytes = await _loadWebProfileImage(_user!.id!.toString());
      return bytes != null ? Uint8List.fromList(bytes) : null;
    }

    return null;
  }

  Future<void> saveUserPreferences() async {
    if (_user != null) {
      await _saveUserToStorage(_user!);
    }
  }

  Future<void> updateVerificationStatus(String status) async {
    if (_user == null) return;

    try {
      await _supabaseService.updateUser(_user!.id.toString(), {
        'verification_status': status,
      });
      _user = _user!.copyWith(verificationStatus: status);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating verification status: $e');
    }
  }

  // ===== Email Verification Methods =====

  // Send verification code to email
  Future<bool> sendEmailVerificationCode(String email) async {
    try {
      final code = await EmailService.sendVerificationCode(email);
      return code != null;
    } catch (e) {
      debugPrint('Error sending verification code: $e');
      return false;
    }
  }

  // Verify email with code
  Future<bool> verifyEmailCode(String email, String code) async {
    try {
      return await EmailService.verifyCode(email, code);
    } catch (e) {
      debugPrint('Error verifying email code: $e');
      return false;
    }
  }

  // Resend verification code
  Future<bool> resendEmailVerificationCode(String email) async {
    try {
      final code = await EmailService.resendVerificationCode(email);
      return code != null;
    } catch (e) {
      debugPrint('Error resending verification code: $e');
      return false;
    }
  }

  // Check if email has pending verification
  Future<bool> hasPendingEmailVerification(String email) async {
    return await EmailService.hasPendingVerification(email);
  }

  // Register with email verification (modified register method)
  Future<String?> registerWithEmailVerification({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'owner',
    String? area,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Validate input
      if (name.trim().isEmpty) throw Exception('Name is required');
      if (email.trim().isEmpty) throw Exception('Email is required');
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Invalid email format');
      }

      // Validate password strength
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      // Check if email exists in Supabase (only for unverified users)
      final existing = await _supabaseService.getUserByEmail(email);
      if (existing != null) {
        // Allow registration if the existing user is unverified
        final existingUser = User.fromMap(existing);
        if (existingUser.verificationStatus != 'unverified') {
          // If user exists and is verified, check if it's the same user trying to register again
          if (existingUser.email == email &&
              existingUser.verificationStatus == 'verified') {
            // Allow the same user to proceed with OTP verification
            _user = existingUser;
            await _saveUserToStorage(_user!);
            return existingUser.id; // Return the UUID string
          }
          throw Exception('Email already exists');
        }
        // If unverified, we'll update this user instead of creating a new one
      }

      final now = DateTime.now();
      final u = User(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: password,
        phone: phone?.trim(),
        role: role,
        area: area,
        verificationStatus: 'unverified', // Start as unverified
      );

      // Check if we already have a user from the existing check
      final id = existing != null
          ? existing['id']
          : await _supabaseService.insertUser(u.toMap());

      // Use the actual UUID string from Supabase, not hashCode
      _user = User.fromMap(u.toMap()..['id'] = id);

      // Save to secure storage
      await _saveUserToStorage(_user!);

      _isLoading = false;
      notifyListeners();

      return id; // Return the UUID string
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Complete email verification
  Future<bool> completeEmailVerification(String email, String code) async {
    try {
      final isValid = await verifyEmailCode(email, code);
      if (isValid) {
        // Update user verification status only if user exists (for owners)
        if (_user != null) {
          await updateVerificationStatus('verified');
        }
        // For pending registrations (doctors/drivers), OTP verification is complete
        // Navigation will be handled by the UI layer

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error completing email verification: $e');
      return false;
    }
  }

  // Verify OTP and complete doctor registration
  Future<bool> verifyOTPAndCompleteRegistration(
    String email,
    String otp,
  ) async {
    try {
      final isValid = await verifyEmailCode(email, otp);
      if (isValid) {
        // Update user verification status
        await updateVerificationStatus('verified');

        // Update documents status to approved
        if (_user != null && _user!.role == 'doctor') {
          await _supabaseService.updateDoctorDocumentsStatus(
            _user!.id.toString(),
            'approved',
          );
        }

        // Update driver documents status to approved
        if (_user != null && _user!.role == 'driver') {
          await _supabaseService.updateDriverDocumentsStatus(
            _user!.id.toString(),
            'approved',
          );
        }

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error verifying OTP and completing registration: $e');
      return false;
    }
  }

  // Get navigation route after successful OTP verification
  String? getNavigationRouteAfterOTP() {
    if (_user == null) return null;

    switch (_user!.role) {
      case 'doctor':
        return '/doctor/dashboard';
      case 'driver':
        return '/driver/dashboard';
      case 'owner':
        return '/owner/dashboard';
      case 'admin':
        return '/admin/dashboard';
      default:
        return '/home';
    }
  }

  // Get navigation route after successful document verification
  String? getNavigationRouteAfterDocumentVerification() {
    if (_user == null) return null;

    switch (_user!.role) {
      case 'doctor':
        return '/doctor/dashboard';
      case 'driver':
        return '/driver/dashboard';
      case 'owner':
        return '/owner/dashboard';
      case 'admin':
        return '/admin/dashboard';
      default:
        return '/home';
    }
  }
}
