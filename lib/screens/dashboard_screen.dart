// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';

import 'owner/pet_management_screen.dart';
import 'owner/booking_screen.dart';
import 'owner/appointments_screen.dart';
import '../../translations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.id != null) {
        context.read<PetProvider>().loadPets(ownerId: authProvider.user!.id!);
      }
    });
  }

  void _navigateToBooking(int petCount) {
    
    final colorScheme = Theme.of(context).colorScheme;

    if (petCount == 0) {
      // Show dialog prompting user to add a pet first
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('noPetsFound')),
          content: Text(context.tr('needToAddPetBeforeBooking')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PetManagementScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(context.tr('addPet')),
            ),
          ],
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BookingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr('vet2UDashboard')),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, child) {
          final petCount = petProvider.pets.length;

          // Colors for the pet status chip
          final bool hasPets = petCount > 0;
          final Color statusBgColor = hasPets
              ? colorScheme.primary.withOpacity(0.08)
              : colorScheme.tertiary.withOpacity(0.10);
          final Color statusBorderColor = hasPets
              ? colorScheme.primary
              : colorScheme.tertiary;
          final Color statusTextColor = statusBorderColor;

          // Colors for CTA cards
          final Color addPetCardBg = colorScheme.tertiaryContainer.withOpacity(
            0.35,
          );
          final Color readyToBookBg = colorScheme.primary.withOpacity(0.08);

          final TextStyle? mutedBodyStyle = theme.textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: colorScheme.primary,
                          child: Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'User',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if ((user?.email ?? '').isNotEmpty)
                                Text(user!.email!, style: mutedBodyStyle),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusBorderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  hasPets
                                      ? '${petCount} ${context.tr('petRegistered')}'
                                      : context.tr('noPetsYet'),
                                  style: TextStyle(
                                    color: statusTextColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Booking CTA (if no pets, show add pet prompt)
                if (petCount == 0)
                  Card(
                    color: addPetCardBg,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pets,
                            size: 48,
                            color: colorScheme.tertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('getStarted'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('addPetProfileToBook'),
                            textAlign: TextAlign.center,
                            style: mutedBodyStyle,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PetManagementScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(context.tr('addYourFirstPet')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.tertiary,
                                foregroundColor: colorScheme.onTertiary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    color: readyToBookBg,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('readyToBook'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('scheduleVetVisitForPet'),
                            textAlign: TextAlign.center,
                            style: mutedBodyStyle,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _navigateToBooking(petCount),
                              icon: const Icon(Icons.add_circle_outline),
                              label: Text(context.tr('bookAppointment')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Services Section
                Text(
                  context.tr('ourServices'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _ServiceCard(
                      icon: Icons.calendar_today,
                      title: context.tr('booking'),
                      subtitle: context.tr('scheduleAVisit'),
                      color: colorScheme.primary,
                      onTap: () => _navigateToBooking(petCount),
                    ),
                    _ServiceCard(
                      icon: Icons.medical_services,
                      title: context.tr('records'),
                      subtitle: context.tr('healthRecords'),
                      color: colorScheme.secondary,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.tr('comingSoon'))),
                        );
                      },
                    ),
                    _ServiceCard(
                      icon: Icons.emergency,
                      title: context.tr('emergency'),
                      subtitle: context.tr('immediateCare'),
                      color: colorScheme.error,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('emergencyServicesComingSoon')),
                          ),
                        );
                      },
                    ),
                    _ServiceCard(
                      icon: Icons.payment,
                      title: context.tr('payments'),
                      subtitle: context.tr('managePayments'),
                      color: colorScheme.tertiary,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('paymentManagementComingSoon')),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick Navigation Buttons
                Text(
                  context.tr('quickActions'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _ActionButton(
                  icon: Icons.pets,
                  text: context.tr('myPets'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PetManagementScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.event,
                  text: context.tr('myAppointments'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}







