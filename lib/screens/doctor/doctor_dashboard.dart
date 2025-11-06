// lib/screens/doctor/doctor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_assignment_provider.dart';
import '../../providers/service_provider.dart';
import '../../models/service.dart';
import '../../models/service_session.dart';
import 'appointment_management_screen.dart';
import 'treatment_recording_screen.dart';
import 'inventory_management_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DoctorHomeScreen(),
    const AppointmentManagementScreen(),
    const TreatmentRecordingScreen(),
    const InventoryManagementScreen(),
    const _DoctorProfileScreen(),
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
            icon: Icon(Icons.schedule),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Treatments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DoctorHomeScreen extends StatefulWidget {
  const _DoctorHomeScreen();

  @override
  State<_DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<_DoctorHomeScreen> {
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
    await serviceAssignmentProvider.loadDoctors();

    // Load today's service session if exists
    final today = DateTime.now().toIso8601String().split('T')[0];
    await serviceAssignmentProvider.loadServiceSessions(
      userId: authProvider.user?.id,
      userRole: 'doctor',
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
      userRole: 'doctor',
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
        title: const Text('Vet2U - Doctor'),
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
              'Welcome back, Dr. ${user?.name ?? 'Doctor'}!',
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
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    color: Colors.blue,
                    count: '5', // TODO: Get from provider
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const AppointmentManagementScreen(),
                      ),
                    ),
                  ),
                  _DashboardCard(
                    title: 'Pending Reviews',
                    icon: const Icon(Icons.pending, color: Colors.white),
                    color: Colors.orange,
                    count: '3', // TODO: Get from provider
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TreatmentRecordingScreen(),
                      ),
                    ),
                  ),
                  _DashboardCard(
                    title: 'Low Stock Alerts',
                    icon: const Icon(Icons.warning, color: Colors.white),
                    color: Colors.red,
                    count: '2', // TODO: Get from provider
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const InventoryManagementScreen(),
                      ),
                    ),
                  ),
                  _DashboardCard(
                    title: 'Emergency Queue',
                    icon: const Icon(Icons.emergency, color: Colors.white),
                    color: Colors.red,
                    count: '1', // TODO: Get from provider
                    onTap: () => _showEmergencyQueue(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyQueue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Cases'),
        content: const Text('View and manage emergency appointments'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final Color color;
  final String? count;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    this.count,
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
              if (count != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count!,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorProfileScreen extends StatelessWidget {
  const _DoctorProfileScreen();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.medical_services,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text('Name: Dr. ${user?.name ?? 'N/A'}'),
            Text('Email: ${user?.email ?? 'N/A'}'),
            Text('Phone: ${user?.phone ?? 'N/A'}'),
            Text('Role: ${user?.role ?? 'doctor'}'),
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
