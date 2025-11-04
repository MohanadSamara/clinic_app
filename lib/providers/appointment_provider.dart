// lib/providers/appointment_provider.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/appointment.dart';
import '../models/service.dart';

class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _appointments = [];
  List<Service> _services = [];
  bool _isLoading = false;

  List<Appointment> get appointments => _appointments;
  List<Service> get services => _services;
  bool get isLoading => _isLoading;

  Future<void> loadServices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DBHelper.instance.getServices();
      _services = data.map((item) => Service.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error loading services: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAppointments({int? ownerId, int? doctorId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DBHelper.instance.getAppointments(
        ownerId: ownerId,
        doctorId: doctorId,
      );
      _appointments = data.map((item) => Appointment.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error loading appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> bookAppointment(Appointment appointment) async {
    try {
      final id = await DBHelper.instance.insertAppointment(appointment.toMap());
      final newAppointment = appointment.copyWith(id: id);
      _appointments.add(newAppointment);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error booking appointment: $e');
      return false;
    }
  }

  Future<bool> updateAppointmentStatus(
    int id,
    String status, {
    int? doctorId,
  }) async {
    try {
      await DBHelper.instance.updateAppointmentStatus(id, status);
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: status,
          doctorId: doctorId ?? _appointments[index].doctorId,
        );
        notifyListeners();
      }

      // If doctor confirms appointment, automatically assign a driver
      if (status == 'confirmed') {
        final appointment = _appointments[index];
        await _autoAssignDriver(appointment);
      }

      // If doctor completes appointment, also update driver status to completed
      if (status == 'completed') {
        final appointment = _appointments[index];
        if (appointment.driverId != null) {
          // Update driver status to completed
          await DBHelper.instance.updateDriverStatus(
            appointment.driverId!,
            'completed',
            appointment.id,
          );

          // Send notification to driver about completion
          await _sendNotificationToDriver(
            appointment.driverId!,
            appointment.id!,
            'Appointment completed by doctor',
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      return false;
    }
  }

  Future<bool> updateAppointment(Appointment appointment) async {
    if (appointment.id == null) return false;

    try {
      await DBHelper.instance.updateAppointment(
        appointment.id!,
        appointment.toMap(),
      );
      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) {
        _appointments[index] = appointment;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating appointment: $e');
      return false;
    }
  }

  Future<bool> assignDriverToAppointment(
    int appointmentId,
    int driverId,
  ) async {
    try {
      await DBHelper.instance.assignDriverToAppointment(
        appointmentId,
        driverId,
      );
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          driverId: driverId,
        );
        notifyListeners();
      }

      // Send notification to driver about assignment
      await _sendNotificationToDriver(
        driverId,
        appointmentId,
        'New appointment assigned',
      );

      return true;
    } catch (e) {
      debugPrint('Error assigning driver: $e');
      return false;
    }
  }

  Future<void> _sendNotificationToDriver(
    int driverId,
    int appointmentId,
    String message,
  ) async {
    try {
      await DBHelper.instance.insertNotification({
        'user_id': driverId,
        'title': 'Appointment Update',
        'message': message,
        'type': 'appointment',
        'is_read': 0,
        'created_at': DateTime.now().toIso8601String(),
        'data': '{"appointment_id": $appointmentId}',
      });
    } catch (e) {
      debugPrint('Error sending notification to driver: $e');
    }
  }

  Future<bool> assignDoctorToAppointment(
    int appointmentId,
    int doctorId,
  ) async {
    try {
      await DBHelper.instance.updateAppointment(appointmentId, {
        'doctor_id': doctorId,
      });
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          doctorId: doctorId,
        );
        notifyListeners();
      }

      // Send notification to doctor about assignment
      await _sendNotificationToDoctor(
        doctorId,
        appointmentId,
        'New appointment assigned',
      );

      return true;
    } catch (e) {
      debugPrint('Error assigning doctor: $e');
      return false;
    }
  }

  Future<void> _sendNotificationToDoctor(
    int doctorId,
    int appointmentId,
    String message,
  ) async {
    try {
      await DBHelper.instance.insertNotification({
        'user_id': doctorId,
        'title': 'Appointment Update',
        'message': message,
        'type': 'appointment',
        'is_read': 0,
        'created_at': DateTime.now().toIso8601String(),
        'data': '{"appointment_id": $appointmentId}',
      });
    } catch (e) {
      debugPrint('Error sending notification to doctor: $e');
    }
  }

  Future<void> _autoAssignDoctor(Appointment appointment) async {
    try {
      // Only assign doctor if not already assigned
      if (appointment.doctorId != null) {
        debugPrint('Doctor already assigned to appointment ${appointment.id}');
        return;
      }

      // Get all doctors
      final doctors = await DBHelper.instance.getAllUsers(role: 'doctor');

      if (doctors.isNotEmpty) {
        // For now, assign the first available doctor
        // In a real app, you might use specialty-based or load-balancing assignment
        final doctorId = doctors.first['id'] as int;

        // Assign doctor to appointment
        await assignDoctorToAppointment(appointment.id!, doctorId);

        debugPrint(
          'Auto-assigned doctor $doctorId to appointment ${appointment.id}',
        );
      } else {
        debugPrint('No doctors found for appointment ${appointment.id}');
      }
    } catch (e) {
      debugPrint('Error auto-assigning doctor: $e');
    }
  }

  Future<void> _autoAssignDriver(Appointment appointment) async {
    try {
      // Get available drivers
      final availableDrivers = await DBHelper.instance.getAvailableDrivers();

      if (availableDrivers.isNotEmpty) {
        // For now, assign the first available driver
        // In a real app, you might use location-based assignment
        final driverId = availableDrivers.first['driver_id'] as int;

        // Assign driver to appointment
        await assignDriverToAppointment(appointment.id!, driverId);

        // Update driver status to indicate they have an assignment
        await DBHelper.instance.updateDriverStatus(
          driverId,
          'assigned',
          appointment.id,
        );

        debugPrint(
          'Auto-assigned driver $driverId to appointment ${appointment.id}',
        );
      } else {
        debugPrint(
          'No available drivers found for appointment ${appointment.id}',
        );
      }
    } catch (e) {
      debugPrint('Error auto-assigning driver: $e');
    }
  }

  Appointment? getAppointmentById(int id) {
    return _appointments.firstWhere((appointment) => appointment.id == id);
  }

  List<Appointment> getAppointmentsByOwner(int ownerId) {
    return _appointments
        .where((appointment) => appointment.ownerId == ownerId)
        .toList();
  }

  List<Appointment> getAppointmentsByDoctor(int doctorId) {
    return _appointments
        .where((appointment) => appointment.doctorId == doctorId)
        .toList();
  }
}

// Role-based permission checks
const Map<String, Set<String>> _allowedTransitions = {
  'pending': {'confirmed', 'cancelled'},
  'confirmed': {
    'en_route',
    'cancelled',
    'completed',
  }, // Allow doctors to complete confirmed appointments
  'en_route': {'in_progress', 'delayed', 'cancelled'},
  'in_progress': {'completed', 'cancelled'},
  'completed': {},
  'cancelled': {},
  'delayed': {'in_progress', 'cancelled'},
};

bool canOwnerUpdateAppointment(String currentStatus, String newStatus) {
  // Owners can only cancel or reschedule pending appointments
  // They cannot mark appointments as complete - that's for doctors only
  if (currentStatus == 'pending') {
    return newStatus == 'cancelled' || newStatus == 'rescheduled';
  }
  return false;
}

bool canDoctorUpdateAppointment(String currentStatus, String newStatus) {
  // Doctors can manage all transitions except owner-only actions
  final allowed = _allowedTransitions[currentStatus] ?? {};
  return allowed.contains(newStatus);
}

bool canDriverUpdateAppointment(String currentStatus, String newStatus) {
  // Drivers can only update status during service delivery
  if (currentStatus == 'confirmed') {
    return newStatus == 'en_route';
  }
  if (currentStatus == 'en_route') {
    return newStatus == 'in_progress' || newStatus == 'delayed';
  }
  return false;
}
