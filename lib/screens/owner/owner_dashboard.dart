// lib/screens/owner/owner_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../models/service_request.dart';
import '../../models/pet.dart';
import '../../models/user.dart';
import '../../components/modern_cards.dart';
import '../../services/location_service.dart';

import 'pet_management_screen.dart';
import 'booking_screen.dart';
import 'appointments_screen.dart';
import 'driver_tracking_screen.dart';
import 'doctor_selection_screen.dart';
import 'profile_screen.dart';
import 'medical_documents_screen.dart';
import 'payment_history_screen.dart';
import '../notification_preferences_screen.dart';
import '../../../translations.dart';
import '../../widgets/language_toggle.dart';

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
    const OwnerProfileScreen(),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.6),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.25,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: context.tr('home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            activeIcon: Icon(Icons.pets),
            label: context.tr('pets'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: context.tr('book'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: context.tr('appointments'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: context.tr('profile'),
          ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(context.tr('vet2UDashboard')),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          const LanguageToggle(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: themeProvider.isDarkMode
                    ? context.tr('switchToLightMode')
                    : context.tr('switchToDarkMode'),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section - Extended
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.9),
                    colorScheme.primary.withOpacity(0.7),
                    colorScheme.secondary.withOpacity(0.5),
                    colorScheme.tertiary.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Image Banner - Extended
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1552728089-57bdde30beb3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
                          width: double.infinity,
                          height: 240,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: 240,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withOpacity(0.8),
                                    colorScheme.secondary.withOpacity(0.6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: double.infinity,
                                height: 240,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary.withOpacity(0.8),
                                      colorScheme.secondary.withOpacity(0.6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.pets,
                                    size: 60,
                                    color: colorScheme.onPrimary.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimary.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  'welcomeBackUser',
                                  args: {
                                    'name':
                                        user?.name?.split(' ').first ??
                                        context.tr('petOwner'),
                                  },
                                ),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      height: 1.2,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr('trustedPartnerPetCare'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.tr('compassionateVeterinaryCare'),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.8),
                                      height: 1.5,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: colorScheme.primary.withOpacity(
                                          0.3,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: colorScheme.primary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          context.tr('rating'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: colorScheme.secondary
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.people,
                                          color: colorScheme.secondary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          context.tr('happyPets'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: colorScheme.secondary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Key Statistics
                  Consumer2<PetProvider, AppointmentProvider>(
                    builder: (context, petProvider, appointmentProvider, _) {
                      final petCount = petProvider.pets.length;
                      final upcomingAppointments = appointmentProvider
                          .appointments
                          .where(
                            (apt) =>
                                apt.ownerId == user?.id &&
                                DateTime.tryParse(
                                      apt.scheduledAt ?? '',
                                    )?.isAfter(DateTime.now()) ==
                                    true,
                          )
                          .length;
                      final completedServices = appointmentProvider.appointments
                          .where(
                            (apt) =>
                                apt.ownerId == user?.id &&
                                apt.status == 'completed',
                          )
                          .length;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _HeroStatCard(
                            value: petCount.toString(),
                            label: context.tr('pets'),
                            icon: Icons.pets,
                            color: colorScheme.onPrimary,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: colorScheme.onPrimary.withOpacity(0.3),
                          ),
                          _HeroStatCard(
                            value: upcomingAppointments.toString(),
                            label: context.tr('upcoming'),
                            icon: Icons.calendar_today,
                            color: colorScheme.onPrimary,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: colorScheme.onPrimary.withOpacity(0.3),
                          ),
                          _HeroStatCard(
                            value: completedServices.toString(),
                            label: context.tr('completed'),
                            icon: Icons.check_circle,
                            color: colorScheme.onPrimary,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Call-to-Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DoctorSelectionScreen(),
                              ),
                            ),
                            icon: Icon(
                              Icons.calendar_today,
                              color: colorScheme.primary,
                            ),
                            label: Text(context.tr('bookAVisit')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.onPrimary,
                              foregroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.onPrimary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: OutlinedButton.icon(
                            onPressed: () => _showEmergencyDialog(context),
                            icon: Icon(
                              Icons.emergency,
                              color: colorScheme.onPrimary,
                            ),
                            label: Text(context.tr('emergency')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Enhanced Success Stories Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.onPrimary.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.onPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.star,
                                color: colorScheme.onPrimary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.tr('successStories'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Multiple success stories in a carousel-like layout
                        _SuccessStoryCard(
                          imageUrl:
                              'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
                          quote:
                              '"${context.tr('vet2U')} ${context.tr('savedMyCatEmergency')}"',
                          author: 'Sarah M., ${context.tr('happyPetOwner')}',
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 16),
                        _SuccessStoryCard(
                          imageUrl:
                              'https://images.unsplash.com/photo-1548124853-8d0e16544a01?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
                          quote: '"${context.tr('mobileVetServiceAmazing')}"',
                          author: 'James K., ${context.tr('dogLover')}',
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 16),
                        _SuccessStoryCard(
                          imageUrl:
                              'https://images.unsplash.com/photo-1574158622682-e40e69881006?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
                          quote:
                              '"${context.tr('affordableProfessionalCaring')}"',
                          author: 'Maria R., ${context.tr('petParent')}',
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rest of the content with padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First card: User Info
                  Card(
                    elevation: 2,
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: colorScheme.primary,
                            child: Text(
                              user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
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
                                  user?.name ?? context.tr('petOwner'),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                ),
                                Text(
                                  user?.email ?? context.tr('noEmail'),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Consumer<PetProvider>(
                                  builder: (context, petProvider, _) {
                                    final petCount = petProvider.pets.length;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: petCount == 0
                                            ? colorScheme.tertiaryContainer
                                                  .withOpacity(0.7)
                                            : colorScheme.primaryContainer
                                                  .withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        petCount == 0
                                            ? context.tr('noPetsYet')
                                            : context.tr(
                                                'petsRegistered',
                                                args: {
                                                  'count': petCount.toString(),
                                                },
                                              ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: petCount == 0
                                                  ? colorScheme
                                                        .onTertiaryContainer
                                                  : colorScheme
                                                        .onPrimaryContainer,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Second section: Quick CTA card
            Consumer<PetProvider>(
              builder: (context, petProvider, _) {
                final hasPets = petProvider.pets.isNotEmpty;
                return Card(
                  elevation: 2,
                  color: hasPets
                      ? colorScheme.surface
                      : colorScheme.tertiaryContainer.withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPets
                              ? context.tr('bookAVisit')
                              : context.tr('addYourFirstPet'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasPets
                              ? context.tr('scheduleAppointmentForPets')
                              : context.tr('registerPetsToStartBooking'),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: hasPets
                                ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const DoctorSelectionScreen(),
                                    ),
                                  )
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PetManagementScreen(),
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              hasPets
                                  ? context.tr('bookAppointment')
                                  : context.tr('addPet'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Third section: Services grid
            Text(
              context.tr('services'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ServiceCard(
                  icon: Icons.calendar_today,
                  title: context.tr('booking'),
                  subtitle: context.tr('scheduleAppointments'),
                  color: colorScheme.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DoctorSelectionScreen(),
                    ),
                  ),
                ),
                _ServiceCard(
                  icon: Icons.medical_services,
                  title: context.tr('records'),
                  subtitle: context.tr('medicalHistory'),
                  color: colorScheme.secondary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const _MedicalHistoryScreen(),
                    ),
                  ),
                ),
                _ServiceCard(
                  icon: Icons.file_download,
                  title: context.tr('documents'),
                  subtitle: context.tr('downloadFiles'),
                  color: colorScheme.tertiary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MedicalDocumentsScreen(),
                    ),
                  ),
                ),
                _ServiceCard(
                  icon: Icons.payment,
                  title: context.tr('payments'),
                  subtitle: context.tr('viewHistory'),
                  color: Colors.green,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PaymentHistoryScreen(),
                    ),
                  ),
                ),
                _ServiceCard(
                  icon: Icons.emergency,
                  title: context.tr('emergency'),
                  subtitle: context.tr('urgentCare'),
                  color: colorScheme.error,
                  onTap: () => _showEmergencyDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Fourth section: Quick Actions
            Text(
              context.tr('quickActions'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _ActionButton(
              icon: Icons.pets,
              label: context.tr('managePets'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PetManagementScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.location_on,
              label: context.tr('trackService'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DriverTrackingScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.schedule,
              label: context.tr('viewAppointments'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AppointmentsScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(
      context,
      listen: false,
    );
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('pleaseLoginFirst'))));
      return;
    }

    if (petProvider.pets.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('pleaseAddPetFirst'))));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EmergencyRequestDialog(
        user: user,
        pets: petProvider.pets,
        onSubmit: (serviceRequest) async {
          try {
            final success = await serviceRequestProvider.createServiceRequest(
              serviceRequest,
            );
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('emergencyRequestSent')),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              throw Exception('Failed to create service request');
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${context.tr('failedSendEmergency')}: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    LocaleProvider localeProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('selectLanguage')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: Text(context.tr('english')),
              onTap: () {
                localeProvider.setLocale(const Locale('en'));

                Navigator.of(context).pop();
              },
              selected: localeProvider.locale.languageCode == 'en',
            ),
            ListTile(
              leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
              title: Text(context.tr('arabic')),
              onTap: () {
                localeProvider.setLocale(const Locale('ar'));

                Navigator.of(context).pop();
              },
              selected: localeProvider.locale.languageCode == 'ar',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('cancel')),
          ),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _HeroStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _HeroStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).brightness == Brightness.dark
                    ? colorScheme.onSurfaceVariant
                    : Colors.black87,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessStoryCard extends StatelessWidget {
  final String imageUrl;
  final String quote;
  final String author;
  final ColorScheme colorScheme;

  const _SuccessStoryCard({
    required this.imageUrl,
    required this.quote,
    required this.author,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.pets, color: colorScheme.primary, size: 40),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onPrimary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: colorScheme.onPrimary.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        quote,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary.withOpacity(0.9),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: colorScheme.onPrimary.withOpacity(0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      author,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimary.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class EmergencyRequestDialog extends StatefulWidget {
  final User user;
  final List<Pet> pets;
  final Function(ServiceRequest) onSubmit;

  const EmergencyRequestDialog({
    super.key,
    required this.user,
    required this.pets,
    required this.onSubmit,
  });

  @override
  State<EmergencyRequestDialog> createState() => _EmergencyRequestDialogState();
}

class _EmergencyRequestDialogState extends State<EmergencyRequestDialog> {
  Pet? _selectedPet;
  final _descriptionController = TextEditingController();
  bool _shareLocation = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitEmergencyRequest() async {
    if (_selectedPet == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('pleaseSelectPet'))));
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('pleaseDescribeEmergency'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      double? latitude;
      double? longitude;
      String? address;

      if (_shareLocation) {
        final locationService = LocationService();
        final position = await locationService.getCurrentLocation();
        if (position != null) {
          latitude = position.latitude;
          longitude = position.longitude;
          // TODO: Get address from coordinates
        }
      }

      final serviceRequest = ServiceRequest(
        ownerId: widget.user.id!,
        petId: _selectedPet!.id!,
        requestType: 'emergency',
        description: _descriptionController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        address: address,
        requestDate: DateTime.now(),
      );

      widget.onSubmit(serviceRequest);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('failedSendEmergency')}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.emergency, color: colorScheme.error),
          const SizedBox(width: 8),
          Text(
            context.tr('emergencyRequest'),
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('selectPetNeedingCare'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Pet>(
              value: _selectedPet,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              items: widget.pets.map((pet) {
                return DropdownMenuItem<Pet>(
                  value: pet,
                  child: Text('${pet.name} (${pet.species})'),
                );
              }).toList(),
              onChanged: (pet) => setState(() => _selectedPet = pet),
              hint: Text(context.tr('choosePet')),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('describeEmergency'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.tr('describeSymptoms'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _shareLocation,
                  onChanged: (value) =>
                      setState(() => _shareLocation = value ?? true),
                ),
                Expanded(
                  child: Text(
                    context.tr('shareLocationResponders'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('emergencyWarning'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submitEmergencyRequest,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.onError,
                    ),
                  ),
                )
              : Text(context.tr('sendEmergencyRequest')),
        ),
      ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('medicalHistory'))),
      body: Consumer2<MedicalProvider, PetProvider>(
        builder: (context, medicalProvider, petProvider, child) {
          if (medicalProvider.isLoading || petProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          final records = medicalProvider.medicalRecords;
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 64,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('noMedicalRecords'),
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final matchingPets = petProvider.pets.where(
                (p) => p.id == record.petId,
              );
              final pet = matchingPets.isNotEmpty ? matchingPets.first : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shadowColor: colorScheme.shadow.withOpacity(0.1),
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pets, color: colorScheme.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pet?.name ??
                                  '${context.tr('petId')}: ${record.petId}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                          ),
                          Text(
                            record.date.split('T')[0],
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        context.tr('diagnosis'),
                        record.diagnosis,
                      ),
                      _buildDetailRow(
                        context.tr('treatment'),
                        record.treatment,
                      ),
                      if (record.prescription != null &&
                          record.prescription!.isNotEmpty)
                        _buildDetailRow(
                          context.tr('prescription'),
                          record.prescription!,
                        ),
                      if (record.notes != null && record.notes!.isNotEmpty)
                        _buildDetailRow(context.tr('notes'), record.notes!),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
