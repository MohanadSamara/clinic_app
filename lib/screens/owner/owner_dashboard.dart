// lib/screens/owner/owner_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/medical_record.dart';
import '../../components/modern_cards.dart';
import 'pet_management_screen.dart';
import 'booking_screen.dart';
import 'appointments_screen.dart';
import 'driver_tracking_screen.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;
      if (userId != null) {
        context.read<PetProvider>().loadPets(ownerId: userId);
        context.read<AppointmentProvider>().loadAppointments(ownerId: userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6),
        elevation: 8,
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _OwnerHomeScreen extends StatelessWidget {
  const _OwnerHomeScreen();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet2U'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: themeProvider.isDarkMode
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Welcome Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    user?.name ?? 'Pet Owner',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Consumer2<PetProvider, AppointmentProvider>(
                builder: (context, petProvider, appointmentProvider, _) {
                  final petCount = petProvider.pets.length;
                  final ownerId = user?.id;
                  final upcomingAppointments = ownerId == null
                      ? 0
                      : appointmentProvider.appointments
                          .where((apt) => apt.ownerId == ownerId)
                          .where(
                            (apt) =>
                                apt.status != 'completed' &&
                                apt.status != 'cancelled',
                          )
                          .length;

                  return Row(
                    children: [
                      Expanded(
                        child: ModernStatsCard(
                          title: 'Active Pets',
                          value: petCount.toString(),
                          icon: Icons.pets,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ModernStatsCard(
                          title: 'Upcoming',
                          value: upcomingAppointments.toString(),
                          icon: Icons.schedule,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // Action Cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ModernActionCard(
                  title: 'Book Appointment',
                  subtitle: 'Schedule veterinary care',
                  icon: Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BookingScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: 'My Pets',
                  subtitle: 'Manage pet profiles',
                  icon: Icons.pets,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PetManagementScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: 'Track Service',
                  subtitle: 'Follow your vet visit',
                  icon: Icons.location_on,
                  color: Colors.purple,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DriverTrackingScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: 'Medical History',
                  subtitle: 'View past treatments',
                  icon: Icons.medical_services,
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const _MedicalHistoryScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModernEmergencyCard(onTap: () => _showEmergencyDialog(context)),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Service'),
        content: const Text('Do you need immediate veterinary assistance?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement emergency booking
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emergency request sent!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Request Emergency'),
          ),
        ],
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
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Pet Owner',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    user?.email ?? 'No email',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Profile Details
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ModernActionCard(
                  title: 'Personal Information',
                  subtitle: 'Update your details',
                  icon: Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () {
                    // TODO: Implement edit profile
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit profile coming soon')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: 'Phone: ${user?.phone ?? 'Not set'}',
                  subtitle: 'Contact number',
                  icon: Icons.phone,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () {
                    // TODO: Implement phone update
                  },
                  showArrow: false,
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: 'Account Settings',
                  subtitle: 'Notifications, privacy',
                  icon: Icons.settings,
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () {
                    // TODO: Implement settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming soon')),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  color: Theme.of(context).colorScheme.error.withOpacity(0.05),
                  child: InkWell(
                    onTap: () => authProvider.logout(),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.logout,
                              color: Theme.of(context).colorScheme.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Sign Out',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Theme.of(
                              context,
                            ).colorScheme.error.withOpacity(0.7),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
