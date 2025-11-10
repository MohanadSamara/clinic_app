// lib/providers/appointment_provider.dart
import 'dart:convert';

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

  Future<void> loadAppointments({
    int? ownerId,
    int? doctorId,
    int? driverId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DBHelper.instance.getAppointments(
        ownerId: ownerId,
        doctorId: doctorId,
        driverId: driverId,
      );
      _appointments = data.map((item) => Appointment.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error loading appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDriverAppointments(int driverId) async {
    await loadAppointments(driverId: driverId);
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
    int? driverId,
    bool notifyUsers = true,
    String? note,
  }) async {
    try {
      await DBHelper.instance.updateAppointmentStatus(id, status);
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: status,
          doctorId: doctorId ?? _appointments[index].doctorId,
          driverId: driverId ?? _appointments[index].driverId,
        );
        notifyListeners();
      }

      if (notifyUsers && index != -1) {
        final appointment = _appointments[index];
        await _notifyStatusChange(appointment, status, note: note);
      }

      return true;
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      return false;
    }
  }

  Future<bool> rescheduleAppointment(
    int appointmentId,
    DateTime newDateTime,
  ) async {
    try {
      await DBHelper.instance.updateAppointment(appointmentId, {
        'scheduled_at': newDateTime.toIso8601String(),
        'status': 'rescheduled',
      });
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          scheduledAt: newDateTime.toIso8601String(),
          status: 'rescheduled',
        );
        notifyListeners();
        await _notifyStatusChange(
          _appointments[index],
          'rescheduled',
          note: 'New time: ${newDateTime.toLocal()}',
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error rescheduling appointment: $e');
      return false;
    }
  }

  Future<bool> assignDriverToAppointment(
    int appointmentId,
    int driverId, {
    bool dispatchImmediately = false,
    String? driverName,
    String? driverPhone,
  }) async {
    try {
      final updateData = {
        'driver_id': driverId,
      };
      if (dispatchImmediately) {
        updateData['status'] = 'en_route';
      }
      await DBHelper.instance.updateAppointment(appointmentId, updateData);
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          driverId: driverId,
          driverName: driverName ?? _appointments[index].driverName,
          driverPhone: driverPhone ?? _appointments[index].driverPhone,
          status:
              dispatchImmediately ? 'en_route' : _appointments[index].status,
        );
        notifyListeners();
        await _sendNotification(
          userId: driverId,
          title: 'New dispatch assignment',
          message:
              'You have been assigned to appointment #$appointmentId. ${dispatchImmediately ? 'Please head out now.' : ''}',
          data: {'appointment_id': appointmentId},
        );
        await _notifyStatusChange(
          _appointments[index],
          dispatchImmediately ? 'en_route' : 'assigned_driver',
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error assigning driver: $e');
      return false;
    }
  }

  Future<bool> updateDriverProgress(
    int appointmentId,
    String status,
  ) async {
    final index =
        _appointments.indexWhere((element) => element.id == appointmentId);
    if (index == -1) return false;
    final appointment = _appointments[index];
    return updateAppointmentStatus(
      appointmentId,
      status,
      driverId: appointment.driverId,
      notifyUsers: true,
    );
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
    await _sendNotification(
      userId: doctorId,
      title: 'Appointment Update',
      message: message,
      data: {'appointment_id': appointmentId},
    );
  }

  Future<void> _sendNotification({
    required int userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String type = 'appointment',
  }) async {
    try {
      await DBHelper.instance.insertNotification({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': 0,
        'created_at': DateTime.now().toIso8601String(),
        'data': data != null ? jsonEncode(data) : null,
      });
    } catch (e) {
      debugPrint('Error sending notification to user $userId: $e');
    }
  }

  Future<void> _notifyStatusChange(
    Appointment appointment,
    String status, {
    String? note,
  }) async {
    final statusMessage = _statusMessages[status] ?? 'Appointment updated';
    final message = note != null ? '$statusMessage ($note)' : statusMessage;
    await _sendNotification(
      userId: appointment.ownerId,
      title: 'Appointment ${appointment.serviceType}',
      message: message,
      data: {
        'appointment_id': appointment.id,
        'status': status,
      },
    );

    if (appointment.doctorId != null) {
      await _sendNotification(
        userId: appointment.doctorId!,
        title: 'Appointment ${appointment.serviceType}',
        message: 'Status updated to $status',
        data: {
          'appointment_id': appointment.id,
          'status': status,
        },
      );
    }

    if (appointment.driverId != null) {
      await _sendNotification(
        userId: appointment.driverId!,
        title: 'Route update',
        message: 'Appointment status changed to $status',
        data: {
          'appointment_id': appointment.id,
          'status': status,
        },
      );
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

  List<Appointment> getAppointmentsByDriver(int driverId) {
    return _appointments
        .where((appointment) => appointment.driverId == driverId)
        .toList();
  }
}

const Map<String, String> _statusMessages = {
  'pending': 'Appointment received',
  'confirmed': 'Appointment confirmed',
  'rescheduled': 'Appointment rescheduled',
  'en_route': 'Mobile clinic is en route',
  'in_progress': 'Doctor has arrived',
  'completed': 'Appointment completed',
  'cancelled': 'Appointment cancelled',
  'delayed': 'Appointment delayed',
  'assigned_driver': 'Driver assigned',
};

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
