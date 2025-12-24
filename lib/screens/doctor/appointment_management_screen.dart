// lib/screens/doctor/appointment_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/appointment.dart';
import '../../models/medical_record.dart';
import '../select_location_screen.dart';
import '../../../translations.dart';
import '../../../translations/translations.dart';
import '../../l10n/app_localizations.dart';
import 'package:get/get.dart' hide Translations;

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
        title: Text(AppLocalizations.of(context)!.appointmentManagement),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: AppLocalizations.of(context)!.today,
              icon: Icon(Icons.today),
            ),
            Tab(
              text: AppLocalizations.of(context)!.upcoming,
              icon: Icon(Icons.schedule),
            ),
            Tab(
              text: AppLocalizations.of(context)!.completed,
              icon: Icon(Icons.check_circle),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: AppLocalizations.of(context)!.sortedByDateTime,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.appointmentsAutoSorted,
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
                  AppLocalizations.of(
                    context,
                  )!.noAppointments.replaceAll('{filter}', filter),
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
              onStart: () => _startAppointment(appointment),
              onComplete: () => _completeAppointment(appointment),
              onUpdateLocation: () => _updateAppointmentLocation(appointment),
              onMarkPaymentReceived: () => _markPaymentReceived(appointment),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.appointmentAccepted),
        ),
      );
    }
  }

  void _startAppointment(Appointment appointment) async {
    final success = await context
        .read<AppointmentProvider>()
        .updateAppointmentStatus(appointment.id!, 'confirmed');
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.appointmentStarted),
        ),
      );
    }
  }

  void _rescheduleAppointment(Appointment appointment) {
    // TODO: Implement reschedule dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.rescheduleComingSoon),
      ),
    );
  }

  void _rejectAppointment(Appointment appointment) async {
    final success = await context
        .read<AppointmentProvider>()
        .updateAppointmentStatus(appointment.id!, 'cancelled');
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.appointmentRejected),
        ),
      );
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
            SnackBar(
              content: Text(AppLocalizations.of(context)!.locationUpdated),
            ),
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
            SnackBar(
              content: Text(AppLocalizations.of(context)!.locationUpdateFailed),
            ),
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
      // For cash payments, process payment first and set status to 'paid'
      if (appointment.paymentMethod == 'cash') {
        final paymentProvider = context.read<PaymentProvider>();
        final payments = await paymentProvider.getPaymentsByAppointment(
          appointment.id!,
        );
        final pendingPayment = payments
            .where((p) => p.status == 'pending')
            .firstOrNull;
        if (pendingPayment != null) {
          final paymentSuccess = await paymentProvider.processCashPayment(
            pendingPayment.id!,
          );
          if (paymentSuccess) {
            // Set status to 'paid' after successful payment processing
            await context.read<AppointmentProvider>().updateAppointmentStatus(
              appointment.id!,
              'paid',
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.paymentProcessingFailed,
                ),
              ),
            );
            return;
          }
        }
      }

      // Mark appointment as completed (for online, it's already 'paid')
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
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.appointmentCompletedRecordSaved,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.appointmentCompletedRecordFailed,
              ),
            ),
          );
        }
      }
    }
  }

  void _markPaymentReceived(Appointment appointment) async {
    if (appointment.paymentMethod != 'cash') return;

    final paymentProvider = context.read<PaymentProvider>();
    final payments = await paymentProvider.getPaymentsByAppointment(
      appointment.id!,
    );
    final pendingPayment = payments
        .where((p) => p.status == 'pending')
        .firstOrNull;
    if (pendingPayment != null) {
      final success = await paymentProvider.processCashPayment(
        pendingPayment.id!,
      );
      if (success) {
        // Set status to 'paid'
        await context.read<AppointmentProvider>().updateAppointmentStatus(
          appointment.id!,
          'paid',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.paymentMarkedAsReceived,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.paymentProcessingFailedGeneral,
            ),
          ),
        );
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
      title: Text(
        AppLocalizations.of(context)!.completeAppointmentAndRecordTreatment,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)!.appointmentServiceType}: ${widget.appointment.serviceType}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _diagnosisController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.diagnosisRequired,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _treatmentController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                )!.treatmentProvidedRequired,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prescriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                )!.prescriptionOptionalShort,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.additionalNotes,
                border: const OutlineInputBorder(),
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
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      context,
                    )!.pleaseFillInDiagnosisAndTreatment,
                  ),
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
          child: Text(AppLocalizations.of(context)!.completeAndSave),
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
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onUpdateLocation;
  final VoidCallback onMarkPaymentReceived;

  const _AppointmentCard({
    required this.appointment,
    required this.onAccept,
    required this.onReschedule,
    required this.onReject,
    required this.onStart,
    required this.onComplete,
    required this.onUpdateLocation,
    required this.onMarkPaymentReceived,
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
                        '${AppLocalizations.of(context)!.scheduledAt}: ${appointment.scheduledAt}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (appointment.address != null)
                        Text(
                          '${AppLocalizations.of(context)!.locationLabel}: ${appointment.address}',
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
                '${AppLocalizations.of(context)!.descriptionLabel}: ${appointment.description}',
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
                    child: Text(AppLocalizations.of(context)!.setLocation),
                  ),
                ],
                if (appointment.status == 'pending') ...[
                  TextButton(
                    onPressed: onAccept,
                    child: Text(AppLocalizations.of(context)!.accept),
                  ),
                  TextButton(
                    onPressed: onReschedule,
                    child: Text(AppLocalizations.of(context)!.reschedule),
                  ),
                  TextButton(
                    onPressed: onReject,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text(AppLocalizations.of(context)!.reject),
                  ),
                ] else if (appointment.status == 'accepted') ...[
                  ElevatedButton(
                    onPressed: onStart,
                    child: Text(AppLocalizations.of(context)!.startAppointment),
                  ),
                ] else if (appointment.status == 'confirmed' ||
                    appointment.status == 'en_route' ||
                    appointment.status == 'in_progress' ||
                    appointment.status == 'paid') ...[
                  ElevatedButton(
                    onPressed: onComplete,
                    child: Text(AppLocalizations.of(context)!.markComplete),
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
      case 'en_route':
        return Colors.lightBlue;
      case 'arrived':
        return Colors.indigo;
      case 'waiting':
        return Colors.amber;
      case 'on_hold':
        return Colors.deepOrange;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'no_show':
        return Colors.redAccent;
      case 'rescheduled':
        return Colors.cyan;
      case 'delayed':
        return Colors.brown;
      case 'paid':
        return Colors.green.shade700;
      case 'refunded':
        return Colors.orange.shade700;
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
      case 'en_route':
        return Icons.directions_car;
      case 'arrived':
        return Icons.location_on;
      case 'waiting':
        return Icons.hourglass_empty;
      case 'on_hold':
        return Icons.pause_circle;
      case 'in_progress':
        return Icons.work;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      case 'no_show':
        return Icons.person_off;
      case 'rescheduled':
        return Icons.event_repeat;
      case 'delayed':
        return Icons.access_time;
      case 'paid':
        return Icons.payment;
      case 'refunded':
        return Icons.undo;
      default:
        return Icons.help;
    }
  }
}
