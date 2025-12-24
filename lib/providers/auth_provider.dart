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

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  // Temporary data for social login role selection
  Map<String, dynamic>? _pendingSocialUser;

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

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

  Future<void> register({
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
      if (password.length < 6)
        throw Exception('Password must be at least 6 characters');

      // Check if email exists
      final existing = await DBHelper.instance.getUserByEmail(email);
      if (existing != null) {
        throw Exception('Email already exists');
      }

      final now = DateTime.now();
      final u = User(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: password, // In production, hash this password
        phone: phone?.trim(),
        role: role,
        area: area,
      );

      final id = await DBHelper.instance.insertUser(u.toMap());
      _user = User.fromMap(u.toMap()..['id'] = id);

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

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Validate input
      if (email.trim().isEmpty) throw Exception('Email is required');
      if (password.isEmpty) throw Exception('Password is required');

      final res = await DBHelper.instance.getUserByEmailAndPassword(
        email.trim().toLowerCase(),
        password,
      );

      if (res == null) {
        throw Exception('Invalid email or password');
      }

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
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (kIsWeb) {
        // Web implementation using Firebase Auth popup
        final firebase_auth.GoogleAuthProvider googleProvider =
            firebase_auth.GoogleAuthProvider();
        final firebase_auth.UserCredential userCredential = await firebase_auth
            .FirebaseAuth
            .instance
            .signInWithPopup(googleProvider);

        await _handleSocialLogin(
          firebaseUser: userCredential.user!,
          provider: 'google',
          providerId: userCredential.user!.uid,
        );
      } else {
        // Mobile implementation using Google Sign In
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
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
      );
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
        // New user: store pending data for role selection
        _pendingSocialUser = {
          'name': firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          'email': firebaseUser.email!,
          'provider': provider,
          'providerId': providerId,
        };
        _isLoading = false;
        // Do not notify listeners for pending state to avoid UI rebuild issues
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
        if (newPassword.length < 6) {
          throw Exception('New password must be at least 6 characters');
        }

        // Verify current password if provided
        if (currentPassword != null && currentPassword.isNotEmpty) {
          final isValidPassword = await DBHelper.instance
              .getUserByEmailAndPassword(_user!.email, currentPassword);
          if (isValidPassword == null) {
            throw Exception('Current password is incorrect');
          }
        }

        updates['password'] = newPassword; // In production, hash this
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

  // Get profile image bytes for web
  Future<Uint8List?> getProfileImageBytes() async {
    if (!kIsWeb || _user == null || _user!.profileImage == null) return null;

    if (_user!.profileImage!.startsWith('web_profile_image_')) {
      final bytes = await _loadWebProfileImage(_user!.id!.toString());
      return bytes != null ? Uint8List.fromList(bytes) : null;
    }

    return null;
  }
}







