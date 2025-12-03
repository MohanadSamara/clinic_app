import 'package:flutter/foundation.dart';
import '../models/van.dart';
import '../models/user.dart';
import '../db/db_helper.dart';

class VanProvider with ChangeNotifier {
  List<Van> _vans = [];
  bool _isLoading = false;

  List<Van> get vans => _vans;
  bool get isLoading => _isLoading;

  Future<void> loadVans() async {
    try {
      _isLoading = true;
      // Don't call notifyListeners() here to avoid build-time notifications

      final dbHelper = DBHelper.instance;
      final vanData = await dbHelper.getAllVans();
      _vans = vanData.map((data) => Van.fromMap(data)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading vans: $e');
      _vans = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVan(Van van) async {
    try {
      final dbHelper = DBHelper.instance;
      final id = await dbHelper.insertVan(van.toMap());
      final newVan = van.copyWith(
        id: id,
        createdAt: DateTime.now().toIso8601String(),
      );
      _vans.add(newVan);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding van: $e');
      rethrow;
    }
  }

  Future<void> updateVan(int id, Van updatedVan) async {
    try {
      final dbHelper = DBHelper.instance;
      await dbHelper.updateVan(id, updatedVan.toMap());
      final index = _vans.indexWhere((van) => van.id == id);
      if (index != -1) {
        _vans[index] = updatedVan;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating van: $e');
      rethrow;
    }
  }

  Future<void> deleteVan(int id) async {
    try {
      final dbHelper = DBHelper.instance;
      await dbHelper.deleteVan(id);
      _vans.removeWhere((van) => van.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting van: $e');
      rethrow;
    }
  }

  Future<Van?> getVanById(int id) async {
    try {
      final dbHelper = DBHelper.instance;
      final vanData = await dbHelper.getVanById(id);
      return vanData != null ? Van.fromMap(vanData) : null;
    } catch (e) {
      debugPrint('Error getting van by id: $e');
      return null;
    }
  }

  Future<Van?> getVanByDriverId(int driverId) async {
    try {
      final dbHelper = DBHelper.instance;
      final vanData = await dbHelper.getVanByDriverId(driverId);
      return vanData != null ? Van.fromMap(vanData) : null;
    } catch (e) {
      debugPrint('Error getting van by driver id: $e');
      return null;
    }
  }

  Future<Van?> getVanByDoctorId(int doctorId) async {
    try {
      final dbHelper = DBHelper.instance;
      final vanData = await dbHelper.getVanByDoctorId(doctorId);
      return vanData != null ? Van.fromMap(vanData) : null;
    } catch (e) {
      debugPrint('Error getting van by doctor id: $e');
      return null;
    }
  }

  Future<void> assignVanToDriver(int vanId, int driverId) async {
    try {
      // Get driver user to check linked doctor
      final driverData = await DBHelper.instance.getUserById(driverId);
      if (driverData == null) {
        throw Exception('Driver not found');
      }
      final driver = User.fromMap(driverData);
      final linkedDoctorId = driver.linkedDoctorId;
      if (linkedDoctorId == null) {
        throw Exception('Driver must be linked to a doctor before assignment');
      }

      // Verify the linked doctor exists and is linked back
      final doctorData = await DBHelper.instance.getUserById(linkedDoctorId);
      if (doctorData == null) {
        throw Exception('Linked doctor not found');
      }
      final doctor = User.fromMap(doctorData);
      if (doctor.linkedDriverId != driverId) {
        throw Exception('Doctor is not properly linked to this driver');
      }

      final van = _vans.firstWhere((v) => v.id == vanId);
      final updatedVan = van.copyWith(
        assignedDriverId: driverId,
        assignedDoctorId: linkedDoctorId,
        status: 'assigned', // Both are assigned
      );
      await updateVan(vanId, updatedVan);
    } catch (e) {
      debugPrint('Error assigning van to driver: $e');
      rethrow;
    }
  }

  Future<void> assignVanToDoctor(int vanId, int doctorId) async {
    try {
      // Get doctor user to check linked driver
      final doctorData = await DBHelper.instance.getUserById(doctorId);
      if (doctorData == null) {
        throw Exception('Doctor not found');
      }
      final doctor = User.fromMap(doctorData);
      final linkedDriverId = doctor.linkedDriverId;
      if (linkedDriverId == null) {
        throw Exception('Doctor must be linked to a driver before assignment');
      }

      // Verify the linked driver exists and is linked back
      final driverData = await DBHelper.instance.getUserById(linkedDriverId);
      if (driverData == null) {
        throw Exception('Linked driver not found');
      }
      final driver = User.fromMap(driverData);
      if (driver.linkedDoctorId != doctorId) {
        throw Exception('Driver is not properly linked to this doctor');
      }

      final van = _vans.firstWhere((v) => v.id == vanId);
      final updatedVan = van.copyWith(
        assignedDoctorId: doctorId,
        assignedDriverId: linkedDriverId,
        status: 'assigned', // Both are assigned
      );
      await updateVan(vanId, updatedVan);
    } catch (e) {
      debugPrint('Error assigning van to doctor: $e');
      rethrow;
    }
  }

  Future<void> unassignVanFromDriver(int vanId) async {
    try {
      final van = _vans.firstWhere((v) => v.id == vanId);
      final updatedVan = van.copyWith(
        assignedDriverId: null,
        assignedDoctorId: null, // Unassign both since they are paired
        status: 'available',
      );
      await updateVan(vanId, updatedVan);
    } catch (e) {
      debugPrint('Error unassigning van from driver: $e');
      rethrow;
    }
  }

  Future<void> unassignVanFromDoctor(int vanId) async {
    try {
      final van = _vans.firstWhere((v) => v.id == vanId);
      final updatedVan = van.copyWith(
        assignedDoctorId: null,
        assignedDriverId: null, // Unassign both since they are paired
        status: 'available',
      );
      await updateVan(vanId, updatedVan);
    } catch (e) {
      debugPrint('Error unassigning van from doctor: $e');
      rethrow;
    }
  }

  Future<void> assignVanToDoctorAndDriver(
    int vanId,
    int doctorId,
    int driverId,
  ) async {
    try {
      final van = _vans.firstWhere((v) => v.id == vanId);
      final updatedVan = van.copyWith(
        assignedDoctorId: doctorId,
        assignedDriverId: driverId,
        status: 'assigned',
      );
      await updateVan(vanId, updatedVan);
    } catch (e) {
      debugPrint('Error assigning van to doctor and driver: $e');
      rethrow;
    }
  }

  Future<void> unassignVanFromDoctorAndDriver(int vanId) async {
    try {
      final van = _vans.firstWhere((v) => v.id == vanId);
      final updatedVan = van.copyWith(
        assignedDoctorId: null,
        assignedDriverId: null,
        status: 'available',
      );
      await updateVan(vanId, updatedVan);
    } catch (e) {
      debugPrint('Error unassigning van from doctor and driver: $e');
      rethrow;
    }
  }

  List<Van> getAvailableVans() {
    return _vans.where((van) => van.isAvailable).toList();
  }

  List<Van> getAssignedVans() {
    return _vans.where((van) => van.isAssigned).toList();
  }

  List<Van> getVansByStatus(String status) {
    return _vans.where((van) => van.status == status).toList();
  }
}
