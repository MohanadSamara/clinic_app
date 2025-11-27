// lib/screens/owner/owner_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/medical_record.dart';
import '../../models/service_request.dart';
import '../../models/pet.dart';
import '../../models/user.dart';
import '../../components/modern_cards.dart';
import '../../components/ui_kit.dart';
import '../../theme/app_theme.dart';
import '../../services/location_service.dart';
import '../../l10n/app_localizations.dart';
import 'pet_management_screen.dart';
import 'booking_screen.dart';
import 'appointments_screen.dart';
import 'driver_tracking_screen.dart';
import 'doctor_selection_screen.dart';
import 'profile_screen.dart';
import 'medical_documents_screen.dart';

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
      backgroundColor: AppTheme.background,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          boxShadow: AppTheme.mediumShadow,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
          selectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.25,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppLocalizations.of(context)!.home,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_outlined),
              activeIcon: Icon(Icons.pets),
              label: AppLocalizations.of(context)!.pets,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: AppLocalizations.of(context)!.book,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule_outlined),
              activeIcon: Icon(Icons.schedule),
              label: AppLocalizations.of(context)!.appointments,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: AppLocalizations.of(context)!.profile,
            ),
          ],
        ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.appTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: AppTheme.onSurfaceVariant,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: themeProvider.isDarkMode
                    ? AppLocalizations.of(context)!.switchToLightMode
                    : AppLocalizations.of(context)!.switchToDarkMode,
              );
            },
          ),
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              return IconButton(
                icon: Icon(Icons.language, color: AppTheme.onSurfaceVariant),
                onPressed: () => _showLanguageDialog(context, localeProvider),
                tooltip: AppLocalizations.of(context)!.changeLanguage,
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              // TODO: Navigate to notifications
            },
            tooltip: AppLocalizations.of(context)!.notifications,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Welcome Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.paddingLarge),
              child: HeroWelcomeSection(
                userName: user?.name ?? 'Pet Owner',
                subtitle: AppLocalizations.of(context)!.yourPetsSafeHands,
                callToAction: PrimaryButton(
                  label: AppLocalizations.of(context)!.bookAppointment,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DoctorSelectionScreen(),
                    ),
                  ),
                  icon: Icons.calendar_today,
                ),
              ),
            ),
          ),

          // Overview
          SliverToBoxAdapter(
            child: SectionHeader(
              title: AppLocalizations.of(context)!.overview,
              subtitle: AppLocalizations.of(context)!.quickSnapshot,
            ),
          ),

          // Quick Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.paddingLarge,
                vertical: AppTheme.padding,
              ),
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
                          title: AppLocalizations.of(context)!.activePets,
                          value: petCount.toString(),
                          icon: Icons.pets,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ModernStatsCard(
                          title: AppLocalizations.of(context)!.upcoming,
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
            child: SectionHeader(
              title: AppLocalizations.of(context)!.quickActions,
              subtitle: AppLocalizations.of(context)!.jumpToTasks,
            ),
          ),

          // Action Cards
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingLarge),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ModernActionCard(
                  title: AppLocalizations.of(context)!.bookAppointment,
                  subtitle: AppLocalizations.of(context)!.scheduleVetCare,
                  icon: Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DoctorSelectionScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: AppLocalizations.of(context)!.pets,
                  subtitle: AppLocalizations.of(context)!.managePetProfiles,
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
                  title: AppLocalizations.of(context)!.trackService,
                  subtitle: AppLocalizations.of(context)!.followVetVisit,
                  icon: Icons.location_on,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DriverTrackingScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: AppLocalizations.of(context)!.medicalHistory,
                  subtitle: AppLocalizations.of(context)!.viewPastTreatments,
                  icon: Icons.medical_services,
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const _MedicalHistoryScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: AppLocalizations.of(context)!.medicalDocuments,
                  subtitle: AppLocalizations.of(context)!.downloadTreatmentDocs,
                  icon: Icons.file_download,
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MedicalDocumentsScreen(),
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseLoginFirst)),
      );
      return;
    }

    if (petProvider.pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseAddPetFirst),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EmergencyRequestDialog(
        user: user,
        pets: petProvider.pets,
        onSubmit: (serviceRequest) async {
          try {
            // TODO: Create service request provider and integrate
            // For now, just show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.emergencyRequestSent,
                ),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send emergency request: $e'),
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
        title: Text(AppLocalizations.of(context)!.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: Text(AppLocalizations.of(context)!.english),
              onTap: () {
                localeProvider.setLocale(const Locale('en'));
                Navigator.of(context).pop();
              },
              selected: localeProvider.locale.languageCode == 'en',
            ),
            ListTile(
              leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
              title: Text(AppLocalizations.of(context)!.arabic),
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
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectPet)),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseDescribeEmergency),
        ),
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
        requestType: 'urgent',
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
          content: Text(
            '${AppLocalizations.of(context)!.failedSendEmergency}: $e',
          ),
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
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.emergency, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.emergencyRequest,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
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
              AppLocalizations.of(context)!.selectPetNeedingCare,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Pet>(
              value: _selectedPet,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: widget.pets.map((pet) {
                return DropdownMenuItem<Pet>(
                  value: pet,
                  child: Text('${pet.name} (${pet.species})'),
                );
              }).toList(),
              onChanged: (pet) => setState(() => _selectedPet = pet),
              hint: Text(AppLocalizations.of(context)!.choosePet),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.describeEmergency,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.describeSymptoms,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
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
                    AppLocalizations.of(context)!.shareLocationResponders,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.emergencyWarning,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitEmergencyRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(AppLocalizations.of(context)!.sendEmergencyRequest),
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
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.medicalHistory)),
      body: Consumer2<MedicalProvider, PetProvider>(
        builder: (context, medicalProvider, petProvider, child) {
          if (medicalProvider.isLoading || petProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noMedicalRecords,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
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
                          Icon(
                            Icons.pets,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
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
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        AppLocalizations.of(context)!.diagnosis,
                        record.diagnosis,
                      ),
                      _buildDetailRow(
                        AppLocalizations.of(context)!.treatment,
                        record.treatment,
                      ),
                      if (record.prescription != null &&
                          record.prescription!.isNotEmpty)
                        _buildDetailRow(
                          AppLocalizations.of(context)!.prescription,
                          record.prescription!,
                        ),
                      if (record.notes != null && record.notes!.isNotEmpty)
                        _buildDetailRow(
                          AppLocalizations.of(context)!.notes,
                          record.notes!,
                        ),
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
        title: Text(AppLocalizations.of(context)!.profile),
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
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
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
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                  title: AppLocalizations.of(context)!.personalInformation,
                  subtitle: AppLocalizations.of(context)!.updateDetails,
                  icon: Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const OwnerProfileScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: 'Phone: ${user?.phone ?? 'Not set'}',
                  subtitle: AppLocalizations.of(context)!.contactNumber,
                  icon: Icons.phone,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () {
                    // TODO: Implement phone update
                  },
                  showArrow: false,
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: AppLocalizations.of(context)!.accountSettings,
                  subtitle: AppLocalizations.of(context)!.notificationsPrivacy,
                  icon: Icons.settings,
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () {
                    // TODO: Implement settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.settingsComingSoon,
                        ),
                      ),
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
                      ).colorScheme.error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.05),
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
                              ).colorScheme.error.withValues(alpha: 0.1),
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
                              AppLocalizations.of(context)!.signOut,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.grey[700]
                                : Theme.of(
                                    context,
                                  ).colorScheme.error.withValues(alpha: 0.7),
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
