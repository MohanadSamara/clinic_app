// lib/screens/owner/owner_dashboard.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/medical_record.dart';
import 'pet_management_screen.dart';
import 'booking_screen.dart';
import 'appointments_screen.dart';
import 'payment_screen.dart';
import 'service_request_screen.dart';
import 'notifications_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _OwnerHomeScreen(),
    const PetManagementScreen(),
    const BookingScreen(),
    const AppointmentsScreen(),
    const _OwnerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: themeProvider.isDarkMode
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.6),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Book',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.schedule),
                label: 'Appointments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OwnerHomeScreen extends StatefulWidget {
  const _OwnerHomeScreen();

  @override
  State<_OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<_OwnerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.id == null) return;
    final ownerId = authProvider.user!.id!;
    await Future.wait([
      context.read<PetProvider>().loadPets(ownerId: ownerId),
      context.read<AppointmentProvider>().loadAppointments(ownerId: ownerId),
      context.read<NotificationProvider>().loadNotifications(ownerId),
      context.read<NotificationProvider>().refreshOwnerReminders(ownerId),
      context.read<PaymentProvider>().loadInvoicesForOwner(ownerId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final currency = NumberFormat.simpleCurrency();
    final petCount = context.watch<PetProvider>().pets.length;
    final appointments = context.watch<AppointmentProvider>().appointments;
    final upcomingCount =
        appointments.where((a) => a.status != 'completed').length;
    final outstandingBalance = context
        .watch<PaymentProvider>()
        .invoices
        .where((invoice) => !invoice.isPaid)
        .fold<double>(0, (sum, invoice) => sum + invoice.balance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet2U - Pet Owner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const OwnerNotificationsScreen(),
              ),
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: themeProvider.isDarkMode
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
              );
            },
          ),
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
              'Welcome back, ${user?.name ?? 'Pet Owner'}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Active Pets',
                            value: '$petCount',
                            icon: Icons.pets,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Upcoming Appts',
                            value: '$upcomingCount',
                            icon: Icons.schedule,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _DashboardCard(
                          title: 'My Pets',
                          icon: Icons.pets,
                          color: Theme.of(context).colorScheme.secondary,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PetManagementScreen(),
                            ),
                          ),
                        ),
                        _DashboardCard(
                          title: 'Book Appointment',
                          icon: Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const BookingScreen(),
                            ),
                          ),
                        ),
                        _DashboardCard(
                          title: 'Medical History',
                          icon: Icons.medical_services,
                          color: Theme.of(context).colorScheme.tertiary,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const _MedicalHistoryScreen(),
                            ),
                          ),
                        ),
                        _DashboardCard(
                          title: 'Service Request',
                          icon: Icons.directions_car,
                          color: Colors.orange,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ServiceRequestScreen(),
                            ),
                          ),
                        ),
                        _DashboardCard(
                          title: 'Billing',
                          icon: Icons.receipt_long,
                          color: Colors.blueGrey,
                          subtitle:
                              'Due: ${currency.format(outstandingBalance)}',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PaymentScreen(),
                            ),
                          ),
                        ),
                        _DashboardCard(
                          title: 'Reminders',
                          icon: Icons.notifications_active,
                          color: Colors.teal,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const OwnerNotificationsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ServiceRequestScreen(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: Theme.of(context).brightness == Brightness.dark ? 6 : 4,
      color: Theme.of(context).cardTheme.color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicalHistoryScreen extends StatefulWidget {
  const _MedicalHistoryScreen();

  @override
  State<_MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<_MedicalHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.id != null) {
        context.read<MedicalProvider>().loadMedicalRecords();
        context.read<PetProvider>().loadPets(ownerId: authProvider.user!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical History')),
      body: Consumer2<MedicalProvider, PetProvider>(
        builder: (context, medicalProvider, petProvider, child) {
          if (medicalProvider.isLoading || petProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = medicalProvider.medicalRecords;
          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No medical records found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final pet = petProvider.pets.cast().firstWhere(
                (p) => p.id == record.petId,
                orElse: () => null,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pets, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pet?.name ?? 'Pet ID: ${record.petId}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            record.date.split('T')[0],
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Diagnosis', record.diagnosis),
                      _buildDetailRow('Treatment', record.treatment),
                      if (record.prescription != null &&
                          record.prescription!.isNotEmpty)
                        _buildDetailRow('Prescription', record.prescription!),
                      if (record.notes != null && record.notes!.isNotEmpty)
                        _buildDetailRow('Notes', record.notes!),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}

class _OwnerProfileScreen extends StatelessWidget {
  const _OwnerProfileScreen();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  fontSize: 32,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Name: ${user?.name ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Email: ${user?.email ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Phone: ${user?.phone ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Role: ${user?.role ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
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
