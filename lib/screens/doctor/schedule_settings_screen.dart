import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/schedule.dart';

class ScheduleSettingsScreen extends StatefulWidget {
  const ScheduleSettingsScreen({super.key});

  @override
  State<ScheduleSettingsScreen> createState() => _ScheduleSettingsScreenState();
}

class _ScheduleSettingsScreenState extends State<ScheduleSettingsScreen> {
  final List<String> _daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final Map<String, String> _dayLabels = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final scheduleProvider = context.read<ScheduleProvider>();

      if (authProvider.user?.id != null) {
        scheduleProvider.loadSchedules(authProvider.user!.id!);
        scheduleProvider.loadSystemSettings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scheduleProvider = context.watch<ScheduleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Settings'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: scheduleProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _daysOfWeek.length,
              itemBuilder: (context, index) {
                final day = _daysOfWeek[index];
                return _DayScheduleCard(
                  dayOfWeek: day,
                  dayLabel: _dayLabels[day]!,
                  schedule: scheduleProvider.getScheduleForDay(
                    context.read<AuthProvider>().user?.id ?? 0,
                    day,
                  ),
                  onScheduleChanged: (schedule) async {
                    final success = await scheduleProvider.saveSchedule(
                      schedule,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Schedule updated successfully'),
                          backgroundColor: colorScheme.primary,
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Failed to update schedule'),
                          backgroundColor: colorScheme.error,
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}

class _DayScheduleCard extends StatefulWidget {
  final String dayOfWeek;
  final String dayLabel;
  final DoctorSchedule? schedule;
  final Function(DoctorSchedule) onScheduleChanged;

  const _DayScheduleCard({
    required this.dayOfWeek,
    required this.dayLabel,
    required this.schedule,
    required this.onScheduleChanged,
  });

  @override
  State<_DayScheduleCard> createState() => _DayScheduleCardState();
}

class _DayScheduleCardState extends State<_DayScheduleCard> {
  late bool _isActive;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isHoliday;
  late bool _isFreeDay;

  @override
  void initState() {
    super.initState();
    _isActive = widget.schedule?.isActive ?? false;
    _startTime = _parseTimeString(widget.schedule?.startTime ?? '08:00');
    _endTime = _parseTimeString(widget.schedule?.endTime ?? '18:00');
    _isHoliday = widget.schedule?.isHoliday ?? false;
    _isFreeDay = widget.schedule?.isFreeDay ?? false;
  }

  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Helper method to convert TimeOfDay to minutes since midnight
  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final scheduleProvider = context.read<ScheduleProvider>();
    final systemStartTime = scheduleProvider.getSystemWorkingHoursStart();
    final systemEndTime = scheduleProvider.getSystemWorkingHoursEnd();

    // Parse system times
    final systemStart = _parseTimeString(systemStartTime);
    final systemEnd = _parseTimeString(systemEndTime);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (picked != null && mounted) {
      // For holiday days, no time selection allowed (doctor is not working)
      if (_isHoliday) {
        debugPrint('Holiday day: Time selection not allowed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Holiday days have no working hours'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      // For free days, allow any times within system bounds
      if (_isFreeDay) {
        final pickedMinutes = _timeOfDayToMinutes(picked);
        final systemStartMinutes = _timeOfDayToMinutes(systemStart);
        final systemEndMinutes = _timeOfDayToMinutes(systemEnd);

        // Free day times must be within system working hours
        if (pickedMinutes < systemStartMinutes ||
            pickedMinutes > systemEndMinutes) {
          debugPrint(
            'UI Validation: Free day time must be within system working hours',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Free day time must be within $systemStartTime - $systemEndTime',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return;
        }

        debugPrint('Free day: Allowing time selection within system bounds');
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        setState(() {});
        _saveSchedule();
        return;
      }

      // For regular days, allow any times within system bounds
      final pickedMinutes = _timeOfDayToMinutes(picked);
      final systemStartMinutes = _timeOfDayToMinutes(systemStart);
      final systemEndMinutes = _timeOfDayToMinutes(systemEnd);

      // Validate against system working hours bounds
      if (pickedMinutes < systemStartMinutes ||
          pickedMinutes > systemEndMinutes) {
        debugPrint('UI Validation: Time must be within system working hours');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Time must be within $systemStartTime - $systemEndTime',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      debugPrint('UI Validation: Time $picked is within system working hours');
      if (isStartTime) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }

      setState(() {});
      _saveSchedule();
    }
  }

  void _saveSchedule() {
    final doctorId = context.read<AuthProvider>().user?.id;
    if (doctorId == null) return;

    final schedule = DoctorSchedule(
      id: widget.schedule?.id,
      doctorId: doctorId,
      dayOfWeek: widget.dayOfWeek,
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(_endTime),
      isActive: _isActive,
      isHoliday: _isHoliday,
      isFreeDay: _isFreeDay,
    );

    widget.onScheduleChanged(schedule);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.dayLabel,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Switch(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                    _saveSchedule();
                  },
                  activeColor: colorScheme.primary,
                ),
              ],
            ),
            if (_isActive) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Free Day',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _isFreeDay,
                    onChanged: (value) {
                      final scheduleProvider = context.read<ScheduleProvider>();

                      // Check free day limit before allowing change
                      if (value && !_isFreeDay) {
                        final freeDayCount = scheduleProvider.schedules
                            .where((s) => s.isFreeDay)
                            .length;
                        if (freeDayCount >= 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Maximum 2 free days allowed',
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                          );
                          return;
                        }
                      }

                      // Reset holiday if enabling free day
                      if (value && _isHoliday) {
                        setState(() => _isHoliday = false);
                      }

                      setState(() => _isFreeDay = value);
                      _saveSchedule();
                    },
                    activeColor: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Holiday Days',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _isHoliday,
                    onChanged: (value) {
                      final scheduleProvider = context.read<ScheduleProvider>();

                      // Check holiday limit before allowing change
                      if (value && !_isHoliday) {
                        final holidayCount = scheduleProvider.schedules
                            .where((s) => s.isHoliday)
                            .length;
                        if (holidayCount >= 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Maximum 2 holiday days allowed',
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                          );
                          return;
                        }
                      }

                      // Reset free day if enabling holiday
                      if (value && _isFreeDay) {
                        setState(() => _isFreeDay = false);
                      }

                      setState(() => _isHoliday = value);
                      _saveSchedule();
                    },
                    activeColor: Colors.red,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (_isActive) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _startTime.format(context),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Time',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _endTime.format(context),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Working hours: ${_startTime.format(context)} - ${_endTime.format(context)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_isHoliday) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_busy, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Holiday Day - No Work',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ] else if (_isFreeDay) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.beach_access, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Free Day - Custom Hours',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_busy,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Day off',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
