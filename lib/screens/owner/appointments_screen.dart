// lib/screens/owner/appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/appointment.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.id != null) {
        // Load appointments for this owner
        context.read<AppointmentProvider>().loadAppointments(
          ownerId: authProvider.user!.id!,
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
        title: const Text('My Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming', icon: Icon(Icons.schedule)),
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'Past', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList('upcoming'),
          _buildAppointmentList('today'),
          _buildAppointmentList('past'),
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

        final appointments = appointmentProvider.appointments.where((apt) {
          final aptDate = DateTime.parse(apt.scheduledAt).toLocal();
          final aptDateOnly = DateTime(
            aptDate.year,
            aptDate.month,
            aptDate.day,
          );

          switch (filter) {
            case 'today':
              return aptDateOnly == today &&
                  (apt.status != 'completed' && apt.status != 'cancelled');
            case 'upcoming':
              return aptDateOnly.isAfter(today) &&
                  (apt.status != 'completed' && apt.status != 'cancelled');
            case 'past':
              return apt.status == 'completed' || apt.status == 'cancelled';
            default:
              return true;
          }
        }).toList();

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filter == 'past' ? Icons.history : Icons.schedule,
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
              onCancel: () => _cancelAppointment(appointment),
            );
          },
        );
      },
    );
  }

  void _cancelAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context
          .read<AppointmentProvider>()
          .updateAppointmentStatus(appointment.id!, 'cancelled');
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appointment cancelled')));
      }
    }
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onCancel;

  const _AppointmentCard({required this.appointment, required this.onCancel});

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
                        'Scheduled: ${_formatDateTime(appointment.scheduledAt)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (appointment.doctorName != null)
                        Text(
                          'Doctor: ${appointment.doctorName}',
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
            if (appointment.price != null) ...[
              const SizedBox(height: 8),
              Text(
                'Price: \$${appointment.price!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (appointment.status == 'pending') ...[
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final appointmentDate = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
      );

      String dateStr;
      if (appointmentDate == today) {
        dateStr = 'Today';
      } else if (appointmentDate == tomorrow) {
        dateStr = 'Tomorrow';
      } else {
        dateStr = '${dateTime.month}/${dateTime.day}/${dateTime.year}';
      }

      final timeStr =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      return '$dateStr at $timeStr';
    } catch (e) {
      return dateTimeString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'en_route':
        return Colors.purple;
      case 'in_progress':
        return Colors.indigo;
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
      case 'en_route':
        return Icons.directions_car;
      case 'in_progress':
        return Icons.work;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
