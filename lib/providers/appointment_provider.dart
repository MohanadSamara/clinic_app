// lib/providers/appointment_provider.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../db/db_helper.dart';
import '../models/appointment.dart';
import '../models/driver_status.dart';
import '../models/service.dart';
import '../providers/notification_provider.dart';
import '../models/pet.dart';
import '../services/calendar_service.dart';

class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _appointments = [];
  List<Service> _services = [];
  bool _isLoading = false;
  final CacheManager _cacheManager = DefaultCacheManager();

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
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check cache first unless force refresh
      if (!forceRefresh && ownerId != null) {
        final cacheKey = 'appointments_owner_$ownerId';
        final cachedData = await _cacheManager.getFileFromCache(cacheKey);
        if (cachedData != null &&
            cachedData.validTill.isAfter(DateTime.now())) {
          // Use cached data
          final cachedAppointments = await cachedData.file.readAsString();
          final data = jsonDecode(cachedAppointments) as List;
          _appointments = data
              .map((item) => Appointment.fromMap(item))
              .toList();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      final data = await DBHelper.instance.getAppointments(
        ownerId: ownerId,
        doctorId: doctorId,
      );
      _appointments = data.map((item) => Appointment.fromMap(item)).toList();

      // Cache the results for owner-specific queries
      if (ownerId != null) {
        final cacheKey = 'appointments_owner_$ownerId';
        await _cacheManager.putFile(
          cacheKey,
          utf8.encode(jsonEncode(_appointments.map((a) => a.toMap()).toList())),
          maxAge: const Duration(minutes: 5),
        );
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> bookAppointment(Appointment appointment) async {
    try {
      // Get driver name if driver is assigned
      String? driverName;
      if (appointment.driverId != null) {
        driverName = await DBHelper.instance.getUserNameById(
          appointment.driverId!,
        );
      }

      // Get doctor name if doctor is assigned
      String? doctorName;
      if (appointment.doctorId != null) {
        doctorName = await DBHelper.instance.getUserNameById(
          appointment.doctorId!,
        );
      }

      final id = await DBHelper.instance.insertAppointment(appointment.toMap());
      final newAppointment = appointment.copyWith(
        id: id,
        driverName: driverName,
        doctorName: doctorName,
      );
      _appointments.add(newAppointment);

      // Update cache with new appointments list for the owner
      final cacheKey = 'appointments_owner_${appointment.ownerId}';
      await _cacheManager.putFile(
        cacheKey,
        utf8.encode(jsonEncode(_appointments.map((a) => a.toMap()).toList())),
        maxAge: const Duration(minutes: 5),
      );

      // Schedule appointment reminder notification
      await _scheduleAppointmentNotifications(newAppointment);

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

      // Auto-assign driver when appointment is confirmed (only if no driver assigned)
      if (status == 'confirmed') {
        final appointment = getAppointmentById(id);
        if (appointment != null && appointment.driverId == null) {
          final availableDriverId = await _getAvailableDriver(id);
          if (availableDriverId != null) {
            await assignDriverToAppointment(id, availableDriverId);
          }
        }

        // Sync confirmed appointment to calendar
        if (appointment != null) {
          try {
            final calendarSuccess =
                await CalendarService.addAppointmentToCalendar(appointment);
            if (calendarSuccess) {
              debugPrint('Appointment ${appointment.id} synced to calendar');
            } else {
              debugPrint(
                'Failed to sync appointment ${appointment.id} to calendar',
              );
            }
          } catch (e) {
            debugPrint('Error syncing appointment to calendar: $e');
          }
        }
      }

      // If doctor completes appointment, mark as completed
      if (status == 'completed') {
        // Appointment is now completed by doctor
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

  Future<bool> assignDoctorToAppointment(
    int appointmentId,
    int doctorId,
  ) async {
    try {
      // Get the linked driver for this doctor
      final linkedDriverId = await _getLinkedDriverForDoctor(doctorId);

      await DBHelper.instance.updateAppointment(appointmentId, {
        'doctor_id': doctorId,
        'driver_id': linkedDriverId,
      });

      final doctorName = await DBHelper.instance.getUserNameById(doctorId);
      final driverName = linkedDriverId != null
          ? await DBHelper.instance.getUserNameById(linkedDriverId)
          : null;

      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          doctorId: doctorId,
          doctorName: doctorName,
          driverId: linkedDriverId,
          driverName: driverName,
        );
        notifyListeners();
      }

      // Send notification to doctor about assignment
      await _sendNotificationToDoctor(
        doctorId,
        appointmentId,
        'New appointment assigned',
      );

      // Send notification to linked driver if exists
      if (linkedDriverId != null) {
        await _sendNotificationToDriver(
          linkedDriverId,
          appointmentId,
          'New appointment assigned (linked to doctor)',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error assigning doctor: $e');
      return false;
    }
  }

  Future<bool> assignDriverToAppointment(
    int appointmentId,
    int driverId,
  ) async {
    try {
      // Get driver name
      final driverName = await DBHelper.instance.getUserNameById(driverId);

      await DBHelper.instance.updateAppointment(appointmentId, {
        'driver_id': driverId,
      });
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          driverId: driverId,
          driverName: driverName,
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

  Future<int?> _getLinkedDriverForDoctor(int doctorId) async {
    try {
      final doctorData = await DBHelper.instance.getUserById(doctorId);
      if (doctorData != null) {
        return doctorData['linked_driver_id'] as int?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting linked driver for doctor: $e');
      return null;
    }
  }

  Future<int?> _getAvailableDriver(int appointmentId) async {
    try {
      // Get appointment details to check location and doctor
      final appointment = getAppointmentById(appointmentId);
      if (appointment == null) return null;

      // PRIORITY 1: Check if appointment's doctor has a linked driver
      if (appointment.doctorId != null) {
        final linkedDriverId = await _getLinkedDriverForDoctor(
          appointment.doctorId!,
        );
        if (linkedDriverId != null) {
          // Check if linked driver is available and nearby
          final linkedDriverStatus = await DBHelper.instance.getDriverStatus(
            linkedDriverId,
          );
          if (linkedDriverStatus != null) {
            final driverStatus = DriverStatus.fromMap(linkedDriverStatus);
            if (driverStatus.status.toLowerCase() == 'available') {
              // Check if driver is nearby (within reasonable distance)
              if (appointment.locationLat != null &&
                  appointment.locationLng != null) {
                final distance = _calculateDistance(
                  appointment.locationLat!,
                  appointment.locationLng!,
                  driverStatus.latitude,
                  driverStatus.longitude,
                );
                // Linked driver gets priority if within 10km
                if (distance <= 10000) {
                  return linkedDriverId;
                }
              } else {
                // No location data, still prefer linked driver
                return linkedDriverId;
              }
            }
          }
        }
      }

      // PRIORITY 2: Fall back to location-based selection
      // Get driver statuses for drivers that are linked to doctors
      final driverStatusesData = await DBHelper.instance
          .getLinkedDriverStatuses();
      final driverStatuses = driverStatusesData
          .map((data) => DriverStatus.fromMap(data))
          .where((status) => status.status.toLowerCase() == 'available')
          .toList();

      if (driverStatuses.isEmpty) return null;

      // If appointment has no location, return first available driver
      if (appointment.locationLat == null || appointment.locationLng == null) {
        return driverStatuses.first.driverId;
      }

      // Calculate distances and find closest driver
      DriverStatus? closestDriver;
      double? minDistance;

      for (final driverStatus in driverStatuses) {
        final distance = _calculateDistance(
          appointment.locationLat!,
          appointment.locationLng!,
          driverStatus.latitude,
          driverStatus.longitude,
        );

        if (minDistance == null || distance < minDistance) {
          minDistance = distance;
          closestDriver = driverStatus;
        }
      }

      if (closestDriver != null) {
        // Check if there are multiple drivers at the same location (within 100 meters)
        final driversAtSameLocation = driverStatuses.where((driver) {
          final distance = _calculateDistance(
            appointment.locationLat!,
            appointment.locationLng!,
            driver.latitude,
            driver.longitude,
          );
          return distance <= 100; // 100 meters threshold
        }).toList();

        if (driversAtSameLocation.length > 1) {
          // Multiple drivers at same location - use tie-breaker strategy
          // For now, prefer driver with no current appointment, then by ID for consistency
          final availableDrivers = driversAtSameLocation
              .where((driver) => driver.currentAppointmentId == null)
              .toList();

          if (availableDrivers.isNotEmpty) {
            // Return driver with smallest ID for consistency
            availableDrivers.sort((a, b) => a.driverId.compareTo(b.driverId));
            return availableDrivers.first.driverId;
          } else {
            // All have appointments, still prefer by ID
            driversAtSameLocation.sort(
              (a, b) => a.driverId.compareTo(b.driverId),
            );
            return driversAtSameLocation.first.driverId;
          }
        }

        return closestDriver.driverId;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting available driver: $e');
      return null;
    }
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000; // meters
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLng = (lng2 - lng1) * (pi / 180);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
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

  Appointment? getAppointmentById(int id) {
    final result = _appointments.where((appointment) => appointment.id == id);
    return result.isNotEmpty ? result.first : null;
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

  Future<void> addService(Service service) async {
    try {
      final id = await DBHelper.instance.insertService(service.toMap());
      final newService = service.copyWith(id: id);
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
      await DBHelper.instance.updateService(service.id!, service.toMap());
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
      await DBHelper.instance.deleteService(id);
      _services.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting service: $e');
      rethrow;
    }
  }

  Future<void> _scheduleAppointmentNotifications(
    Appointment appointment,
  ) async {
    try {
      // Get pet name for personalized notifications
      String petName = 'your pet';
      if (appointment.petId != null) {
        final petData = await DBHelper.instance.getPetById(appointment.petId!);
        if (petData != null) {
          petName = petData['name'] ?? 'your pet';
        }
      }

      // Parse the scheduled time
      DateTime? scheduledTime;
      if (appointment.scheduledAt != null) {
        scheduledTime = DateTime.tryParse(appointment.scheduledAt!);
      }

      if (scheduledTime == null) return;

      // Schedule appointment reminder (1 hour before)
      final notificationProvider = NotificationProvider();
      await notificationProvider.scheduleAppointmentReminder(
        petName: petName,
        appointmentTime: scheduledTime,
        relatedId: appointment.id?.toString(),
      );
    } catch (e) {
      debugPrint('Error scheduling appointment notifications: $e');
    }
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
