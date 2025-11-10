// lib/screens/doctor/appointment_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_provider.dart';
import '../../models/appointment.dart';
import '../../models/medical_record.dart';
import '../../models/user.dart';
import '../../db/db_helper.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends State<AppointmentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.id != null) {
        // Load appointments assigned to this doctor
        context.read<AppointmentProvider>().loadAppointments(
          doctorId: authProvider.user!.id!,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'Upcoming', icon: Icon(Icons.schedule)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sorted by date & time',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Appointments are automatically sorted by date and time',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList('today'),
          _buildAppointmentList('upcoming'),
          _buildAppointmentList('completed'),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(String filter) {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        if (appointmentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter appointments based on status and date
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final appointments =
            appointmentProvider.appointments.where((apt) {
                final aptDate = DateTime.parse(apt.scheduledAt).toLocal();
                final aptDateOnly = DateTime(
                  aptDate.year,
                  aptDate.month,
                  aptDate.day,
                );

                switch (filter) {
                  case 'today':
                    return aptDateOnly == today;
                  case 'upcoming':
                    return aptDateOnly.isAfter(today);
                  case 'completed':
                    return apt.status == 'completed';
                  default:
                    return true;
                }
              }).toList()
              // Sort appointments by date and time (earliest first)
              ..sort((a, b) {
                final aDate = DateTime.parse(a.scheduledAt);
                final bDate = DateTime.parse(b.scheduledAt);
                return aDate.compareTo(bDate);
              });

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filter == 'completed'
                      ? Icons.check_circle_outline
                      : Icons.schedule,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${filter} appointments',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return _AppointmentCard(
              appointment: appointment,
              onAccept: () => _acceptAppointment(appointment),
              onReschedule: () => _rescheduleAppointment(appointment),
              onReject: () => _rejectAppointment(appointment),
              onComplete: () => _completeAppointment(appointment),
            );
          },
        );
      },
    );
  }

  void _acceptAppointment(Appointment appointment) async {
    final authProvider = context.read<AuthProvider>();
    final success = await context
        .read<AppointmentProvider>()
        .updateAppointmentStatus(
          appointment.id!,
          'confirmed',
          doctorId: authProvider.user!.id!,
        );
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Appointment accepted')));
    }
  }

  Future<void> _rescheduleAppointment(Appointment appointment) async {
    final newDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => _RescheduleDialog(initial: appointment.scheduledAt),
    );

    if (newDate != null) {
      final success = await context
          .read<AppointmentProvider>()
          .rescheduleAppointment(appointment.id!, newDate);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment rescheduled')),
        );
      }
    }
  }

  void _rejectAppointment(Appointment appointment) async {
    final success = await context
        .read<AppointmentProvider>()
        .updateAppointmentStatus(appointment.id!, 'cancelled');
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Appointment rejected')));
    }
  }

  Future<void> _dispatchDriver(Appointment appointment) async {
    final driversData = await DBHelper.instance.getAllUsers(role: 'driver');
    if (driversData.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No drivers available to dispatch')),
      );
      return;
    }

    final drivers = driversData.map(User.fromMap).toList();
    final selectedId = await showDialog<int>(
      context: context,
      builder: (context) => _DriverSelectionDialog(drivers: drivers),
    );

    if (selectedId != null) {
      final selectedDriver =
          drivers.firstWhere((driver) => driver.id == selectedId);
      final success = await context
          .read<AppointmentProvider>()
          .assignDriverToAppointment(
            appointment.id!,
            selectedId,
            dispatchImmediately: true,
            driverName: selectedDriver.name,
            driverPhone: selectedDriver.phone,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver dispatched successfully')),
        );
      }
    }
  }

  void _completeAppointment(Appointment appointment) async {
    // Show treatment recording dialog before marking complete
    final treatmentDetails = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _TreatmentCompletionDialog(appointment: appointment),
    );

    if (treatmentDetails != null) {
      // Mark appointment as completed
      final success = await context
          .read<AppointmentProvider>()
          .updateAppointmentStatus(appointment.id!, 'completed');

      if (success) {
        // Create treatment record
        final medicalProvider = context.read<MedicalProvider>();
        final authProvider = context.read<AuthProvider>();

        final record = MedicalRecord(
          petId: appointment.petId,
          doctorId: authProvider.user!.id!,
          diagnosis: treatmentDetails['diagnosis'] ?? '',
          treatment: treatmentDetails['treatment'] ?? '',
          prescription: treatmentDetails['prescription']?.isEmpty ?? true
              ? null
              : treatmentDetails['prescription'],
          notes: treatmentDetails['notes']?.isEmpty ?? true
              ? null
              : treatmentDetails['notes'],
          date: DateTime.now().toIso8601String(),
        );

        final recordSuccess = await medicalProvider.addMedicalRecord(record);

        if (recordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment completed and treatment record saved'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Appointment completed but failed to save treatment record',
              ),
            ),
          );
        }
      }
    }
  }
}

class _RescheduleDialog extends StatefulWidget {
  final String? initial;

  const _RescheduleDialog({this.initial});

  @override
  State<_RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<_RescheduleDialog> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    final parsed = widget.initial != null
        ? DateTime.tryParse(widget.initial!)?.toLocal()
        : null;
    if (parsed != null) {
      _selectedDate = parsed;
      _selectedTime = TimeOfDay.fromDateTime(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reschedule appointment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text('Date: ${_selectedDate.toLocal().toString().split(' ').first}'),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text('Time: ${_selectedTime.format(context)}'),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final result = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );
            Navigator.pop(context, result);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _DriverSelectionDialog extends StatelessWidget {
  final List<User> drivers;

  const _DriverSelectionDialog({required this.drivers});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign mobile clinic driver'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];
            return ListTile(
              leading: const Icon(Icons.directions_car),
              title: Text(driver.name),
              subtitle: driver.phone != null ? Text(driver.phone!) : null,
              onTap: () => Navigator.pop(context, driver.id),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _TreatmentCompletionDialog extends StatefulWidget {
  final Appointment appointment;

  const _TreatmentCompletionDialog({required this.appointment});

  @override
  State<_TreatmentCompletionDialog> createState() =>
      _TreatmentCompletionDialogState();
}

class _TreatmentCompletionDialogState
    extends State<_TreatmentCompletionDialog> {
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Appointment & Record Treatment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment: ${widget.appointment.serviceType}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Diagnosis *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _treatmentController,
              decoration: const InputDecoration(
                labelText: 'Treatment Provided *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prescriptionController,
              decoration: const InputDecoration(
                labelText: 'Prescription (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_diagnosisController.text.isEmpty ||
                _treatmentController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill in diagnosis and treatment'),
                ),
              );
              return;
            }

            Navigator.of(context).pop({
              'diagnosis': _diagnosisController.text,
              'treatment': _treatmentController.text,
              'prescription': _prescriptionController.text,
              'notes': _notesController.text,
            });
          },
          child: const Text('Complete & Save'),
        ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onAccept;
  final VoidCallback onReschedule;
  final VoidCallback onReject;
  final VoidCallback onComplete;
  final VoidCallback onDispatch;

  const _AppointmentCard({
    required this.appointment,
    required this.onAccept,
    required this.onReschedule,
    required this.onReject,
    required this.onComplete,
    required this.onDispatch,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(appointment.status);
    final statusIcon = _getStatusIcon(appointment.status);
    final scheduled = DateTime.tryParse(appointment.scheduledAt)?.toLocal();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.serviceType,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        scheduled != null
                            ? 'Scheduled ${scheduled.toString().split('.').first}'
                            : 'Scheduled: ${appointment.scheduledAt}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (appointment.address != null &&
                          appointment.address!.isNotEmpty)
                        Text(
                          'Location: ${appointment.address}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      if (appointment.ownerName != null)
                        Text('Owner: ${appointment.ownerName}'),
                      if (appointment.ownerPhone != null)
                        Text('Contact: ${appointment.ownerPhone}'),
                      if (appointment.driverName != null)
                        Text('Driver: ${appointment.driverName}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (appointment.description != null &&
                appointment.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                appointment.description!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (appointment.status == 'pending') ...[
                  ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onReschedule,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Reschedule'),
                  ),
                  TextButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject'),
                  ),
                ],
                if (appointment.status == 'confirmed' ||
                    appointment.status == 'en_route' ||
                    appointment.status == 'in_progress')
                  ElevatedButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark complete'),
                  ),
                if (appointment.driverId == null &&
                    appointment.urgencyLevel != 'routine')
                  OutlinedButton.icon(
                    onPressed: onDispatch,
                    icon: const Icon(Icons.directions_car),
                    label: const Text('Dispatch driver'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
