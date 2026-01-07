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

  // Initialize auth state from shared preferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      if (userData != null) {
        final userMap = Map<String, dynamic>.from(
          userData.split(',').fold<Map<String, dynamic>>({}, (map, pair) {
            final parts = pair.split(':');
            if (parts.length == 2) {
              final key = parts[0];
              final value = parts[1];
              if (key == 'id') {
                map[key] = int.tryParse(value);
              } else {
                map[key] = value;
              }
            }
            return map;
          }),
        );
        _user = User.fromMap(userMap);
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
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
      final hashedPassword = PasswordUtils.hashPassword(password);
      final u = User(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: hashedPassword,
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
        throw Exception('Invalid email or password');
      }

      // Verify password against hash
      final storedPassword = userData['password'] as String;
      final isPasswordValid = PasswordUtils.verifyPassword(
        password,
        storedPassword,
      );
      if (!isPasswordValid) {
        throw Exception('Invalid email or password');
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
          final isValidPassword = PasswordUtils.verifyPassword(
            currentPassword,
            _user!.password,
          );
          if (!isValidPassword) {
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
    final userData = {
      'id': user.id.toString(),
      'name': user.name,
      'email': user.email,
      'role': user.role,
      'phone': user.phone ?? '',
    };

    final dataString = userData.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, dataString);
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

    // Hash the password before storing
    final hashedPassword = PasswordUtils.hashPassword(password);

    // Store simple data as string
    final simpleData = {
      'name': name,
      'email': email.toLowerCase(),
      'password': hashedPassword,
      'phone': phone ?? '',
      'area': area,
      'created_at': DateTime.now().toIso8601String(),
    };

    final simpleDataString = simpleData.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');

    // Store documents as JSON (but exclude file bytes for storage)
    final documentsForStorage = <String, dynamic>{};
    for (final entry in documents.entries) {
      final docData = Map<String, dynamic>.from(entry.value);
      // Remove file bytes - they'll be lost on restart
      docData.remove('file_data');
      documentsForStorage[entry.key] = docData;
    }

    await prefs.setString(_pendingDoctorKey, simpleDataString);
    await prefs.setString(
      '${_pendingDoctorKey}_documents',
      jsonEncode(documentsForStorage),
    );

    _pendingDoctorRegistration = {...simpleData, 'documents': documents};
  }

  // Get pending doctor registration data
  Map<String, dynamic>? get pendingDoctorRegistration =>
      _pendingDoctorRegistration;

  // Check if there's pending doctor registration
  bool get hasPendingDoctorRegistration => _pendingDoctorRegistration != null;

  // Complete doctor registration (called after verification is done)
  Future<int?> completeDoctorRegistration() async {
    if (_pendingDoctorRegistration == null) {
      throw Exception('No pending doctor registration');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final data = _pendingDoctorRegistration!;
      final email = data['email'] as String;

      // Check if email already exists
      final existing = await DBHelper.instance.getUserByEmail(email);
      if (existing != null) {
        throw Exception('Email already exists');
      }

      final u = User(
        name: data['name'] as String,
        email: email,
        password: data['password'] as String,
        phone: (data['phone'] as String?)?.isEmpty == true
            ? null
            : data['phone'] as String?,
        role: 'doctor',
        area: data['area'] as String?,
        verificationStatus: 'verified', // Auto-verify for simplicity
      );

      final id = await DBHelper.instance.insertUser(u.toMap());
      _user = User.fromMap(u.toMap()..['id'] = id);

      // Save documents
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
            'status': 'approved', // Auto-approve for simplicity
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

  // Clear pending doctor registration
  Future<void> clearPendingDoctorRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingDoctorKey);
    await prefs.remove('${_pendingDoctorKey}_documents');
    _pendingDoctorRegistration = null;
  }

  // Load pending doctor registration from storage
  Future<void> loadPendingDoctorRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_pendingDoctorKey);
      if (dataString != null) {
        final dataMap = <String, dynamic>{};
        for (final pair in dataString.split(',')) {
          final parts = pair.split(':');
          if (parts.length >= 2) {
            final key = parts[0];
            final value = parts.sublist(1).join(':');
            dataMap[key] = value;
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

      // Check if email exists
      final existing = await DBHelper.instance.getUserByEmail(email);
      if (existing != null) {
        throw Exception('Email already exists');
      }

      final now = DateTime.now();
      final hashedPassword = PasswordUtils.hashPassword(password);
      final u = User(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: hashedPassword,
        phone: phone?.trim(),
        role: role,
        area: area,
        verificationStatus: 'unverified', // Start as unverified
      );

      final id = await DBHelper.instance.insertUser(u.toMap());
      _user = User.fromMap(u.toMap()..['id'] = id);

      // Send verification email
      final emailSent = await sendEmailVerificationCode(email);
      if (!emailSent) {
        // If email fails, still create user but mark as unverified
        debugPrint('Warning: Failed to send verification email');
      }

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
        // Update user verification status
        await updateVerificationStatus('verified');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error completing email verification: $e');
      return false;
    }
  }
}
