// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'owner',
  }) async {
    _isLoading = true;
    notifyListeners();
    final existing = await DBHelper.instance.getUserByEmail(email);
    if (existing != null) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Email already exists');
    }
    final u = User(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
    );
    final id = await DBHelper.instance.insertUser(u.toMap());
    _user = User.fromMap(u.toMap()..['id'] = id);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();
    final res = await DBHelper.instance.getUserByEmailAndPassword(
      email,
      password,
    );
    if (res == null) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Invalid credentials');
    }
    _user = User.fromMap(res);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }
}
