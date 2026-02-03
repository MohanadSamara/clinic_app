import 'package:flutter/foundation.dart';
import '../services/supabase_complete_service.dart';
import '../models/van.dart';

class VanProvider with ChangeNotifier {
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;
  List<Van> _vans = [];
  bool _isLoading = false;
  String? _error;

  List<Van> get vans => _vans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// UUID validation regex - matches standard UUID format
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Validates that a string is a valid UUID format, throws if invalid
  void _validateUUID(String id, String fieldName) {
    if (id.isEmpty || !_uuidRegex.hasMatch(id)) {
      throw ArgumentError('$fieldName must be a valid UUID, got: $id');
    }
  }

  Future<void> loadVans() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      final data = await _supabaseService.getAllVans();
      _vans = data.map((e) => Van.fromSupabase(e)).toList();
    } catch (e) {
      debugPrint('Error loading vans: $e');
      _error = 'Error loading vans: $e';
      _vans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVan(Van van) async {
    try {
      _isLoading = true;
      notifyListeners();
      final vanId = await _supabaseService.insertVan(
        van.toSupabase()..remove('id'),
      );
      final newVan = van.copyWith(
        id: vanId,
        createdAt: DateTime.now().toIso8601String(),
      );
      _vans.add(newVan);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding van: $e');
      _error = 'Error adding van: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVan(String id, Van updatedVan) async {
    try {
      await _supabaseService.updateVan(
        id,
        updatedVan.toSupabase()..remove('id'),
      );
      final index = _vans.indexWhere((v) => v.id == id);
      if (index != -1) {
        _vans[index] = updatedVan;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating van: $e');
      _error = 'Error updating van: $e';
      rethrow;
    }
  }

  Future<void> deleteVan(String id) async {
    try {
      await _supabaseService.deleteVan(id);
      _vans.removeWhere((v) => v.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting van: $e');
      _error = 'Error deleting van: $e';
      rethrow;
    }
  }

  Van? getVanById(String id) {
    try {
      return _vans.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Van?> getVanByDriverId(String driverId) async {
    try {
      final data = await _supabaseService.getVanByDriverId(driverId);
      if (data == null) return null;
      return Van.fromSupabase(data);
    } catch (e) {
      debugPrint('Error getting van by driver id: $e');
      return null;
    }
  }

  Future<Van?> getVanByDoctorId(String doctorId) async {
    try {
      final data = await _supabaseService.getVanByDoctorId(doctorId);
      if (data == null) return null;
      return Van.fromSupabase(data);
    } catch (e) {
      debugPrint('Error getting van by doctor id: $e');
      return null;
    }
  }

  List<Van> getAvailableVans() => _vans.where((v) => v.isAvailable).toList();
  List<Van> getAssignedVans() => _vans.where((v) => v.isAssigned).toList();
  List<Van> getVansByStatus(String status) =>
      _vans.where((v) => v.status == status).toList();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> assignVanToDriver(String vanId, String driverId) async {
    _validateUUID(vanId, 'vanId');
    _validateUUID(driverId, 'driverId');
    await _supabaseService.updateVan(vanId, {
      'assigned_driver_id': driverId,
      'status': 'assigned',
    });
    final index = _vans.indexWhere((v) => v.id == vanId);
    if (index != -1) {
      _vans[index] = _vans[index].copyWith(
        assignedDriverId: driverId,
        status: 'assigned',
      );
      notifyListeners();
    }
  }

  Future<void> assignVanToDoctor(String vanId, String doctorId) async {
    _validateUUID(vanId, 'vanId');
    _validateUUID(doctorId, 'doctorId');
    await _supabaseService.updateVan(vanId, {
      'assigned_doctor_id': doctorId,
      'status': 'assigned',
    });
    final index = _vans.indexWhere((v) => v.id == vanId);
    if (index != -1) {
      _vans[index] = _vans[index].copyWith(
        assignedDoctorId: doctorId,
        status: 'assigned',
      );
      notifyListeners();
    }
  }

  /// Assigns a van to both a doctor and driver using their user IDs (UUIDs)
  /// All parameters MUST be valid UUIDs - validation is enforced
  Future<void> assignVanToDoctorAndDriver({
    required String vanId,
    required String driverUserId,
    required String doctorUserId,
  }) async {
    _validateUUID(vanId, 'vanId');
    _validateUUID(driverUserId, 'driverUserId');
    _validateUUID(doctorUserId, 'doctorUserId');
    await _supabaseService.updateVan(vanId, {
      'assigned_driver_id': driverUserId,
      'assigned_doctor_id': doctorUserId,
      'status': 'assigned',
    });
    final index = _vans.indexWhere((v) => v.id == vanId);
    if (index != -1) {
      _vans[index] = _vans[index].copyWith(
        assignedDriverId: driverUserId,
        assignedDoctorId: doctorUserId,
        status: 'assigned',
      );
      notifyListeners();
    }
  }

  Future<void> unassignVanFromDriver(String vanId) async {
    _validateUUID(vanId, 'vanId');
    await _supabaseService.updateVan(vanId, {
      'assigned_driver_id': null,
      'assigned_doctor_id': null,
      'status': 'available',
    });
    final index = _vans.indexWhere((v) => v.id == vanId);
    if (index != -1) {
      _vans[index] = _vans[index].copyWith(
        assignedDriverId: null,
        assignedDoctorId: null,
        status: 'available',
      );
      notifyListeners();
    }
  }

  Future<void> unassignVanFromDoctor(String vanId) async {
    _validateUUID(vanId, 'vanId');
    await _supabaseService.updateVan(vanId, {
      'assigned_doctor_id': null,
      'assigned_driver_id': null,
      'status': 'available',
    });
    final index = _vans.indexWhere((v) => v.id == vanId);
    if (index != -1) {
      _vans[index] = _vans[index].copyWith(
        assignedDoctorId: null,
        assignedDriverId: null,
        status: 'available',
      );
      notifyListeners();
    }
  }

  Future<void> unassignVanFromDoctorAndDriver(String vanId) async {
    _validateUUID(vanId, 'vanId');
    await _supabaseService.updateVan(vanId, {
      'assigned_doctor_id': null,
      'assigned_driver_id': null,
      'status': 'available',
    });
    final index = _vans.indexWhere((v) => v.id == vanId);
    if (index != -1) {
      _vans[index] = _vans[index].copyWith(
        assignedDoctorId: null,
        assignedDriverId: null,
        status: 'available',
      );
      notifyListeners();
    }
  }
}

/// Example of WRONG usage:
/// ```dart
/// final van = Van(...);
/// provider.assignVanToDoctorAndDriver(vanId: van.id.hashCode, ...); // ❌ WRONG - hashCode is int
/// provider.assignVanToDoctorAndDriver(vanId: van.id.toString(), ...); // ❌ WRONG - still might be wrong
/// ```
///
/// Example of CORRECT usage:
/// ```dart
/// final van = Van(...); // van.id is already a String UUID
/// provider.assignVanToDoctorAndDriver(vanId: van.id, driverUserId: driver.id, doctorUserId: doctor.id);
/// // ✅ CORRECT - all IDs are UUID strings
