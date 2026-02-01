// lib/providers/van_provider.dart
// Van Provider using Supabase as the single source of truth
// All data synced globally across devices
// Migrated to Supabase database (PostgreSQL) - 2026-01-31

import 'package:flutter/foundation.dart';
import '../services/supabase_complete_service.dart';
import '../models/van.dart';

/// VanProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: vans
///
/// All database operations now use Supabase client exclusively.
/// Firestore has been completely removed.
class VanProvider with ChangeNotifier {
  List<Van> _vans = [];
  bool _isLoading = false;
  String? _error;

  // Supabase service instance for database operations
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  List<Van> get vans => _vans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========== LOAD DATA ==========

  Future<void> loadVans() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final vansData = await _supabaseService.getAllVans();

      _vans = vansData.map((data) {
        // Convert String UUID to int for backward compatibility
        data['id'] = (data['id'] as String).hashCode;
        return Van.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading vans: $e');
      _error = 'Error loading vans: $e';
      _vans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== ADD VAN ==========

  Future<void> addVan(Van van) async {
    try {
      _isLoading = true;
      notifyListeners();

      final vanData = {
        'name': van.name,
        'license_plate': van.licensePlate,
        'model': van.model,
        'capacity': van.capacity,
        'status': van.status,
        'description': van.description,
        'area': van.area,
        'assigned_driver_id': van.assignedDriverId?.toString(),
        'assigned_doctor_id': van.assignedDoctorId?.toString(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final vanId = await _supabaseService.insertVan(vanData);

      // Convert String UUID to int for backward compatibility
      final vanIdInt = vanId.hashCode;

      final newVan = van.copyWith(
        id: vanIdInt,
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

  // ========== UPDATE VAN ==========

  Future<void> updateVan(dynamic id, Van updatedVan) async {
    try {
      final idInt = id is int ? id : id.hashCode;
      final index = _vans.indexWhere((van) => van.id == idInt);
      if (index == -1) return;

      final vanIdStr = id.toString();

      await _supabaseService.updateVan(vanIdStr, {
        'name': updatedVan.name,
        'license_plate': updatedVan.licensePlate,
        'model': updatedVan.model,
        'capacity': updatedVan.capacity,
        'status': updatedVan.status,
        'description': updatedVan.description,
        'area': updatedVan.area,
        'assigned_driver_id': updatedVan.assignedDriverId?.toString(),
        'assigned_doctor_id': updatedVan.assignedDoctorId?.toString(),
      });

      _vans[index] = updatedVan.copyWith(id: idInt);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating van: $e');
      _error = 'Error updating van: $e';
      rethrow;
    }
  }

  // ========== DELETE VAN ==========

  Future<void> deleteVan(dynamic id) async {
    try {
      final idInt = id is int ? id : id.hashCode;
      final index = _vans.indexWhere((van) => van.id == idInt);
      if (index == -1) return;

      final vanIdStr = id.toString();

      await _supabaseService.deleteVan(vanIdStr);

      _vans.removeAt(index);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting van: $e');
      _error = 'Error deleting van: $e';
      rethrow;
    }
  }

  // ========== GET VAN BY ID ==========

  Van? getVanById(dynamic id) {
    final idInt = id is int ? id : id.hashCode;
    try {
      return _vans.firstWhere((van) => van.id == idInt);
    } catch (e) {
      return null;
    }
  }

  // ========== GET VAN BY DRIVER ID ==========

  Future<Van?> getVanByDriverId(dynamic driverId) async {
    try {
      final driverIdStr = driverId?.toString() ?? '';

      final vanData = await _supabaseService.getVanByDriverId(driverIdStr);

      if (vanData == null) return null;

      // Convert String UUID to int for backward compatibility
      vanData['id'] = (vanData['id'] as String).hashCode;
      return Van.fromMap(vanData);
    } catch (e) {
      debugPrint('Error getting van by driver id: $e');
      return null;
    }
  }

  // ========== GET VAN BY DOCTOR ID ==========

  Future<Van?> getVanByDoctorId(dynamic doctorId) async {
    try {
      final doctorIdStr = doctorId?.toString() ?? '';

      final vanData = await _supabaseService.getVanByDoctorId(doctorIdStr);

      if (vanData == null) return null;

      // Convert String UUID to int for backward compatibility
      vanData['id'] = (vanData['id'] as String).hashCode;
      return Van.fromMap(vanData);
    } catch (e) {
      debugPrint('Error getting van by doctor id: $e');
      return null;
    }
  }

  // ========== ASSIGN VAN ==========

  Future<void> assignVanToDriver(dynamic vanId, dynamic driverId) async {
    try {
      final vanIdInt = vanId is int ? vanId : vanId.hashCode;
      final index = _vans.indexWhere((van) => van.id == vanIdInt);
      if (index == -1) return;

      final vanIdStr = vanId.toString();
      final driverIdStr = driverId?.toString() ?? '';

      await _supabaseService.updateVan(vanIdStr, {
        'assigned_driver_id': driverIdStr,
        'status': 'assigned',
      });

      final updatedVan = _vans[index].copyWith(
        assignedDriverId: driverId is int ? driverId : driverId.hashCode,
        status: 'assigned',
      );

      _vans[index] = updatedVan;
      notifyListeners();
    } catch (e) {
      debugPrint('Error assigning van to driver: $e');
      _error = 'Error assigning van: $e';
      rethrow;
    }
  }

  Future<void> assignVanToDoctor(dynamic vanId, dynamic doctorId) async {
    try {
      final vanIdInt = vanId is int ? vanId : vanId.hashCode;
      final index = _vans.indexWhere((van) => van.id == vanIdInt);
      if (index == -1) return;

      final vanIdStr = vanId.toString();
      final doctorIdStr = doctorId?.toString() ?? '';

      await _supabaseService.updateVan(vanIdStr, {
        'assigned_doctor_id': doctorIdStr,
        'status': 'assigned',
      });

      final updatedVan = _vans[index].copyWith(
        assignedDoctorId: doctorId is int ? doctorId : doctorId.hashCode,
        status: 'assigned',
      );

      _vans[index] = updatedVan;
      notifyListeners();
    } catch (e) {
      debugPrint('Error assigning van to doctor: $e');
      _error = 'Error assigning van: $e';
      rethrow;
    }
  }

  Future<void> assignVanToDoctorAndDriver(
    dynamic vanId,
    dynamic doctorId,
    dynamic driverId,
  ) async {
    try {
      final vanIdInt = vanId is int ? vanId : vanId.hashCode;
      final index = _vans.indexWhere((van) => van.id == vanIdInt);
      if (index == -1) return;

      final vanIdStr = vanId.toString();
      final doctorIdStr = doctorId?.toString() ?? '';
      final driverIdStr = driverId?.toString() ?? '';

      await _supabaseService.updateVan(vanIdStr, {
        'assigned_doctor_id': doctorIdStr,
        'assigned_driver_id': driverIdStr,
        'status': 'assigned',
      });

      final updatedVan = _vans[index].copyWith(
        assignedDoctorId: doctorId is int ? doctorId : doctorId.hashCode,
        assignedDriverId: driverId is int ? driverId : driverId.hashCode,
        status: 'assigned',
      );

      _vans[index] = updatedVan;
      notifyListeners();
    } catch (e) {
      debugPrint('Error assigning van to doctor and driver: $e');
      _error = 'Error assigning van: $e';
      rethrow;
    }
  }

  // ========== UNASSIGN VAN ==========

  Future<void> unassignVanFromDriver(dynamic vanId) async {
    try {
      final vanIdInt = vanId is int ? vanId : vanId.hashCode;
      final index = _vans.indexWhere((van) => van.id == vanIdInt);
      if (index == -1) return;

      final vanIdStr = vanId.toString();

      await _supabaseService.updateVan(vanIdStr, {
        'assigned_driver_id': null,
        'assigned_doctor_id': null,
        'status': 'available',
      });

      final updatedVan = _vans[index].copyWith(
        assignedDriverId: null,
        assignedDoctorId: null,
        status: 'available',
      );

      _vans[index] = updatedVan;
      notifyListeners();
    } catch (e) {
      debugPrint('Error unassigning van from driver: $e');
      _error = 'Error unassigning van: $e';
      rethrow;
    }
  }

  Future<void> unassignVanFromDoctor(dynamic vanId) async {
    try {
      final vanIdInt = vanId is int ? vanId : vanId.hashCode;
      final index = _vans.indexWhere((van) => van.id == vanIdInt);
      if (index == -1) return;

      final vanIdStr = vanId.toString();

      await _supabaseService.updateVan(vanIdStr, {
        'assigned_doctor_id': null,
        'assigned_driver_id': null,
        'status': 'available',
      });

      final updatedVan = _vans[index].copyWith(
        assignedDoctorId: null,
        assignedDriverId: null,
        status: 'available',
      );

      _vans[index] = updatedVan;
      notifyListeners();
    } catch (e) {
      debugPrint('Error unassigning van from doctor: $e');
      _error = 'Error unassigning van: $e';
      rethrow;
    }
  }

  Future<void> unassignVanFromDoctorAndDriver(dynamic vanId) async {
    try {
      final vanIdInt = vanId is int ? vanId : vanId.hashCode;
      final index = _vans.indexWhere((van) => van.id == vanIdInt);
      if (index == -1) return;

      final vanIdStr = vanId.toString();

      await _supabaseService.updateVan(vanIdStr, {
        'assigned_doctor_id': null,
        'assigned_driver_id': null,
        'status': 'available',
      });

      final updatedVan = _vans[index].copyWith(
        assignedDoctorId: null,
        assignedDriverId: null,
        status: 'available',
      );

      _vans[index] = updatedVan;
      notifyListeners();
    } catch (e) {
      debugPrint('Error unassigning van: $e');
      _error = 'Error unassigning van: $e';
      rethrow;
    }
  }

  // ========== FILTERS ==========

  List<Van> getAvailableVans() {
    return _vans.where((van) => van.isAvailable).toList();
  }

  List<Van> getAssignedVans() {
    return _vans.where((van) => van.isAssigned).toList();
  }

  List<Van> getVansByStatus(String status) {
    return _vans.where((van) => van.status == status).toList();
  }

  // ========== CLEAR ==========

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
