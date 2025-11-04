// lib/screens/driver/driver_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../providers/auth_provider.dart';
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
    const _RouteNavigationScreen(),
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
            icon: Icon(Icons.navigation),
            label: 'Routes',
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

class _DriverHomeScreen extends StatelessWidget {
  const _DriverHomeScreen();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

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
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    title: 'Today\'s Route',
                    icon: const Icon(Icons.route, color: Colors.white),
                    color: Colors.blue,
                    subtitle: '3 stops remaining',
                    onTap: () => _navigateToRouteScreen(context),
                  ),
                  _DashboardCard(
                    title: 'Current Status',
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    color: Colors.green,
                    subtitle: 'On Route',
                    onTap: () => _updateStatus(context),
                  ),
                  _DashboardCard(
                    title: 'Next Appointment',
                    icon: const Icon(Icons.schedule, color: Colors.white),
                    color: Colors.orange,
                    subtitle: 'View Routes',
                    onTap: () => _navigateToRouteScreen(context),
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

  void _navigateToRouteScreen(BuildContext context) {
    // Navigate to the Routes tab (index 1) in the bottom navigation
    // Since this is inside a screen that's part of a bottom navigation,
    // we need to find the parent DriverDashboard and update its index
    final driverDashboard = context
        .findAncestorWidgetOfExactType<DriverDashboard>();
    if (driverDashboard != null) {
      // This is a bit tricky since we need to access the parent state
      // For now, we'll use a simple navigation approach
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const _RouteNavigationScreen()),
      );
    }
  }

  void _navigateToAppointmentScreen(BuildContext context) {
    // Navigate to the Routes tab (index 1) since we removed the Appointments tab
    _navigateToRouteScreen(context);
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

class _RouteNavigationScreen extends StatefulWidget {
  const _RouteNavigationScreen();

  @override
  State<_RouteNavigationScreen> createState() => _RouteNavigationScreenState();
}

class _RouteNavigationScreenState extends State<_RouteNavigationScreen> {
  String _currentStatus = 'available';
  double? _currentLat;
  double? _currentLng;
  bool _isTracking = false;
  List<Map<String, dynamic>> _assignedAppointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllAssignedAppointments(); // Load all assigned appointments from database
    _startLocationTracking();
  }

  Future<void> _loadAssignedAppointments() async {
    setState(() => _loading = true);

    try {
      // Get current driver ID from auth provider
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.id != null) {
        final appointments = await DBHelper.instance.getAppointments(
          driverId: authProvider.user!.id!,
          // Remove status filter to show ALL appointments assigned to this driver
        );

        // Convert to appointment objects and filter by today's date
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        final todayAppointments = appointments.where((apt) {
          final aptDate = DateTime.parse(apt['scheduled_at'] as String);
          return aptDate.isAfter(todayStart) && aptDate.isBefore(todayEnd);
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

  Future<void> _loadAllAssignedAppointments() async {
    setState(() => _loading = true);

    try {
      // Get current driver ID from auth provider
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.id != null) {
        final appointments = await DBHelper.instance.getAppointments(
          driverId: authProvider.user!.id!,
          // Remove status filter to show ALL appointments assigned to this driver
        );

        // Sort by scheduled time (no date filter - show all assigned)
        appointments.sort((a, b) {
          final timeA = DateTime.parse(a['scheduled_at'] as String);
          final timeB = DateTime.parse(b['scheduled_at'] as String);
          return timeA.compareTo(timeB);
        });

        setState(() {
          _assignedAppointments = appointments;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _startLocationTracking() async {
    // TODO: Implement real GPS tracking using LocationService
    setState(() {
      _isTracking = true;
      _currentLat = 31.963158; // Example coordinates (Amman, Jordan)
      _currentLng = 35.930359;
    });

    // Start automatic status updates based on location
    _startAutomaticStatusUpdates();
  }

  void _startAutomaticStatusUpdates() {
    // Check location every 30 seconds and update status automatically
    // This simulates Uber-like automatic status updates
    // In real implementation, this would use geofencing and continuous location monitoring

    // For now, we'll simulate automatic status updates based on proximity
    // In a real app, this would use background location services and geofencing
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _isTracking) {
        _checkProximityAndUpdateStatus();
        _startAutomaticStatusUpdates(); // Continue checking
      }
    });
  }

  void _checkProximityAndUpdateStatus() {
    // Check if driver is close to any appointment location
    for (final appointment in _assignedAppointments) {
      final aptLat = appointment['location_lat'] as double?;
      final aptLng = appointment['location_lng'] as double?;

      if (aptLat != null &&
          aptLng != null &&
          _currentLat != null &&
          _currentLng != null) {
        final distance = _calculateRealDistance(
          _currentLat!,
          _currentLng!,
          aptLat,
          aptLng,
        );

        // If within 100 meters of appointment location and status is 'en_route', auto-update to 'arrived'
        if (distance < 0.1 && _currentStatus == 'en_route') {
          // 100 meters
          _updateStatus('arrived');
          break;
        }
      }
    }
  }

  double _calculateRealDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    // Haversine formula for more accurate distance calculation
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = (lat2 - lat1) * (3.141592653589793 / 180);
    final double dLng = (lng2 - lng1) * (3.141592653589793 / 180);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c; // Distance in kilometers
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Navigation'),
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.location_on : Icons.location_off),
            onPressed: () {
              setState(() {
                _isTracking = !_isTracking;
                if (_isTracking) {
                  _startLocationTracking();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status and Location Display
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status: ${_currentStatus.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_currentStatus),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _currentStatus.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_currentLat != null && _currentLng != null)
                  Text(
                    'Location: ${_currentLat!.toStringAsFixed(6)}, ${_currentLng!.toStringAsFixed(6)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),

          // Route List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _assignedAppointments.isEmpty
                ? const Center(child: Text('No appointments assigned to you'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _assignedAppointments.length,
                    itemBuilder: (context, index) {
                      final appointment = _assignedAppointments[index];
                      final isNext = index == 0;
                      final status = isNext ? 'next' : 'upcoming';

                      // Calculate ETA and distance (simplified)
                      final eta = _calculateETA(appointment);
                      final distance = _calculateDistance(appointment);

                      return _RouteStopCard(
                        title: isNext
                            ? 'Next Stop: ${appointment['service_type']}'
                            : '${appointment['service_type']}',
                        address:
                            appointment['address'] ?? 'Address not provided',
                        eta: eta,
                        distance: _shouldShowLocation(appointment)
                            ? distance
                            : 'N/A',
                        status: status,
                        onNavigate: _shouldShowLocation(appointment)
                            ? () => _navigateToLocation(
                                appointment['location_lat'] as double? ??
                                    31.9565,
                                appointment['location_lng'] as double? ??
                                    35.9189,
                              )
                            : () {},
                        onUpdateStatus: () => _updateAppointmentStatus(
                          'en_route',
                          appointment['id'] as int,
                        ),
                      );
                    },
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
          _loadAllAssignedAppointments();
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating status: $error')),
          );
        });
  }

  String _calculateETA(Map<String, dynamic> appointment) {
    final scheduledTime = DateTime.parse(appointment['scheduled_at'] as String);
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  String _calculateDistance(Map<String, dynamic> appointment) {
    // Simplified distance calculation - in real app would use GPS coordinates
    final lat = appointment['location_lat'] as double?;
    final lng = appointment['location_lng'] as double?;

    if (lat != null &&
        lng != null &&
        _currentLat != null &&
        _currentLng != null) {
      // Simple Euclidean distance approximation
      final distance =
          ((lat - _currentLat!) * (lat - _currentLat!) +
                  (lng - _currentLng!) * (lng - _currentLng!))
              .abs();
      return '${(distance * 111).toStringAsFixed(1)} km'; // Rough km conversion
    }
    return 'Distance unknown';
  }

  bool _shouldShowLocation(Map<String, dynamic> appointment) {
    // Only show location/distance for today's appointments
    final appointmentDate = DateTime.parse(
      appointment['scheduled_at'] as String,
    );
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return appointmentDate.isAfter(todayStart) &&
        appointmentDate.isBefore(todayEnd);
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
        return Colors.green;
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
}

class _RouteStopCard extends StatelessWidget {
  final String title;
  final String address;
  final String eta;
  final String distance;
  final String status;
  final VoidCallback onNavigate;
  final VoidCallback onUpdateStatus;

  const _RouteStopCard({
    required this.title,
    required this.address,
    required this.eta,
    required this.distance,
    required this.status,
    required this.onNavigate,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (status) {
      case 'next':
        statusColor = Colors.blue;
        break;
      case 'upcoming':
        statusColor = Colors.grey;
        break;
      case 'emergency':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
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
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(address, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ETA: $eta',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Distance: $distance',
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
                    onPressed: onUpdateStatus,
                    child: const Text('Update Status'),
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
