// lib/providers/schedule_provider.dart
// Schedule Provider using Firestore for global sync
// Supports both int (local DB) and String (Firebase Auth) doctor IDs
// OTP Authentication remains UNCHANGED

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule.dart';

class ScheduleProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DoctorSchedule> _schedules = [];
  Map<String, dynamic> _systemSettings = {};
  bool _isLoading = false;
  String? _currentDoctorId; // String for Firestore queries

  List<DoctorSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;

  // Set current doctor and load their schedules
  // Accepts both int (local) and String (Firebase) IDs
  void setCurrentDoctorId(dynamic doctorId) {
    // Convert to String for Firestore
    if (doctorId == null) {
      _currentDoctorId = null;
      return;
    }
    _currentDoctorId = doctorId.toString();
    loadSchedules(_currentDoctorId!);
  }

  // Load schedules from Firestore
  Future<void> loadSchedules(String doctorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // DEBUG: Log database read operation
      debugPrint('===========================================');
      debugPrint('DATABASE READ: Loading schedules from Firestore');
      debugPrint('DATABASE READ: Doctor ID: $doctorId');
      debugPrint('DATABASE READ: Collection: schedules');
      debugPrint('DATABASE READ: Query: where(doctorId, isEqualTo: $doctorId)');

      final snapshot = await _firestore
          .collection('schedules')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      debugPrint('DATABASE READ: Found ${snapshot.docs.length} documents');

      _schedules = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        debugPrint('DATABASE READ: Document ID: ${doc.id}');
        debugPrint('DATABASE READ: Document Data: $data');
        return DoctorSchedule.fromMap(data);
      }).toList();

      debugPrint('DATABASE READ: All schedules loaded successfully');
      debugPrint('===========================================');
    } catch (e) {
      debugPrint('Error loading schedules from Firestore: $e');
      _schedules = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stream schedules in real-time
  Stream<List<DoctorSchedule>> streamSchedules(String doctorId) {
    return _firestore
        .collection('schedules')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return DoctorSchedule.fromMap(data);
          }).toList();
        });
  }

  // Load system settings from Firestore
  Future<void> loadSystemSettings() async {
    try {
      final snapshot = await _firestore.collection('system_settings').get();
      for (final doc in snapshot.docs) {
        _systemSettings[doc.id] = doc.data()['value'];
      }
    } catch (e) {
      debugPrint('Error loading system settings: $e');
      _systemSettings = {};
    }
  }

  // Get system working hours
  String getSystemWorkingHoursStart() {
    return _systemSettings['working_hours_start'] ?? '08:00';
  }

  String getSystemWorkingHoursEnd() {
    return _systemSettings['working_hours_end'] ?? '18:00';
  }

  // Validate schedule against system working hours
  bool isScheduleValid(DoctorSchedule schedule) {
    final systemStart = getSystemWorkingHoursStart();
    final systemEnd = getSystemWorkingHoursEnd();

    final scheduleStart = schedule.startTime;
    final scheduleEnd = schedule.endTime;

    debugPrint('Validating schedule: $scheduleStart - $scheduleEnd');
    debugPrint('System hours: $systemStart - $systemEnd');

    if (schedule.isHoliday) {
      debugPrint('Validation passed: Holiday day (no work)');
      return true;
    }

    if (schedule.isFreeDay) {
      final startMinutes = _parseTime(scheduleStart);
      final endMinutes = _parseTime(scheduleEnd);
      final systemStartMinutes = _parseTime(systemStart);
      final systemEndMinutes = _parseTime(systemEnd);

      if (startMinutes >= systemStartMinutes &&
          endMinutes <= systemEndMinutes) {
        debugPrint(
          'Validation passed: Free day times are within system bounds',
        );
        return true;
      } else {
        debugPrint(
          'Validation failed: Free day times must be within system working hours',
        );
        return false;
      }
    }

    final startMinutes = _parseTime(scheduleStart);
    final endMinutes = _parseTime(scheduleEnd);
    final systemStartMinutes = _parseTime(systemStart);
    final systemEndMinutes = _parseTime(systemEnd);

    if (startMinutes >= systemStartMinutes && endMinutes <= systemEndMinutes) {
      debugPrint('Validation passed: Schedule is within system working hours');
      return true;
    } else {
      debugPrint(
        'Validation failed: Schedule must be within system working hours ($systemStart - $systemEnd)',
      );
      return false;
    }
  }

  // Add or update a schedule in Firestore
  Future<bool> saveSchedule(DoctorSchedule schedule) async {
    if (!isScheduleValid(schedule)) {
      debugPrint(
        'Schedule validation failed: times outside system working hours',
      );
      return false;
    }

    if (schedule.isHoliday) {
      final holidayCount = _schedules.where((s) => s.isHoliday).length;
      if (holidayCount >= 2 &&
          !_schedules.any((s) => s.id == schedule.id && s.isHoliday)) {
        debugPrint('Validation failed: Maximum 2 holiday days allowed');
        return false;
      }
    }

    try {
      // Ensure doctorId is a String for Firestore
      final firestoreDoctorId = schedule.doctorId.toString();

      final scheduleData = schedule.toMap()..remove('id');
      scheduleData['doctorId'] = firestoreDoctorId;

      // DEBUG: Log data being sent to Firestore
      debugPrint('===========================================');
      debugPrint('PROVIDER DEBUG: Saving schedule to Firestore');
      debugPrint('PROVIDER DEBUG: Schedule ID: ${schedule.id ?? "NEW"}');
      debugPrint('PROVIDER DEBUG: Doctor ID: $firestoreDoctorId');
      debugPrint('PROVIDER DEBUG: Day: ${schedule.dayOfWeek}');
      debugPrint('PROVIDER DEBUG: Start Time: ${schedule.startTime}');
      debugPrint('PROVIDER DEBUG: End Time: ${schedule.endTime}');
      debugPrint('PROVIDER DEBUG: Is Holiday: ${schedule.isHoliday}');
      debugPrint('PROVIDER DEBUG: Is Free Day: ${schedule.isFreeDay}');
      debugPrint('PROVIDER DEBUG: Data: $scheduleData');
      debugPrint(
        'PROVIDER DEBUG: Timestamp: ${DateTime.now().toIso8601String()}',
      );
      debugPrint('===========================================');

      if (schedule.id == null || schedule.id!.isEmpty) {
        // Create new schedule
        final docRef = await _firestore
            .collection('schedules')
            .add(scheduleData);
        final newSchedule = schedule.copyWith(
          id: docRef.id,
          doctorId: firestoreDoctorId,
        );
        _schedules.add(newSchedule);
        debugPrint(
          'PROVIDER DEBUG: New schedule created with ID: ${docRef.id}',
        );
      } else {
        // Update existing schedule
        await _firestore
            .collection('schedules')
            .doc(schedule.id)
            .update(scheduleData);
        final index = _schedules.indexWhere((s) => s.id == schedule.id);
        if (index != -1) {
          _schedules[index] = schedule.copyWith(doctorId: firestoreDoctorId);
        }
        debugPrint('PROVIDER DEBUG: Existing schedule updated: ${schedule.id}');
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving schedule to Firestore: $e');
      return false;
    }
  }

  // Delete a schedule from Firestore
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _firestore.collection('schedules').doc(scheduleId).delete();
      _schedules.removeWhere((s) => s.id == scheduleId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting schedule from Firestore: $e');
      return false;
    }
  }

  // Get schedule for a specific day
  DoctorSchedule? getScheduleForDay(dynamic doctorId, String dayOfWeek) {
    final docId = doctorId?.toString() ?? '';
    return _schedules.firstWhere(
      (schedule) =>
          schedule.doctorId == docId && schedule.dayOfWeek == dayOfWeek,
      orElse: () => DoctorSchedule(
        doctorId: docId,
        dayOfWeek: dayOfWeek,
        startTime: '08:00',
        endTime: '18:00',
        isActive: false,
        isHoliday: false,
        isFreeDay: false,
      ),
    );
  }

  // Check if doctor is available at a specific time
  bool isDoctorAvailable(dynamic doctorId, String dayOfWeek, String time) {
    final schedule = getScheduleForDay(doctorId, dayOfWeek);
    if (schedule == null || !schedule.isActive) return false;

    final startTime = _parseTime(schedule.startTime);
    final endTime = _parseTime(schedule.endTime);
    final checkTime = _parseTime(time);

    return checkTime >= startTime && checkTime <= endTime;
  }

  // Helper method to parse time string to minutes since midnight
  int _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  // Clear schedules (useful when switching doctors)
  void clearSchedules() {
    _schedules = [];
    notifyListeners();
  }
}
