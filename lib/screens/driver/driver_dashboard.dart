// lib/screens/driver/driver_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/appointment.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loadingAssignments = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignments();
    });
  }

  Future<void> _loadAssignments() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user?.id == null) return;
    setState(() => _loadingAssignments = true);
    await context
        .read<AppointmentProvider>()
        .loadDriverAppointments(user!.id!);
    setState(() => _loadingAssignments = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet2U - Driver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh assignments',
            onPressed: _loadAssignments,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.route), text: 'Today'),
            Tab(icon: Icon(Icons.list_alt), text: 'All'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
          ],
        ),
      ),
      body: _loadingAssignments
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _RouteTab(filterToday: true, onOpenMap: _openMap),
                _RouteTab(filterToday: false, onOpenMap: _openMap),
                _DriverProfileTab(driverName: user?.name ?? 'Driver'),
              ],
            ),
    );
  }

  Future<void> _openMap(Appointment appointment) async {
    String? url;
    if (appointment.locationLat != null && appointment.locationLng != null) {
      url =
          'https://www.google.com/maps/dir/?api=1&destination=${appointment.locationLat},${appointment.locationLng}';
    } else if ((appointment.address ?? '').isNotEmpty) {
      url =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(appointment.address!)}';
    }
    if (url != null && await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open maps for this stop')),
      );
    }
  }
}

class _RouteTab extends StatelessWidget {
  final bool filterToday;
  final Future<void> Function(Appointment appointment) onOpenMap;

  const _RouteTab({
    required this.filterToday,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        if (appointmentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignments = _optimiseRoute(
          appointmentProvider.appointments,
          filterToday: filterToday,
        );

        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filterToday ? Icons.map_outlined : Icons.inbox,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  filterToday
                      ? 'No scheduled visits for today'
                      : 'No assignments available',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final authProvider = context.read<AuthProvider>();
            if (authProvider.user?.id != null) {
              await context
                  .read<AppointmentProvider>()
                  .loadDriverAppointments(authProvider.user!.id!);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final appointment = assignments[index];
              return _RouteStopCard(
                appointment: appointment,
                onOpenMap: () => onOpenMap(appointment),
              );
            },
          ),
        );
      },
    );
  }

  List<Appointment> _optimiseRoute(
    List<Appointment> appointments, {
    required bool filterToday,
  }) {
    final now = DateTime.now();
    final urgencyOrder = {'emergency': 0, 'urgent': 1, 'routine': 2};
    final filtered = appointments.where((appointment) {
      final scheduled = DateTime.tryParse(appointment.scheduledAt)?.toLocal();
      if (scheduled == null) return false;
      if (!filterToday) return true;
      return scheduled.year == now.year &&
          scheduled.month == now.month &&
          scheduled.day == now.day;
    }).toList();

    filtered.sort((a, b) {
      final aPriority = urgencyOrder[a.urgencyLevel] ?? 3;
      final bPriority = urgencyOrder[b.urgencyLevel] ?? 3;
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      final aDate = DateTime.tryParse(a.scheduledAt) ?? DateTime.now();
      final bDate = DateTime.tryParse(b.scheduledAt) ?? DateTime.now();
      return aDate.compareTo(bDate);
    });

    return filtered;
  }
}

class _RouteStopCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onOpenMap;

  const _RouteStopCard({
    required this.appointment,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppointmentProvider>();
    final scheduled = DateTime.tryParse(appointment.scheduledAt)?.toLocal();
    final subtitle = scheduled != null
        ? '${_formatDate(scheduled)} • ${_formatTime(scheduled)}'
        : appointment.scheduledAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _urgencyColor(appointment.urgencyLevel),
                  child: Text(appointment.urgencyLevel[0].toUpperCase()),
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
                      const SizedBox(height: 4),
                      Text(subtitle),
                      if ((appointment.address ?? '').isNotEmpty)
                        Text(
                          appointment.address!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        _statusColor(appointment.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appointment.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(appointment.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (appointment.ownerName != null)
              Text('Owner: ${appointment.ownerName}'),
            if (appointment.ownerPhone != null)
              Text('Contact: ${appointment.ownerPhone}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onOpenMap,
                  icon: const Icon(Icons.map),
                  label: const Text('Open in Maps'),
                ),
                if (_canStartRoute(appointment.status))
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(
                      context,
                      provider,
                      appointment,
                      'en_route',
                    ),
                    icon: const Icon(Icons.directions_car),
                    label: const Text('Start route'),
                  ),
                if (appointment.status == 'en_route')
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(
                      context,
                      provider,
                      appointment,
                      'in_progress',
                    ),
                    icon: const Icon(Icons.place),
                    label: const Text('Arrived'),
                  ),
                if (appointment.status == 'in_progress')
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(
                      context,
                      provider,
                      appointment,
                      'completed',
                    ),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete visit'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canStartRoute(String status) {
    return status == 'confirmed' || status == 'rescheduled' || status == 'pending';
  }

  Future<void> _updateStatus(
    BuildContext context,
    AppointmentProvider provider,
    Appointment appointment,
    String status,
  ) async {
    final success = await provider.updateDriverProgress(appointment.id!, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Status updated to ${status.replaceAll('_', ' ')}'
                : 'Failed to update status',
          ),
        ),
      );
    }
  }

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'emergency':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'en_route':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.hour}:$minutes';
  }
}

class _DriverProfileTab extends StatelessWidget {
  final String driverName;

  const _DriverProfileTab({required this.driverName});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        final completed = appointmentProvider.appointments
            .where((a) => a.status == 'completed')
            .length;
        final active = appointmentProvider.appointments
            .where((a) => a.status != 'completed' && a.status != 'cancelled')
            .length;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Name: $driverName'),
                    const SizedBox(height: 4),
                    Text('Active assignments: $active'),
                    Text('Completed visits: $completed'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Tips for a great day',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Check urgent requests first'),
                    Text('• Share ETA updates via the appointment actions'),
                    Text('• Keep vaccines refrigerated during transit'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
