// lib/screens/driver/driver_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../providers/auth_provider.dart';
import '../../providers/service_assignment_provider.dart';
import '../../providers/service_provider.dart';
import '../../models/service.dart';
import '../../models/service_session.dart';
import '../../db/db_helper.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DriverHomeScreen(),
    const _AppointmentStatusScreen(),
    const _VehicleCheckScreen(),
    const _DriverProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.car_repair),
            label: 'Vehicle',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DriverHomeScreen extends StatefulWidget {
  const _DriverHomeScreen();

  @override
  State<_DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<_DriverHomeScreen> {
  Service? _selectedService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    final serviceAssignmentProvider = Provider.of<ServiceAssignmentProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await serviceProvider.loadServices();
    await serviceAssignmentProvider.loadDriverAssignments();

    // Load today's service session if exists
    final today = DateTime.now().toIso8601String().split('T')[0];
    await serviceAssignmentProvider.loadServiceSessions(
      userId: authProvider.user?.id,
      userRole: 'driver',
      sessionDate: today,
    );

    final sessions = serviceAssignmentProvider.serviceSessions;
    if (sessions.isNotEmpty) {
      final session = sessions.first;
      _selectedService = serviceProvider.services.firstWhere(
        (s) => s.id == session.selectedServiceId,
      );
    }
  }

  Future<void> _selectService(Service service) async {
    setState(() => _isLoading = true);

    final serviceAssignmentProvider = Provider.of<ServiceAssignmentProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final today = DateTime.now().toIso8601String().split('T')[0];
    final session = ServiceSession(
      userId: authProvider.user!.id!,
      userRole: 'driver',
      selectedServiceId: service.id!,
      sessionDate: today,
      isActive: true,
    );

    final success = await serviceAssignmentProvider.createServiceSession(
      session,
    );
    if (success) {
      setState(() => _selectedService = service);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final serviceAssignmentProvider = Provider.of<ServiceAssignmentProvider>(
      context,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet2U - Driver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${user?.name ?? 'Driver'}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            // Service Selection Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Service for Today',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_selectedService != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Selected: ${_selectedService!.name}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      DropdownButtonFormField<Service>(
                        decoration: const InputDecoration(
                          labelText: 'Choose Service',
                          border: OutlineInputBorder(),
                        ),
                        value: null,
                        items: serviceProvider.services
                            .where((service) => service.isActive)
                            .map(
                              (service) => DropdownMenuItem(
                                value: service,
                                child: Text(service.name),
                              ),
                            )
                            .toList(),
                        onChanged: _isLoading
                            ? null
                            : (service) {
                                if (service != null) {
                                  _selectService(service);
                                }
                              },
                      ),
                      if (_isLoading) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    title: 'Today\'s Appointments',
                    icon: const Icon(Icons.assignment, color: Colors.white),
                    color: Colors.blue,
                    subtitle: 'View today\'s work',
                    onTap: () => _navigateToAppointmentScreen(context),
                  ),
                  _DashboardCard(
                    title: 'Current Status',
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    color: Colors.green,
                    subtitle: 'Update status',
                    onTap: () => _updateStatus(context),
                  ),
                  _DashboardCard(
                    title: 'Emergency',
                    icon: const Icon(Icons.emergency, color: Colors.white),
                    color: Colors.red,
                    subtitle: 'Available',
                    onTap: () => _toggleEmergencyMode(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateStatus(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.green),
            title: const Text('On Route'),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.pause, color: Colors.orange),
            title: const Text('At Location'),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.blue),
            title: const Text('Completed'),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _toggleEmergencyMode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Mode'),
        content: const Text('Toggle emergency availability?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emergency mode toggled')),
              );
            },
            child: const Text('Toggle'),
          ),
        ],
      ),
    );
  }

  void _navigateToAppointmentScreen(BuildContext context) {
    // Navigate to the Appointments tab (index 1) in the bottom navigation
    // Since this is inside a screen that's part of a bottom navigation,
    // we need to find the parent DriverDashboard and update its index
    final driverDashboard = context
        .findAncestorWidgetOfExactType<DriverDashboard>();
    if (driverDashboard != null) {
      // This is a bit tricky since we need to access the parent state
      // For now, we'll use a simple navigation approach
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const _AppointmentStatusScreen(),
        ),
      );
    }
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final Color color;
  final String? subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: icon,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentStatusScreen extends StatefulWidget {
  const _AppointmentStatusScreen();

  @override
  State<_AppointmentStatusScreen> createState() =>
      _AppointmentStatusScreenState();
}

class _AppointmentStatusScreenState extends State<_AppointmentStatusScreen> {
  String _currentStatus = 'available';
  List<Map<String, dynamic>> _assignedAppointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignedAppointments();
  }

  Future<void> _loadAssignedAppointments() async {
    setState(() => _loading = true);

    try {
      // Get current driver ID from auth provider
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.id != null) {
        final appointments = await DBHelper.instance.getAppointments(
          driverId: authProvider.user!.id!,
          // Show all appointments assigned to this driver (confirmed, en_route, etc.)
        );

        // Filter to only today's appointments with location
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        final todayAppointments = appointments.where((apt) {
          final aptDate = DateTime.parse(apt['scheduled_at'] as String);
          return aptDate.isAfter(todayStart) &&
              aptDate.isBefore(todayEnd) &&
              apt['location_lat'] != null &&
              apt['location_lng'] != null;
        }).toList();

        // Sort by scheduled time
        todayAppointments.sort((a, b) {
          final timeA = DateTime.parse(a['scheduled_at'] as String);
          final timeB = DateTime.parse(b['scheduled_at'] as String);
          return timeA.compareTo(timeB);
        });

        setState(() {
          _assignedAppointments = todayAppointments;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s Appointments')),
      body: Column(
        children: [
          // Current Status Display
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(_currentStatus),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_currentStatus),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(_currentStatus),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          // Appointments List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _assignedAppointments.isEmpty
                ? const Center(
                    child: Text('No appointments assigned for today'),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAssignedAppointments,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _assignedAppointments.length,
                      itemBuilder: (context, index) {
                        final appointment = _assignedAppointments[index];
                        final isNext = index == 0;

                        return _AppointmentCard(
                          appointment: appointment,
                          isNext: isNext,
                          currentStatus: _currentStatus,
                          onNavigate: () => _navigateToLocation(
                            appointment['location_lat'] as double? ?? 31.9565,
                            appointment['location_lng'] as double? ?? 35.9189,
                          ),
                          onUpdateStatus: (status) => _updateAppointmentStatus(
                            status,
                            appointment['id'] as int,
                          ),
                        );
                      },
                    ),
                  ),
          ),

          // Quick Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _updateStatus('on_the_way'),
                  icon: const Icon(Icons.directions_car),
                  label: const Text('On the Way'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _updateStatus('arrived'),
                  icon: const Icon(Icons.location_on),
                  label: const Text('Arrived'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _updateStatus('completed'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLocation(double lat, double lng) {
    // TODO: Open native maps app with directions
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navigating to: $lat, $lng')));
  }

  void _updateAppointmentStatus(String status, int appointmentId) {
    // Update appointment status in database
    DBHelper.instance
        .updateAppointmentStatus(appointmentId, status)
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Appointment status updated to: $status')),
          );
          // Reload appointments to reflect changes
          _loadAssignedAppointments();
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating status: $error')),
          );
        });
  }

  void _updateStatus(String status) {
    setState(() {
      _currentStatus = status;
    });

    String message;
    switch (status) {
      case 'on_the_way':
        message = 'Status updated: On the way to appointment';
        break;
      case 'arrived':
        message = 'Status updated: Arrived at location';
        break;
      case 'completed':
        message = 'Status updated: Appointment completed';
        break;
      case 'delayed':
        message = 'Status updated: Running delayed';
        break;
      default:
        message = 'Status updated';
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.grey;
      case 'on_the_way':
        return Colors.blue;
      case 'arrived':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'delayed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'available':
        return Icons.check_circle_outline;
      case 'on_the_way':
        return Icons.directions_car;
      case 'arrived':
        return Icons.location_on;
      case 'completed':
        return Icons.check_circle;
      case 'delayed':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final bool isNext;
  final String currentStatus;
  final VoidCallback onNavigate;
  final Function(String) onUpdateStatus;

  const _AppointmentCard({
    required this.appointment,
    required this.isNext,
    required this.currentStatus,
    required this.onNavigate,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final scheduledTime = DateTime.parse(appointment['scheduled_at'] as String);
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    String eta;
    if (difference.isNegative) {
      eta = 'Overdue';
    } else if (difference.inHours > 0) {
      eta = '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      eta = '${difference.inMinutes}m';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isNext ? Colors.blue : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isNext
                        ? 'Next: ${appointment['service_type']}'
                        : '${appointment['service_type']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              appointment['address'] ?? 'Address not provided',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Doctor: ${appointment['doctor_name'] ?? 'Not assigned'}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            Text(
              'Owner: ${appointment['owner_name'] ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            Text(
              'Driver: ${appointment['driver_name'] ?? 'Not assigned'}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ETA: $eta',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Distance: ~5 km', // Placeholder - would calculate real distance
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onUpdateStatus('en_route'),
                    child: const Text('Start Route'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCheckScreen extends StatelessWidget {
  const _VehicleCheckScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Check')),
      body: const Center(child: Text('Vehicle Check Screen - Coming Soon')),
    );
  }
}

class _DriverProfileScreen extends StatelessWidget {
  const _DriverProfileScreen();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.drive_eta, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('Name: ${user?.name ?? 'N/A'}'),
            Text('Email: ${user?.email ?? 'N/A'}'),
            Text('Phone: ${user?.phone ?? 'N/A'}'),
            Text('Role: ${user?.role ?? 'driver'}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => authProvider.logout(),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
