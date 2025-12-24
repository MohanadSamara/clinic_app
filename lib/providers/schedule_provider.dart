import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/schedule.dart';
import '../db/db_helper.dart';

class ScheduleProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper.instance;

  List<DoctorSchedule> _schedules = [];
  bool _isLoading = false;
  Map<String, dynamic> _systemSettings = {};

  List<DoctorSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get systemSettings => _systemSettings;

  // Get schedules for a specific doctor
  Future<void> loadSchedules(int doctorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final scheduleData = await _dbHelper.getSchedulesByDoctor(doctorId);
      _schedules = scheduleData
          .map((data) => DoctorSchedule.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error loading schedules: $e');
      _schedules = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load system settings
  Future<void> loadSystemSettings() async {
    try {
      _systemSettings = await _dbHelper.getSystemSettings();
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

    // For holiday days, no validation needed (doctor is not working)
    if (schedule.isHoliday) {
      debugPrint('Validation passed: Holiday day (no work)');
      return true;
    }

    // For free days, allow any times within system bounds
    if (schedule.isFreeDay) {
      final startMinutes = _parseTime(scheduleStart);
      final endMinutes = _parseTime(scheduleEnd);
      final systemStartMinutes = _parseTime(systemStart);
      final systemEndMinutes = _parseTime(systemEnd);

      // Free day times must be within system working hours
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

    // For regular days, doctor can set any hours within system bounds
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

  // Add or update a schedule
  Future<bool> saveSchedule(DoctorSchedule schedule) async {
    try {
      // Validate against system working hours
      if (!isScheduleValid(schedule)) {
        debugPrint(
          'Schedule validation failed: times outside system working hours',
        );
        return false;
      }

      // Limit to 2 holiday days per doctor
      if (schedule.isHoliday) {
        final holidayCount = _schedules.where((s) => s.isHoliday).length;
        if (holidayCount >= 2 &&
            !_schedules.any((s) => s.id == schedule.id && s.isHoliday)) {
          debugPrint('Validation failed: Maximum 2 holiday days allowed');
          return false;
        }
      }

      if (schedule.id == null) {
        // Insert new schedule
        final id = await _dbHelper.insertSchedule(schedule.toMap());
        final newSchedule = schedule.copyWith(id: id);
        _schedules.add(newSchedule);
      } else {
        // Update existing schedule
        await _dbHelper.updateSchedule(schedule.id!, schedule.toMap());
        final index = _schedules.indexWhere((s) => s.id == schedule.id);
        if (index != -1) {
          _schedules[index] = schedule;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving schedule: $e');
      return false;
    }
  }

  // Delete a schedule
  Future<bool> deleteSchedule(int scheduleId) async {
    try {
      await _dbHelper.deleteSchedule(scheduleId);
      _schedules.removeWhere((s) => s.id == scheduleId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting schedule: $e');
      return false;
    }
  }

  // Get schedule for a specific day
  DoctorSchedule? getScheduleForDay(int doctorId, String dayOfWeek) {
    return _schedules.firstWhere(
      (schedule) =>
          schedule.doctorId == doctorId && schedule.dayOfWeek == dayOfWeek,
      orElse: () => DoctorSchedule(
        doctorId: doctorId,
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
  bool isDoctorAvailable(int doctorId, String dayOfWeek, String time) {
    final schedule = getScheduleForDay(doctorId, dayOfWeek);
    if (schedule == null || !schedule.isActive) return false;

    // Parse time strings and compare
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
