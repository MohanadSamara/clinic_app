// lib/providers/firebase_auth_provider.dart
// Firebase Auth Provider - Uses new Auth and Firestore services
// All data linked to FirebaseAuth.currentUser.uid

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/firestore_crud_service.dart';
import '../models/user_model.dart';

class FirebaseAuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Services
  final AuthService _authService = AuthService.instance;
  final FirestoreCrudService _firestoreService = FirestoreCrudService.instance;

  // Getters
  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get userId => _authService.currentUserId;

  // ========== INITIALIZATION ==========

  /// Initialize auth state from Firebase Auth
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Listen to auth state changes
      _authService.authStateChanges.listen((firebaseUser) async {
        if (firebaseUser != null) {
          await _loadUserProfile(firebaseUser.uid);
        } else {
          _user = null;
          notifyListeners();
        }
      });

      // Check if user is already logged in
      if (_authService.currentUser != null) {
        final uid = _authService.currentUserId;
        if (uid != null) {
          await _loadUserProfile(uid);
        }
      }

      _isInitialized = true;
    } catch (e) {
      _error = 'Failed to initialize: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile(String uid) async {
    try {
      final result = await _firestoreService.read(
        userId: uid,
        collection: 'profile',
        docId: uid,
      );

      if (result.success && result.data != null) {
        _user = UserModel.fromMap(result.data!, uid);
      } else {
        _user = null;
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _user = null;
    }
    notifyListeners();
  }

  // ========== REGISTRATION ==========

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    required UserRole role,
    String? area,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userModel = await _authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
        area: area,
      );

      _user = userModel;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== LOGIN ==========

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userModel = await _authService.login(
        email: email,
        password: password,
      );

      _user = userModel;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== LOGOUT ==========

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _error = null;
    } catch (e) {
      _error = 'Logout failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== PASSWORD RESET ==========

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Password reset failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== PROFILE UPDATE ==========

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? area,
    String? profileImage,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Pass non-null values only
      if (name != null ||
          phone != null ||
          area != null ||
          profileImage != null) {
        await _authService.updateProfile(
          name: name,
          phone: phone,
          area: area,
          profileImage: profileImage,
        );
      }

      _user = _user!.copyWith(
        name: name ?? _user!.name,
        phone: phone ?? _user!.phone,
        area: area ?? _user!.area,
        profileImage: profileImage ?? _user!.profileImage,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Update failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== DATA OPERATIONS ==========

  Future<String?> addPet({
    required String name,
    required String species,
    String? breed,
    DateTime? dob,
    String? notes,
    String? photoUrl,
  }) async {
    if (_user == null) return null;

    final result = await _firestoreService.addPet(
      userId: _user!.id!,
      name: name,
      species: species,
      breed: breed,
      dob: dob,
      notes: notes,
      photoUrl: photoUrl,
    );

    if (!result.success) {
      _error = result.error;
    }
    return result.data;
  }

  Future<List<Map<String, dynamic>>> getPets() async {
    if (_user == null) return [];
    final result = await _firestoreService.getPets(userId: _user!.id!);
    return result.data ?? [];
  }

  Stream<List<Map<String, dynamic>>> streamPets() {
    if (_user == null) return Stream.value([]);
    return _firestoreService.streamPets(_user!.id!);
  }

  Future<String?> addAppointment({
    required String petId,
    required String serviceType,
    required DateTime scheduledAt,
    String? description,
    String? address,
    double? price,
    String? doctorId,
    String? driverId,
  }) async {
    if (_user == null) return null;

    final result = await _firestoreService.addAppointment(
      userId: _user!.id!,
      petId: petId,
      serviceType: serviceType,
      scheduledAt: scheduledAt,
      description: description,
      address: address,
      price: price,
      doctorId: doctorId,
      driverId: driverId,
    );

    if (!result.success) {
      _error = result.error;
    }
    return result.data;
  }

  Future<List<Map<String, dynamic>>> getAppointments({String? status}) async {
    if (_user == null) return [];
    final result = await _firestoreService.getAppointments(
      userId: _user!.id!,
      status: status,
    );
    return result.data ?? [];
  }

  Stream<List<Map<String, dynamic>>> streamAppointments() {
    if (_user == null) return Stream.value([]);
    return _firestoreService.streamAppointments(_user!.id!);
  }

  Future<String?> addMedicalRecord({
    required String petId,
    required String diagnosis,
    String? treatment,
    String? prescription,
    String? notes,
    DateTime? date,
  }) async {
    if (_user == null) return null;

    final result = await _firestoreService.addMedicalRecord(
      userId: _user!.id!,
      petId: petId,
      diagnosis: diagnosis,
      treatment: treatment,
      prescription: prescription,
      notes: notes,
      date: date,
    );

    if (!result.success) {
      _error = result.error;
    }
    return result.data;
  }

  Future<List<Map<String, dynamic>>> getMedicalRecords({String? petId}) async {
    if (_user == null) return [];
    final result = await _firestoreService.getMedicalRecords(
      userId: _user!.id!,
      petId: petId,
    );
    return result.data ?? [];
  }

  Stream<List<Map<String, dynamic>>> streamMedicalRecords() {
    if (_user == null) return Stream.value([]);
    return _firestoreService.streamMedicalRecords(_user!.id!);
  }

  // ========== HELPERS ==========

  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool hasRole(UserRole role) {
    return _user?.role == role;
  }

  bool get isDoctor => hasRole(UserRole.doctor);
  bool get isDriver => hasRole(UserRole.driver);
  bool get isOwner => hasRole(UserRole.owner);
  bool get isAdmin => hasRole(UserRole.admin);
}
