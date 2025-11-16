// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/db_helper.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

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

    // Clear shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);

    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? password,
  }) async {
    if (_user == null) throw Exception('Not authenticated');

    try {
      final updates = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        updates['name'] = name.trim();
      }
      if (phone != null) {
        updates['phone'] = phone.trim();
      }
      if (password != null && password.length >= 6) {
        updates['password'] = password; // In production, hash this
      }

      if (updates.isNotEmpty) {
        await DBHelper.instance.updateUser(_user!.id!, updates);
        final updatedUser = _user!.copyWith(
          name: updates['name'] ?? _user!.name,
          phone: updates['phone'] ?? _user!.phone,
          password: updates['password'] ?? _user!.password,
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
}
