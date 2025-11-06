// lib/providers/service_assignment_provider.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/van.dart';
import '../models/doctor_service_assignment.dart';
import '../models/driver_doctor_assignment.dart';
import '../models/service_session.dart';
import '../models/service.dart';
import '../models/user.dart';

class ServiceAssignmentProvider extends ChangeNotifier {
  List<Van> _vans = [];
  List<DoctorServiceAssignment> _doctorAssignments = [];
  List<DriverDoctorAssignment> _driverAssignments = [];
  List<ServiceSession> _serviceSessions = [];
  bool _isLoading = false;

  List<Van> get vans => _vans;
  List<DoctorServiceAssignment> get doctorAssignments => _doctorAssignments;
  List<DriverDoctorAssignment> get driverAssignments => _driverAssignments;
  List<ServiceSession> get serviceSessions => _serviceSessions;
  bool get isLoading => _isLoading;

  Future<void> loadVans() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DBHelper.instance.getVans();
      _vans = data.map((item) => Van.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error loading vans: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDoctors() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DBHelper.instance.getDoctors();
      // Convert to DoctorServiceAssignment format for compatibility
      _doctorAssignments = data
          .map(
            (item) => DoctorServiceAssignment(
              id: item['id'],
              doctorId: item['user_id'],
              serviceId: item['assigned_service_id'],
              isActive: item['is_available'] == 1,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading doctors: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDriverAssignments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DBHelper.instance.getDriverDoctorAssignments();
      _driverAssignments = data
          .map((item) => DriverDoctorAssignment.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error loading driver assignments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadServiceSessions({
    int? userId,
    String? userRole,
    String? sessionDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DBHelper.instance.getServiceSessions(
        userId: userId,
        userRole: userRole,
        sessionDate: sessionDate,
      );
      _serviceSessions = data
          .map((item) => ServiceSession.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error loading service sessions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addVan(Van van) async {
    try {
      final id = await DBHelper.instance.insertVan(van.toMap());
      final newVan = van.copyWith(id: id);
      _vans.add(newVan);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding van: $e');
      return false;
    }
  }

  Future<bool> addDoctorAssignment(DoctorServiceAssignment assignment) async {
    try {
      final doctorData = {
        'user_id': assignment.doctorId,
        'assigned_service_id': assignment.serviceId,
        'is_available': assignment.isActive ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      };
      final id = await DBHelper.instance.insertDoctor(doctorData);
      final newAssignment = assignment.copyWith(id: id);
      _doctorAssignments.add(newAssignment);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding doctor assignment: $e');
      return false;
    }
  }

  Future<bool> addDriverAssignment(DriverDoctorAssignment assignment) async {
    try {
      final id = await DBHelper.instance.insertDriverDoctorAssignment(
        assignment.toMap(),
      );
      final newAssignment = assignment.copyWith(id: id);
      _driverAssignments.add(newAssignment);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding driver assignment: $e');
      return false;
    }
  }

  Future<bool> createServiceSession(ServiceSession session) async {
    try {
      final id = await DBHelper.instance.insertServiceSession(session.toMap());
      final newSession = session.copyWith(id: id);
      _serviceSessions.add(newSession);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating service session: $e');
      return false;
    }
  }

  Future<bool> updateServiceSession(ServiceSession session) async {
    if (session.id == null) return false;

    try {
      await DBHelper.instance.updateServiceSession(
        session.id!,
        session.toMap(),
      );
      final index = _serviceSessions.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        _serviceSessions[index] = session;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating service session: $e');
      return false;
    }
  }

  // Get van for a specific driver
  Van? getVanByDriverId(int driverId) {
    return _vans.firstWhere((van) => van.driverId == driverId);
  }

  // Get assigned service for a doctor
  Service? getAssignedServiceForDoctor(int doctorId) {
    final assignment = _doctorAssignments.firstWhere(
      (a) => a.doctorId == doctorId,
    );
    // Note: This would need access to ServiceProvider to get the service details
    // For now, return null - implement when integrating with ServiceProvider
    return null;
  }

  // Get assigned driver for a doctor
  int? getAssignedDriverForDoctor(int doctorId) {
    final assignment = _driverAssignments.firstWhere(
      (a) => a.doctorId == doctorId,
    );
    return assignment.driverId;
  }

  // Get assigned doctor for a driver
  int? getAssignedDoctorForDriver(int driverId) {
    final assignment = _driverAssignments.firstWhere(
      (a) => a.driverId == driverId,
    );
    return assignment.doctorId;
  }

  // Get available doctors for a specific service
  Future<List<User>> getAvailableDoctorsForService(
    int serviceId,
    String sessionDate,
  ) async {
    try {
      debugPrint('Loading doctor assignments...');
      // Ensure doctor assignments are loaded
      if (_doctorAssignments.isEmpty) {
        await loadDoctors();
      }

      // Get doctors assigned to this service
      final doctorIds = _doctorAssignments
          .where((a) => a.serviceId == serviceId && a.isActive)
          .map((a) => a.doctorId)
          .toList();

      if (doctorIds.isEmpty) {
        debugPrint('No doctors assigned to service $serviceId');
        debugPrint(
          'Available assignments: ${_doctorAssignments.map((a) => 'Doctor ${a.doctorId} -> Service ${a.serviceId} (Active: ${a.isActive})').toList()}',
        );
        return [];
      }

      debugPrint(
        'Found ${doctorIds.length} doctors assigned to service $serviceId: $doctorIds',
      );

      // Get user details for assigned doctors
      final doctors = <User>[];
      for (final id in doctorIds) {
        final userData = await DBHelper.instance.getUserById(id);
        if (userData != null) {
          doctors.add(User.fromMap(userData));
          debugPrint('Added doctor: ${userData['name']} (ID: $id)');
        } else {
          debugPrint('Doctor with ID $id not found in users table');
        }
      }

      debugPrint('Returning ${doctors.length} doctors for service $serviceId');
      return doctors;
    } catch (e) {
      debugPrint('Error getting available doctors: $e');
      return [];
    }
  }

  // Check if doctor and driver have matching service selections for a session
  bool hasMatchingServiceSelection(
    int doctorId,
    int driverId,
    int serviceId,
    String sessionDate,
  ) {
    final doctorSession = _serviceSessions.firstWhere(
      (s) =>
          s.userId == doctorId &&
          s.userRole == 'doctor' &&
          s.sessionDate == sessionDate,
    );
    final driverSession = _serviceSessions.firstWhere(
      (s) =>
          s.userId == driverId &&
          s.userRole == 'driver' &&
          s.sessionDate == sessionDate,
    );

    return doctorSession.selectedServiceId == serviceId &&
        driverSession.selectedServiceId == serviceId;
  }
}
