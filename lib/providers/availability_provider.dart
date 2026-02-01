import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/van.dart';
import '../services/supabase_complete_service.dart';

class AvailabilityProvider extends ChangeNotifier {
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  List<User> _onlineUsers = [];
  List<Van> _availableVans = [];
  Timer? _statusUpdateTimer;

  List<User> get onlineUsers => _onlineUsers;
  List<Van> get availableVans => _availableVans;

  // Get users by availability status
  List<User> getUsersByStatus(String status) {
    return _onlineUsers
        .where((user) => user.availabilityStatus == status)
        .toList();
  }

  // Get available doctors
  List<User> get availableDoctors {
    return _onlineUsers
        .where(
          (user) =>
              user.role == 'doctor' &&
              user.availabilityStatus == 'online' &&
              user.linkedDriverId != null,
        )
        .toList();
  }

  // Get available drivers
  List<User> get availableDrivers {
    return _onlineUsers
        .where(
          (user) =>
              user.role == 'driver' &&
              user.availabilityStatus == 'online' &&
              user.linkedDoctorId != null,
        )
        .toList();
  }

  // Get available doctor-driver pairs
  List<Map<String, User>> get availablePairs {
    List<Map<String, User>> pairs = [];

    for (var doctor in availableDoctors) {
      var driver = availableDrivers.firstWhere(
        (d) => d.id == doctor.linkedDriverId,
        orElse: () => User(id: '-1', name: '', email: '', password: ''),
      );

      if (driver.id != '-1') {
        pairs.add({'doctor': doctor, 'driver': driver});
      }
    }

    return pairs;
  }

  Future<void> loadAvailabilityData() async {
    try {
      // Load online users
      final userData = await _supabaseService.getAllUsers();
      _onlineUsers = userData
          .map((data) => User.fromMap(data))
          .where((user) => user.availabilityStatus != 'offline')
          .toList();

      // Load available vans
      final vanData = await _supabaseService.getAllVans();
      _availableVans = vanData
          .map((data) => Van.fromMap(data))
          .where((van) => van.status == 'available' || van.status == 'assigned')
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading availability data: $e');
    }
  }

  Future<void> updateUserAvailability(String userId, String status) async {
    try {
      final userData = await _supabaseService.getUserById(userId);
      if (userData != null) {
        final user = User.fromMap(userData);
        final updatedUser = user.copyWith(
          availabilityStatus: status,
          lastSeen: DateTime.now().toIso8601String(),
        );

        await _supabaseService.updateUser(userId, updatedUser.toMap());

        // Update local list
        final index = _onlineUsers.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _onlineUsers[index] = updatedUser;
        } else if (status != 'offline') {
          _onlineUsers.add(updatedUser);
        } else {
          _onlineUsers.removeWhere((u) => u.id == userId);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating user availability: $e');
    }
  }

  Future<void> updateVanAvailability(String vanId, String status) async {
    try {
      final vanData = await _supabaseService.getVanById(vanId);
      if (vanData != null) {
        final van = Van.fromMap(vanData);
        final updatedVan = van.copyWith(status: status);

        await _supabaseService.updateVan(vanId, updatedVan.toMap());

        // Update local list
        final index = _availableVans.indexWhere((v) => v.id == vanId);
        if (index != -1) {
          _availableVans[index] = updatedVan;
        } else if (status == 'available' || status == 'assigned') {
          _availableVans.add(updatedVan);
        } else {
          _availableVans.removeWhere((v) => v.id == vanId);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating van availability: $e');
    }
  }

  // Start periodic status updates (simulate real-time)
  void startStatusUpdates() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      loadAvailabilityData();
    });
  }

  // Stop status updates
  void stopStatusUpdates() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = null;
  }

  @override
  void dispose() {
    stopStatusUpdates();
    super.dispose();
  }
}
