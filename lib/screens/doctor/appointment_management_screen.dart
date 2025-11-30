// lib/screens/doctor/appointment_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_provider.dart';
import '../../models/appointment.dart';
import '../../models/medical_record.dart';
import '../select_location_screen.dart';

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
              onUpdateLocation: () => _updateAppointmentLocation(appointment),
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
          'accepted',
          doctorId: authProvider.user!.id!,
        );
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Appointment accepted')));
    }
  }

  void _rescheduleAppointment(Appointment appointment) {
    // TODO: Implement reschedule dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reschedule feature coming soon')),
    );
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

  void _updateAppointmentLocation(Appointment appointment) async {
    // Navigate to select location screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectLocationScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      final lat = result['latitude'] as double?;
      final lng = result['longitude'] as double?;
      final address = result['address'] as String?;

      if (lat != null && lng != null) {
        final updatedAppointment = appointment.copyWith(
          locationLat: lat,
          locationLng: lng,
          address: address,
        );

        final success = await context
            .read<AppointmentProvider>()
            .updateAppointment(updatedAppointment);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location updated successfully')),
          );
          // Reload appointments
          final authProvider = context.read<AuthProvider>();
          if (authProvider.user?.id != null) {
            context.read<AppointmentProvider>().loadAppointments(
              doctorId: authProvider.user!.id!,
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update location')),
          );
        }
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
  final VoidCallback onUpdateLocation;

  const _AppointmentCard({
    required this.appointment,
    required this.onAccept,
    required this.onReschedule,
    required this.onReject,
    required this.onComplete,
    required this.onUpdateLocation,
  });
  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(appointment.status);
    final statusIcon = _getStatusIcon(appointment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        'Scheduled: ${appointment.scheduledAt}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (appointment.address != null)
                        Text(
                          'Location: ${appointment.address}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
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
                'Description: ${appointment.description}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (appointment.locationLat == null ||
                    appointment.locationLng == null) ...[
                  TextButton(
                    onPressed: onUpdateLocation,
                    child: const Text('Set Location'),
                  ),
                ],
                if (appointment.status == 'pending') ...[
                  TextButton(onPressed: onAccept, child: const Text('Accept')),
                  TextButton(
                    onPressed: onReschedule,
                    child: const Text('Reschedule'),
                  ),
                  TextButton(
                    onPressed: onReject,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ] else if (appointment.status == 'confirmed' ||
                    appointment.status == 'en_route' ||
                    appointment.status == 'in_progress') ...[
                  ElevatedButton(
                    onPressed: onComplete,
                    child: const Text('Mark Complete'),
                  ),
                ],
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
      case 'accepted':
        return Colors.teal;
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
      case 'accepted':
        return Icons.thumb_up;
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
