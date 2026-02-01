// lib/providers/schedule_provider.dart
// Schedule Provider using Supabase for global sync
// Migrated to Supabase database (PostgreSQL) - 2026-01-31

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/supabase_complete_service.dart';
import '../models/schedule.dart';

/// ScheduleProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: schedules, system_settings
///
/// All database operations now use Supabase client exclusively.
/// Firestore has been completely removed.
class ScheduleProvider extends ChangeNotifier {
  // Supabase service instance for database operations
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  List<DoctorSchedule> _schedules = [];
  Map<String, dynamic> _systemSettings = {};
  bool _isLoading = false;
  String? _currentDoctorId;

  List<DoctorSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;

  // Set current doctor and load their schedules
  void setCurrentDoctorId(String? doctorId) {
    if (doctorId == null) {
      _currentDoctorId = null;
      return;
    }
    _currentDoctorId = doctorId;
    loadSchedules(_currentDoctorId!);
  }

  // Load schedules from Supabase
  Future<void> loadSchedules(String doctorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final schedulesData = await _supabaseService.getSchedulesByDoctor(
        doctorId,
      );

      _schedules = schedulesData.map((data) => DoctorSchedule.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error loading schedules from Supabase: $e');
      _schedules = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load system settings from Supabase
  Future<void> loadSystemSettings() async {
    try {
      _systemSettings = await _supabaseService.getSystemSettings();
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

    if (schedule.isHoliday) {
      return true;
    }

    final startMinutes = _parseTime(scheduleStart);
    final endMinutes = _parseTime(scheduleEnd);
    final systemStartMinutes = _parseTime(systemStart);
    final systemEndMinutes = _parseTime(systemEnd);

    return startMinutes >= systemStartMinutes && endMinutes <= systemEndMinutes;
  }

  // Add or update a schedule in Supabase
  Future<bool> saveSchedule(DoctorSchedule schedule) async {
    if (!isScheduleValid(schedule)) {
      return false;
    }

    if (schedule.isHoliday) {
      final holidayCount = _schedules.where((s) => s.isHoliday).length;
      if (holidayCount >= 2 &&
          !_schedules.any((s) => s.id == schedule.id && s.isHoliday)) {
        return false;
      }
    }

    try {
      final scheduleData = schedule.toMap();
      scheduleData.remove('id');

      if (schedule.id == null || schedule.id!.isEmpty) {
        // Create new schedule
        final scheduleId = await _supabaseService.insertSchedule(scheduleData);
        final newSchedule = schedule.copyWith(id: scheduleId);
        _schedules.add(newSchedule);
      } else {
        // Update existing schedule
        await _supabaseService.updateSchedule(schedule.id!, scheduleData);
        final index = _schedules.indexWhere((s) => s.id == schedule.id);
        if (index != -1) {
          _schedules[index] = schedule;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving schedule to Supabase: $e');
      return false;
    }
  }

  // Delete a schedule from Supabase
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _supabaseService.deleteSchedule(scheduleId);
      _schedules.removeWhere((s) => s.id == scheduleId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting schedule from Supabase: $e');
      return false;
    }
  }

  // Get schedule for a specific day
  DoctorSchedule? getScheduleForDay(String doctorId, String dayOfWeek) {
    try {
      return _schedules.firstWhere(
        (schedule) =>
            schedule.doctorId == doctorId && schedule.dayOfWeek == dayOfWeek,
      );
    } catch (e) {
      return DoctorSchedule(
        doctorId: doctorId,
        dayOfWeek: dayOfWeek,
        startTime: '08:00',
        endTime: '18:00',
        isActive: false,
        isHoliday: false,
        isFreeDay: false,
      );
    }
  }

  // Check if doctor is available at a specific time
  bool isDoctorAvailable(String doctorId, String dayOfWeek, String time) {
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
