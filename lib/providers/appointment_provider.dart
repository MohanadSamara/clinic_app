// lib/providers/appointment_provider.dart
// Migrated to Supabase database (PostgreSQL) - 2026-01-31
// All data synced globally across devices via Supabase

import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/supabase_complete_service.dart';
import '../models/appointment.dart';
import '../models/service.dart';
import '../models/payment.dart';
import '../models/pet.dart';
import '../services/calendar_service.dart';

/// AppointmentProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: appointments, services, payments
///
/// All database operations now use Supabase client exclusively.
/// Firestore has been completely removed.
class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _appointments = [];
  List<Service> _services = [];
  bool _isLoading = false;
  String? _error;

  List<Appointment> get appointments => _appointments;
  List<Service> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Supabase service instance for database operations (singleton)
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  // ========== LOAD DATA ==========

  Future<void> loadServices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final services = await _supabaseService.getServices();
      _services = services.map((data) {
        data['id'] = data['id'] ?? data['id'].hashCode;
        return Service.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading services: $e');
      _error = 'Error loading services: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAppointments({
    String? ownerId,
    String? doctorId,
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final appointments = await _supabaseService.getAppointments(
        ownerId: ownerId?.toString(),
        doctorId: doctorId?.toString(),
      );

      _appointments = appointments.map((data) {
        data['id'] = data['id'] ?? data['id'].hashCode;
        return Appointment.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      _error = 'Error loading appointments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== BOOK APPOINTMENT ==========

  Future<bool> bookAppointment(Appointment appointment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Add to Supabase
      final appointmentData = appointment.toMap();
      final id = await _supabaseService.insertAppointment(appointmentData);

      // Create local appointment object
      final newAppointment = appointment.copyWith(id: id.hashCode);

      _appointments.insert(0, newAppointment);
      notifyListeners();

      // Schedule calendar event
      try {
        final calendarEventId = await CalendarService.addAppointmentToCalendar(
          newAppointment,
        );
        if (calendarEventId != null) {
          await _supabaseService.updateAppointment(id, {
            'calendar_event_id': calendarEventId,
          });
        }
      } catch (e) {
        debugPrint('Error adding to calendar: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error booking appointment: $e');
      _error = 'Error booking appointment: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== UPDATE STATUS ==========

  Future<bool> updateAppointmentStatus(
    int id,
    String status, {
    int? doctorId,
  }) async {
    try {
      // Find the appointment in local state to get the UUID
      final appointment = _appointments.firstWhere((a) => a.id == id);

      // Update in Supabase
      await _supabaseService.updateAppointmentStatus(
        appointment.id.toString(),
        status,
      );

      // Update local state
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: status,
          doctorId: doctorId?.toString() ?? _appointments[index].doctorId,
        );
        notifyListeners();
      }

      // Create payment when doctor accepts
      if (status == 'accepted') {
        final apt = getAppointmentById(id);
        if (apt != null) {
          await _createPaymentForAppointment(apt);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      return false;
    }
  }

  // ========== UPDATE APPOINTMENT ==========

  Future<bool> updateAppointment(Appointment appointment) async {
    if (appointment.id == null) return false;

    try {
      // Update in Supabase
      await _supabaseService.updateAppointment(
        appointment.id.toString(),
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

  // ========== ASSIGN DOCTOR ==========

  Future<bool> assignDoctorToAppointment(
    int appointmentId,
    int doctorId,
  ) async {
    try {
      // Find the appointment in local state to get the UUID
      final appointment = _appointments.firstWhere(
        (a) => a.id == appointmentId,
      );

      // Update in Supabase
      await _supabaseService.updateAppointment(appointment.id.toString(), {
        'doctor_id': doctorId.toString(),
      });

      // Update local state
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          doctorId: doctorId.toString(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error assigning doctor: $e');
      return false;
    }
  }

  // ========== ASSIGN DRIVER ==========

  Future<bool> assignDriverToAppointment(
    int appointmentId,
    int driverId,
  ) async {
    try {
      // Find the appointment in local state to get the UUID
      final appointment = _appointments.firstWhere(
        (a) => a.id == appointmentId,
      );

      // Update in Supabase
      await _supabaseService.updateAppointment(appointment.id.toString(), {
        'driver_id': driverId.toString(),
      });

      // Update local state
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          driverId: driverId.toString(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error assigning driver: $e');
      return false;
    }
  }

  // ========== HELPERS ==========

  Appointment? getAppointmentById(int id) {
    try {
      return _appointments.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Appointment> getAppointmentsByOwner(int ownerId) {
    return _appointments
        .where((a) => a.ownerId.toString() == ownerId.toString())
        .toList();
  }

  List<Appointment> getAppointmentsByDoctor(int doctorId) {
    return _appointments
        .where((a) => a.doctorId?.toString() == doctorId.toString())
        .toList();
  }

  // ========== SERVICES ==========

  Future<void> addService(Service service) async {
    try {
      final serviceData = service.toMap();
      final id = await _supabaseService.insertService(serviceData);

      final newService = service.copyWith(id: id.hashCode);
      _services.add(newService);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding service: $e');
      rethrow;
    }
  }

  Future<void> updateService(Service service) async {
    if (service.id == null) return;

    try {
      // Find the service in local state to get the UUID
      final localService = _services.firstWhere((s) => s.id == service.id);

      // Update in Supabase
      await _supabaseService.updateService(
        localService.id.toString(),
        service.toMap(),
      );

      final index = _services.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _services[index] = service;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating service: $e');
      rethrow;
    }
  }

  Future<void> deleteService(int id) async {
    try {
      // Find the service in local state to get the UUID
      final localService = _services.firstWhere((s) => s.id == id);

      // Delete from Supabase
      await _supabaseService.deleteService(localService.id.toString());

      _services.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting service: $e');
      rethrow;
    }
  }

  // ========== PAYMENTS ==========

  Future<void> _createPaymentForAppointment(Appointment appointment) async {
    try {
      final subtotal = appointment.price ?? 0.0;
      final tax = subtotal * 0.16;
      final total = subtotal + tax;

      final invoiceNumber =
          'INV-${appointment.id}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      final paymentData = {
        'appointment_id': appointment.id.toString(),
        'user_id': appointment.ownerId.toString(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'currency': 'JOD',
        'method': appointment.paymentMethod ?? 'cash',
        'status': 'pending',
        'service_description': appointment.serviceType ?? 'Veterinary Service',
        'invoice_number': invoiceNumber,
      };

      await _supabaseService.insertPayment(paymentData);

      debugPrint('Payment record created for appointment ${appointment.id}');
    } catch (e) {
      debugPrint('Error creating payment for appointment: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Role-based permission checks
const Map<String, Set<String>> _allowedTransitions = {
  'pending': {'accepted', 'cancelled', 'rescheduled'},
  'accepted': {'confirmed', 'cancelled', 'rescheduled'},
  'confirmed': {
    'en_route',
    'arrived',
    'cancelled',
    'completed',
    'no_show',
    'paid',
  },
  'en_route': {'in_progress', 'arrived', 'delayed', 'cancelled'},
  'arrived': {'waiting', 'in_progress', 'cancelled'},
  'waiting': {'in_progress', 'on_hold', 'cancelled'},
  'on_hold': {'waiting', 'in_progress', 'cancelled'},
  'in_progress': {'completed', 'cancelled'},
  'completed': {},
  'cancelled': {},
  'delayed': {'in_progress', 'cancelled'},
  'no_show': {'rescheduled', 'cancelled'},
  'rescheduled': {'pending', 'cancelled'},
  'paid': {'completed', 'cancelled', 'refunded'},
  'refunded': {'cancelled'},
};

bool canOwnerUpdateAppointment(String currentStatus, String newStatus) {
  if (currentStatus == 'pending') {
    return newStatus == 'cancelled' || newStatus == 'rescheduled';
  }
  if (currentStatus == 'accepted') {
    return newStatus == 'confirmed' ||
        newStatus == 'cancelled' ||
        newStatus == 'rescheduled';
  }
  if (currentStatus == 'confirmed') {
    return newStatus == 'cancelled' || newStatus == 'rescheduled';
  }
  if (currentStatus == 'arrived' ||
      currentStatus == 'waiting' ||
      currentStatus == 'on_hold') {
    return newStatus == 'cancelled';
  }
  if (currentStatus == 'no_show') {
    return newStatus == 'rescheduled' || newStatus == 'cancelled';
  }
  if (currentStatus == 'rescheduled' ||
      currentStatus == 'paid' ||
      currentStatus == 'refunded') {
    return newStatus == 'cancelled';
  }
  return false;
}

bool canDoctorUpdateAppointment(String currentStatus, String newStatus) {
  final allowed = _allowedTransitions[currentStatus] ?? {};
  return allowed.contains(newStatus);
}
