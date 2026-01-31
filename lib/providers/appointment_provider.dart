// lib/providers/appointment_provider.dart
// Appointment Provider using Firestore as the single source of truth
// All data synced globally across devices
// OTP Authentication remains UNCHANGED

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import '../models/service.dart';
import '../models/payment.dart';
import '../models/pet.dart';
import '../services/calendar_service.dart';

class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _appointments = [];
  List<Service> _services = [];
  bool _isLoading = false;
  String? _error;

  List<Appointment> get appointments => _appointments;
  List<Service> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== LOAD DATA ==========

  Future<void> loadServices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('services').get();
      _services = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
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
    int? ownerId,
    int? doctorId,
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('appointments')
          .orderBy('scheduledAt', descending: true);

      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId.toString());
      }
      if (doctorId != null) {
        query = query.where('doctorId', isEqualTo: doctorId.toString());
      }

      final snapshot = await query.get();

      _appointments = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? doc.id.hashCode;
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
      // Add to Firestore
      final docRef = await _firestore.collection('appointments').add({
        'ownerId': appointment.ownerId.toString(),
        'petId': appointment.petId.toString(),
        'serviceType': appointment.serviceType,
        'description': appointment.description,
        'scheduledAt': appointment.scheduledAt,
        'status': 'pending',
        'address': appointment.address,
        'price': appointment.price,
        'doctorId': appointment.doctorId?.toString(),
        'driverId': appointment.driverId?.toString(),
        'urgencyLevel': appointment.urgencyLevel,
        'locationLat': appointment.locationLat,
        'locationLng': appointment.locationLng,
        'paymentMethod': appointment.paymentMethod,
        'serviceRequestId': appointment.serviceRequestId?.toString(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update with document ID
      await docRef.update({'id': docRef.id});

      // Create local appointment object
      final newAppointment = appointment.copyWith(
        id: int.tryParse(docRef.id.hashCode.toString()) ?? docRef.id.hashCode,
      );

      _appointments.insert(0, newAppointment);
      notifyListeners();

      // Schedule calendar event
      try {
        final calendarEventId = await CalendarService.addAppointmentToCalendar(
          newAppointment,
        );
        if (calendarEventId != null) {
          await docRef.update({'calendarEventId': calendarEventId});
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
      // Find the document in Firestore
      final snapshot = await _firestore.collection('appointments').get();

      String? docId;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (int.tryParse(doc.id) == id || doc.id.hashCode == id) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        await _firestore.collection('appointments').doc(docId).update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update local state
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: status,
          doctorId: doctorId ?? _appointments[index].doctorId,
        );
        notifyListeners();
      }

      // Create payment when doctor accepts
      if (status == 'accepted') {
        final appointment = getAppointmentById(id);
        if (appointment != null) {
          await _createPaymentForAppointment(appointment);
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
      // Find and update in Firestore
      final snapshot = await _firestore.collection('appointments').get();

      String? docId;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (int.tryParse(doc.id) == appointment.id ||
            doc.id.hashCode == appointment.id) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        await _firestore.collection('appointments').doc(docId).update({
          'serviceType': appointment.serviceType,
          'description': appointment.description,
          'scheduledAt': appointment.scheduledAt,
          'status': appointment.status,
          'address': appointment.address,
          'price': appointment.price,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

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
      // Find and update in Firestore
      final snapshot = await _firestore.collection('appointments').get();

      String? docId;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (int.tryParse(doc.id) == appointmentId ||
            doc.id.hashCode == appointmentId) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        await _firestore.collection('appointments').doc(docId).update({
          'doctorId': doctorId.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update local state
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          doctorId: doctorId,
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
      // Find and update in Firestore
      final snapshot = await _firestore.collection('appointments').get();

      String? docId;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (int.tryParse(doc.id) == appointmentId ||
            doc.id.hashCode == appointmentId) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        await _firestore.collection('appointments').doc(docId).update({
          'driverId': driverId.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update local state
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          driverId: driverId,
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
      final docRef = await _firestore.collection('services').add({
        'name': service.name,
        'description': service.description,
        'price': service.price,
        'category': service.category,
        'isActive': service.isActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await docRef.update({
        'id': int.tryParse(docRef.id) ?? docRef.id.hashCode,
      });

      final newService = service.copyWith(
        id: int.tryParse(docRef.id) ?? docRef.id.hashCode,
      );
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
      // Find and update in Firestore
      final snapshot = await _firestore.collection('services').get();

      String? docId;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (int.tryParse(doc.id) == service.id ||
            doc.id.hashCode == service.id) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        await _firestore.collection('services').doc(docId).update({
          'name': service.name,
          'description': service.description,
          'price': service.price,
          'category': service.category,
          'isActive': service.isActive,
        });
      }

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
      // Find and delete from Firestore
      final snapshot = await _firestore.collection('services').get();

      String? docId;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (int.tryParse(doc.id) == id || doc.id.hashCode == id) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        await _firestore.collection('services').doc(docId).delete();
      }

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

      await _firestore.collection('payments').add({
        'appointmentId': appointment.id.toString(),
        'userId': appointment.ownerId.toString(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'currency': 'JOD',
        'method': appointment.paymentMethod ?? 'cash',
        'status': 'pending',
        'serviceDescription': appointment.serviceType ?? 'Veterinary Service',
        'invoiceNumber': invoiceNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });

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
