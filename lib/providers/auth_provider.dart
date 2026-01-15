// lib/providers/auth_provider.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../db/db_helper.dart';
import '../models/user.dart';
import '../firebase_options.dart';
import '../utils/password_utils.dart';
import '../services/email_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  // Temporary data for social login role selection
  Map<String, dynamic>? _pendingSocialUser;

  // Temporary doctor registration data (stored until verification is complete)
  Map<String, dynamic>? _pendingDoctorRegistration;

  // Temporary driver registration data (stored until verification is complete)
  Map<String, dynamic>? _pendingDriverRegistration;

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _pendingDoctorKey = 'pending_doctor_registration';

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

  Future<int?> register({
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
      final passwordValidation = PasswordUtils.validatePassword(password);
      if (!passwordValidation.isValid) {
        throw Exception(passwordValidation.errors.join('. '));
      }

      // Check if email exists
      final existing = await DBHelper.instance.getUserByEmail(email);
      if (existing != null) {
        throw Exception('Email already exists');
      }

      final now = DateTime.now();
      final u = User(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: password, // Save as plain text
        phone: phone?.trim(),
        role: role,
        area: area,
        verificationStatus: role == 'doctor' ? 'pending' : 'verified',
      );

      final id = await DBHelper.instance.insertUser(u.toMap());
      _user = User.fromMap(u.toMap()..['id'] = id);

      // Save to secure storage
      await _saveUserToStorage(_user!);

      _isLoading = false;
      notifyListeners();

      return id;
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

      // Get user by email first
      final userData = await DBHelper.instance.getUserByEmail(
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
    await firebase_auth.FirebaseAuth.instance.signOut();

    // Clear shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);

    notifyListeners();
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
      // Check if user already exists in local DB
      final existingUser = await DBHelper.instance.getUserByEmail(
        firebaseUser.email!,
      );

      if (existingUser != null) {
        // Existing user: update with social auth info if needed
        User localUser = User.fromMap(existingUser);
        if (localUser.provider == null) {
          // Update user to include social auth
          await DBHelper.instance.updateUser(localUser.id!, {
            'provider': provider,
            'providerId': providerId,
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

          final id = await DBHelper.instance.insertUser(localUser.toMap());
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
            'provider': providerId,
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
        updates['profileImage'] = 'web_profile_image_${_user!.id}';
      } else if (!kIsWeb && profileImagePath != null) {
        // For mobile/desktop, store file path
        updates['profileImage'] = profileImagePath.trim().isEmpty
            ? null
            : profileImagePath.trim();
      } else if (profileImageBytes == null && profileImagePath == null) {
        // Clear profile image
        if (kIsWeb) {
          await _deleteWebProfileImage(_user!.id!.toString());
        }
        updates['profileImage'] = null;
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
        await DBHelper.instance.updateUser(_user!.id!, updates);
        final updatedUser = _user!.copyWith(
          name: updates['name'] ?? _user!.name,
          phone: updates['phone'] ?? _user!.phone,
          area: updates['area'] ?? _user!.area,
          password: updates['password'] ?? _user!.password,
          profileImage: updates['profileImage'] ?? _user!.profileImage,
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
      // Check if user already exists
      final existingUser = await DBHelper.instance.getUserByEmail(email);

      if (existingUser != null) {
        // Update existing user with new role and social auth info
        final updates = <String, dynamic>{'role': role};
        if (existingUser['provider'] == null) {
          updates['provider'] = provider;
          updates['providerId'] = providerId;
        }
        await DBHelper.instance.updateUser(existingUser['id'], updates);
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

        final id = await DBHelper.instance.insertUser(localUser.toMap());
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

  // ===== Doctor Registration Methods =====

  // Store doctor registration data temporarily (without saving to database)
  Future<void> storePendingDoctorRegistration({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String area,
    required Map<String, dynamic> documents,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Store simple data as JSON to handle special characters in passwords
    final simpleData = {
      'name': name,
      'email': email.toLowerCase(),
      'password': password,
      'phone': phone ?? '',
      'area': area,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Store documents as JSON (but exclude file bytes for storage)
    final documentsForStorage = <String, dynamic>{};
    for (final entry in documents.entries) {
      final docData = Map<String, dynamic>.from(entry.value);
      // Remove file bytes - they'll be lost on restart
      docData.remove('file_data');
      documentsForStorage[entry.key] = docData;
    }

    await prefs.setString(_pendingDoctorKey, jsonEncode(simpleData));
    await prefs.setString(
      '${_pendingDoctorKey}_documents',
      jsonEncode(documentsForStorage),
    );

    _pendingDoctorRegistration = {...simpleData, 'documents': documents};
  }

  // Store driver registration data temporarily (without saving to database)
  Future<void> storePendingDriverRegistration({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String area,
    required Map<String, dynamic> documents,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Store simple data as JSON to handle special characters in passwords
    final simpleData = {
      'name': name,
      'email': email.toLowerCase(),
      'password': password,
      'phone': phone ?? '',
      'area': area,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Store documents as JSON (but exclude file bytes for storage)
    final documentsForStorage = <String, dynamic>{};
    for (final entry in documents.entries) {
      final docData = Map<String, dynamic>.from(entry.value);
      // Remove file bytes - they'll be lost on restart
      docData.remove('file_data');
      documentsForStorage[entry.key] = docData;
    }

    await prefs.setString('pending_driver_registration', jsonEncode(simpleData));
    await prefs.setString(
      'pending_driver_registration_documents',
      jsonEncode(documentsForStorage),
    );

    _pendingDriverRegistration = {...simpleData, 'documents': documents};
  }

  // Get pending doctor registration data
  Map<String, dynamic>? get pendingDoctorRegistration =>
      _pendingDoctorRegistration;

  // Check if there's pending doctor registration
  bool get hasPendingDoctorRegistration => _pendingDoctorRegistration != null;

  // Get pending driver registration data
  Map<String, dynamic>? get pendingDriverRegistration =>
      _pendingDriverRegistration;

  // Check if there's pending driver registration
  bool get hasPendingDriverRegistration => _pendingDriverRegistration != null;

  // Complete doctor registration (called after OTP verification)
  Future<int?> completeDoctorRegistration() async {
    if (_pendingDoctorRegistration == null) {
      throw Exception('No pending doctor registration');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final data = _pendingDoctorRegistration!;
      final email = data['email'] as String;

      // Check if email already exists (only verified users should block registration)
      final existing = await DBHelper.instance.getUserByEmail(email);
      if (existing != null) {
        final existingUser = User.fromMap(existing);
        if (existingUser.verificationStatus == 'verified') {
          throw Exception('Email already exists');
        }
        // If unverified, we'll update this record
      }

      final u = User(
        name: data['name'] as String,
        email: email,
        password: data['password'] as String, // Save as plain text
        phone: (data['phone'] as String?)?.isEmpty == true
            ? null
            : data['phone'] as String?,
        role: 'doctor',
        area: data['area'] as String?,
        verificationStatus:
            'verified', // Set to verified after document verification
      );

      final id = await DBHelper.instance.insertUser(u.toMap());
      _user = User.fromMap(u.toMap()..['id'] = id);

      // Save documents with approved status (since verification is complete)
      final documents = data['documents'] as Map<String, dynamic>;
      for (final entry in documents.entries) {
        final doc = entry.value;
        if (doc['fileName'] != null) {
          final documentData = {
            'doctor_id': id,
            'document_type': doc['document_type'],
            'file_name': doc['fileName'],
            'file_path': doc['file_path'],
            'file_data': doc['file_data'],
            'upload_date': DateTime.now().toIso8601String(),
            'status': 'approved', // Documents are approved after verification
            'document_number': doc['documentNumber'] ?? '',
            'expiry_date': doc['expiry_date'],
            'issuing_authority': doc['issuingAuthority'] ?? '',
            'verification_code': doc['verificationCode'] ?? '',
          };
          await DBHelper.instance.insertDoctorVerificationDocument(
            documentData,
          );
        }
      }

      // Clear pending registration
      await clearPendingDoctorRegistration();

      // Save user to storage
      await _saveUserToStorage(_user!);

      _isLoading = false;
      notifyListeners();

      return id;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Complete driver registration (called after OTP verification)
  Future<int?> completeDriverRegistration() async {
    if (_pendingDriverRegistration == null) {
      throw Exception('No pending driver registration');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final data = _pendingDriverRegistration!;
      final email = data['email'] as String;

      // Check if email already exists
      final existing = await DBHelper.instance.getUserByEmail(email);
      if (existing != null) {
        // If the existing user is unverified, we can proceed with registration
        final existingUser = User.fromMap(existing);
        if (existingUser.verificationStatus == 'unverified') {
          // This is likely a retry of the registration process, so we can proceed
          // The user will be updated during the completion process
        } else {
          throw Exception('Email already exists');
        }
      }

      final u = User(
        name: data['name'] as String,
        email: email,
        password: data['password'] as String, // Save as plain text
        phone: (data['phone'] as String?)?.isEmpty == true
            ? null
            : data['phone'] as String?,
        role: 'driver',
        area: data['area'] as String?,
        verificationStatus:
            'verified', // Set to verified after document verification
      );

      final id = await DBHelper.instance.insertUser(u.toMap());
      _user = User.fromMap(u.toMap()..['id'] = id);

      // Save documents with pending status
      final documents = data['documents'] as Map<String, dynamic>;
      for (final entry in documents.entries) {
        final doc = entry.value;
        if (doc['fileName'] != null) {
          final documentData = {
            'driver_id': id,
            'document_type': doc['document_type'],
            'document_number': doc['documentNumber'] ?? '',
            'file_name': doc['fileName'],
            'file_path': doc['file_path'],
            'file_data': doc['file_data'],
            'upload_date': DateTime.now().toIso8601String(),
            'expiry_date': doc['expiry_date'],
            'issue_date': doc['issue_date'],
            'issuing_authority': doc['issuingAuthority'] ?? '',
            'status': 'approved', // Documents are approved after verification
            'verification_code': doc['verificationCode'] ?? '',
            'vehicle_class': doc['vehicleClass'] ?? '',
          };
          await DBHelper.instance.insertDriverVerificationDocument(
            documentData,
          );
        }
      }

      // Clear pending registration
      await clearPendingDriverRegistration();

      // Save user to storage
      await _saveUserToStorage(_user!);

      _isLoading = false;
      notifyListeners();

      return id;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Clear pending doctor registration
  Future<void> clearPendingDoctorRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingDoctorKey);
    await prefs.remove('${_pendingDoctorKey}_documents');
    _pendingDoctorRegistration = null;
  }

  // Clear pending driver registration
  Future<void> clearPendingDriverRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_driver_registration');
    await prefs.remove('pending_driver_registration_documents');
    _pendingDriverRegistration = null;
  }

  // Load pending doctor registration from storage
  Future<void> loadPendingDoctorRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_pendingDoctorKey);
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
        final docsString = prefs.getString('${_pendingDoctorKey}_documents');
        if (docsString != null) {
          try {
            dataMap['documents'] = jsonDecode(docsString);
          } catch (e) {
            dataMap['documents'] = {};
          }
        } else {
          dataMap['documents'] = {};
        }

        _pendingDoctorRegistration = dataMap;
      }
    } catch (e) {
      debugPrint('Error loading pending doctor registration: $e');
    }
  }

  // Load pending driver registration from storage
  Future<void> loadPendingDriverRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('pending_driver_registration');
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
          'pending_driver_registration_documents',
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

        _pendingDriverRegistration = dataMap;
      }
    } catch (e) {
      debugPrint('Error loading pending driver registration: $e');
    }
  }

  // Remove the old parse method
  void _parseDocumentsString(String docsStr) {
    // No longer needed - using JSON now
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
      await DBHelper.instance.updateUser(_user!.id!, {
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
  Future<int?> registerWithEmailVerification({
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
      final passwordValidation = PasswordUtils.validatePassword(password);
      if (!passwordValidation.isValid) {
        throw Exception(passwordValidation.errors.join('. '));
      }

      // Check if email exists (only for unverified users)
      final existing = await DBHelper.instance.getUserByEmail(email);
      if (existing != null) {
        // Allow registration if the existing user is unverified
        final existingUser = User.fromMap(existing);
        if (existingUser.verificationStatus != 'unverified') {
          // If user exists and is verified, check if it's the same user trying to register again
          // This can happen during the OTP verification flow
          if (existingUser.email == email &&
              existingUser.verificationStatus == 'verified') {
            // Allow the same user to proceed with OTP verification
            _user = existingUser;
            await _saveUserToStorage(_user!);
            return existingUser.id;
          }
          throw Exception('Email already exists');
        }
        // If unverified, we'll update this user instead of creating a new one
      }

      final now = DateTime.now();
      final u = User(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: password, // Save as plain text
        phone: phone?.trim(),
        role: role,
        area: area,
        verificationStatus: 'unverified', // Start as unverified
      );

      // Check if we already have a user from the existing check
      final id =
          existing != null &&
              User.fromMap(existing).verificationStatus == 'unverified'
          ? existing['id'] as int
          : await DBHelper.instance.insertUser(u.toMap());

      _user = User.fromMap(u.toMap()..['id'] = id);

      // Save to secure storage
      await _saveUserToStorage(_user!);

      _isLoading = false;
      notifyListeners();

      return id;
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
          await DBHelper.instance.updateDoctorDocumentsStatus(
            _user!.id!,
            'approved',
          );
        }

        // Update driver documents status to approved
        if (_user != null && _user!.role == 'driver') {
          await DBHelper.instance.updateDriverDocumentsStatus(
            _user!.id!,
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
