// lib/screens/doctor/doctor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medical_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/availability_provider.dart';
import '../../models/service.dart';
import '../../models/appointment.dart';
import '../../models/medical_record.dart';
import '../../models/pet.dart';
import '../../models/user.dart';
import '../../db/db_helper.dart';

import '../../components/modern_cards.dart';
import '../../screens/owner/doctor_selection_screen.dart';
import 'appointment_management_screen.dart';
import 'treatment_recording_screen.dart';
import 'inventory_management_screen.dart';
import 'profile_screen.dart';
import 'medical_record_form_screen.dart';
import 'document_upload_screen.dart';
import 'van_selection_screen.dart';
import 'schedule_settings_screen.dart';
import 'emergency_cases_screen.dart';
import '../../l10n/app_localizations.dart';

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
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6),
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: AppLocalizations.of(context)!.manageAppointments,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: AppLocalizations.of(context)!.recordTreatments,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: AppLocalizations.of(context)!.inventoryManagement,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppLocalizations.of(context)!.profile,
          ),
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

class _DoctorHomeScreenState extends State<_DoctorHomeScreen>
    with WidgetsBindingObserver {
  Service? _selectedService;
  User? _linkedDriver;
  bool _isLoading = false;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _startAutoSaveTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Save data when app goes to background or is inactive
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveDataBeforeExit();
    }

    // Update availability status based on app state
    final authProvider = context.read<AuthProvider>();
    final availabilityProvider = context.read<AvailabilityProvider>();
    if (authProvider.user?.id != null) {
      final newStatus = (state == AppLifecycleState.resumed)
          ? 'online'
          : 'offline';
      availabilityProvider.updateUserAvailability(
        authProvider.user!.id!,
        newStatus,
      );
    }
  }

  void _startAutoSaveTimer() {
    // Auto-save every 30 seconds
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _autoSaveData();
      }
    });
  }

  void _autoSaveData() {
    try {
      final authProvider = context.read<AuthProvider>();
      final availabilityProvider = context.read<AvailabilityProvider>();

      // Save current availability status
      if (authProvider.user?.id != null) {
        availabilityProvider.updateUserAvailability(
          authProvider.user!.id!,
          'online',
        );
      }

      debugPrint('Auto-saved user data at ${DateTime.now()}');
    } catch (e) {
      debugPrint('Error during auto-save: $e');
    }
  }

  Future<void> _loadData() async {
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    final authProvider = context.read<AuthProvider>();
    final appointmentProvider = context.read<AppointmentProvider>();
    final availabilityProvider = context.read<AvailabilityProvider>();
    final doctorId = authProvider.user?.id;

    await serviceProvider.loadServices();
    await availabilityProvider.loadAvailabilityData();
    if (doctorId != null) {
      await appointmentProvider.loadAppointments(doctorId: doctorId);
      await _loadLinkedDriver();
      // Set doctor as online when dashboard loads
      await availabilityProvider.updateUserAvailability(doctorId, 'online');
    }
  }

  Future<void> _loadLinkedDriver() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    try {
      if (authProvider.user?.linkedDriverId != null) {
        final dbHelper = DBHelper.instance;
        final driverData = await dbHelper.getUserById(
          authProvider.user!.linkedDriverId!,
        );
        if (driverData != null && mounted) {
          setState(() {
            _linkedDriver = User.fromMap(driverData);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading linked driver: $e');
    }
  }

  Future<void> _selectService(Service service) async {
    setState(() => _isLoading = true);

    // Simple service selection without complex provider logic
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
    setState(() => _selectedService = service);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);
    final availabilityProvider = Provider.of<AvailabilityProvider>(context);
    final user = authProvider.user;
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final doctorId = user?.id;
    final doctorAppointments = doctorId == null
        ? <Appointment>[]
        : appointmentProvider.appointments
              .where((apt) => apt.doctorId == doctorId)
              .toList();
    final today = DateTime.now();
    final todaysAppointments = doctorAppointments.where((apt) {
      final scheduled = DateTime.tryParse(apt.scheduledAt);
      if (scheduled == null) return false;
      return scheduled.year == today.year &&
          scheduled.month == today.month &&
          scheduled.day == today.day;
    }).length;
    final completedAppointments = doctorAppointments
        .where((apt) => apt.status == 'completed')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              return IconButton(
                icon: Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => _showLanguageDialog(context, localeProvider),
                tooltip: AppLocalizations.of(context)!.changeLanguage,
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: themeProvider.isDarkMode
                    ? AppLocalizations.of(context)!.switchToLightMode
                    : AppLocalizations.of(context)!.switchToDarkMode,
              );
            },
          ),
          // Removed driver selection - admin handles linking
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => authProvider.logout(),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => _closeApp(context),
            tooltip: AppLocalizations.of(context)!.closeApp,
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
                    AppLocalizations.of(context)!.welcomeBack,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.doctorNameWithText(
                      user?.name ?? AppLocalizations.of(context)!.doctor,
                    ),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<AvailabilityProvider>(
                    builder: (context, availabilityProvider, child) {
                      final currentUser = availabilityProvider.onlineUsers
                          .firstWhere(
                            (u) => u.id == user?.id,
                            orElse: () =>
                                user ??
                                User(id: -1, name: '', email: '', password: ''),
                          );
                      final isOnline =
                          currentUser.availabilityStatus == 'online';

                      return Row(
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.status}: ',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isOnline ? Colors.green : Colors.grey,
                              ),
                            ),
                            child: Text(
                              isOnline
                                  ? AppLocalizations.of(context)!.online
                                  : AppLocalizations.of(context)!.offline,
                              style: TextStyle(
                                color: isOnline
                                    ? Colors.green.shade800
                                    : Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: isOnline,
                            onChanged: (value) async {
                              if (user?.id != null) {
                                await availabilityProvider
                                    .updateUserAvailability(
                                      user!.id!,
                                      value ? 'online' : 'offline',
                                    );
                              }
                            },
                            activeColor: Colors.green,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Service Selection
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.serviceForToday,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedService != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.secondary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: colorScheme.secondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedService!.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: colorScheme.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        DropdownButtonFormField<Service>(
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.selectService,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
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
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Linked Driver Card
          if (_linkedDriver != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 950),
                  builder: (context, driverValue, child) {
                    return Opacity(
                      opacity: driverValue,
                      child: Transform.translate(
                        offset: Offset(30 * (1 - driverValue), 0),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          color: Theme.of(context).colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.linkedDriver,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _linkedDriver!.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _linkedDriver!.email,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                if (_linkedDriver!.phone != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${AppLocalizations.of(context)!.phoneLabel}: ${_linkedDriver!.phone}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.active,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // Quick Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ModernStatsCard(
                      title: AppLocalizations.of(context)!.todaysAppointments,
                      value: todaysAppointments.toString(),
                      icon: Icons.calendar_today,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ModernStatsCard(
                      title: AppLocalizations.of(context)!.completed,
                      value: completedAppointments.toString(),
                      icon: Icons.check_circle,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                AppLocalizations.of(context)!.quickActions,
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
                  title: AppLocalizations.of(context)!.manageAppointments,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.viewAndUpdatePatientSchedules,
                  icon: Icons.calendar_today,
                  color: colorScheme.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AppointmentManagementScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: AppLocalizations.of(context)!.recordTreatments,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.documentMedicalProcedures,
                  icon: Icons.medical_services,
                  color: colorScheme.secondary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TreatmentRecordingScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: AppLocalizations.of(context)!.inventoryManagement,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.checkSuppliesAndMedications,
                  icon: Icons.inventory,
                  color: colorScheme.tertiary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const InventoryManagementScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: AppLocalizations.of(context)!.medicalRecords,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.viewAndManagePatientRecords,
                  icon: Icons.medical_services,
                  color: colorScheme.secondary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const _MedicalRecordsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: AppLocalizations.of(context)!.uploadDocuments,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.uploadTreatmentDocumentsAndReports,
                  icon: Icons.upload_file,
                  color: colorScheme.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DocumentUploadScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Removed van selection - admin handles assignments
                ModernActionCard(
                  title: AppLocalizations.of(context)!.urgentCases,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.approveAndManageUrgentServiceRequests,
                  icon: Icons.emergency,
                  color: colorScheme.error,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EmergencyCasesScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _closeApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.closeApp),
        content: Text(
          AppLocalizations.of(context)!.areYouSureYouWantToCloseTheApp,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performAppExit();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.closeApp),
          ),
        ],
      ),
    );
  }

  void _performAppExit() {
    // Save any pending data before closing
    _saveDataBeforeExit();

    if (kIsWeb) {
      // For web: Try to close the window (may not work due to browser security)
      try {
        html.window.close();
      } catch (e) {
        debugPrint('Unable to close web window: $e');
        // Fallback: show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.pleaseCloseThisBrowserTabManuallyToExitTheApp,
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      // For mobile: SystemNavigator.pop() works on Android, on iOS it may not close but returns to home
      try {
        SystemNavigator.pop();
      } catch (e) {
        debugPrint('Unable to close app on mobile platform: $e');
      }
    } else {
      // For desktop or other platforms: Show message since exit may not work reliably
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.pleaseCloseTheApplicationWindowManuallyToExit,
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _saveDataBeforeExit() {
    // Save any pending data before app closes
    try {
      // Update user availability to offline
      final authProvider = context.read<AuthProvider>();
      final availabilityProvider = context.read<AvailabilityProvider>();
      if (authProvider.user?.id != null) {
        availabilityProvider.updateUserAvailability(
          authProvider.user!.id!,
          'offline',
        );
      }

      // Any other data saving logic can be added here
      debugPrint('Data saved before app exit');
    } catch (e) {
      debugPrint('Error saving data before exit: $e');
    }
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

class _MedicalRecordsScreen extends StatefulWidget {
  const _MedicalRecordsScreen();

  @override
  State<_MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<_MedicalRecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.id != null) {
        context.read<MedicalProvider>().loadMedicalRecords(
          doctorId: authProvider.user!.id!,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.medicalRecordsScreen),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: AppLocalizations.of(context)!.addMedicalRecord,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MedicalRecordFormScreen(),
              ),
            ),
          ),
        ],
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, animationValue, child) {
          return Opacity(
            opacity: animationValue,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - animationValue)),
              child: Consumer<MedicalProvider>(
                builder: (context, medicalProvider, child) {
                  if (medicalProvider.isLoading) {
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
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.noMedicalRecords,
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.addMedicalRecordsForYourPatients,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MedicalRecordFormScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: Text(
                              AppLocalizations.of(context)!.addFirstRecord,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort records by date (newest first)
                  final sortedRecords = records.toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, listValue, child) {
                      return Opacity(
                        opacity: listValue,
                        child: Transform.translate(
                          offset: Offset(30 * (1 - listValue), 0),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: sortedRecords.length,
                            itemBuilder: (context, index) {
                              final record = sortedRecords[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: Duration(
                                  milliseconds: 400 + (index * 100),
                                ),
                                curve: Curves.easeOutCubic,
                                builder: (context, cardValue, child) {
                                  return Transform.translate(
                                    offset: Offset(-30 * (1 - cardValue), 0),
                                    child: Opacity(
                                      opacity: cardValue,
                                      child: _MedicalRecordCard(
                                        record: record,
                                        onEdit: () =>
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    MedicalRecordFormScreen(
                                                      record: record,
                                                    ),
                                              ),
                                            ),
                                        onDelete: () => _showDeleteConfirmation(
                                          context,
                                          record,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MedicalRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMedicalRecord),
        content: Text(AppLocalizations.of(context)!.confirmDeleteMedicalRecord),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await context
                  .read<MedicalProvider>()
                  .deleteMedicalRecord(record.id!);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      )!.medicalRecordDeletedSuccessfully,
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
}

class _MedicalRecordCard extends StatelessWidget {
  final MedicalRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicalRecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Parse date for better display
    final date = DateTime.tryParse(record.date);
    final formattedDate = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : record.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.petId}: ${record.petId}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(AppLocalizations.of(context)!.edit),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Diagnosis Section
            _buildDetailSection(
              context,
              AppLocalizations.of(context)!.diagnosis,
              record.diagnosis,
              Icons.local_hospital,
              colorScheme.errorContainer,
              colorScheme.error,
            ),

            const SizedBox(height: 16),

            // Treatment Section
            _buildDetailSection(
              context,
              AppLocalizations.of(context)!.treatment,
              record.treatment,
              Icons.healing,
              colorScheme.secondaryContainer,
              colorScheme.secondary,
            ),

            // Prescription Section (if available)
            if (record.prescription != null &&
                record.prescription!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailSection(
                context,
                AppLocalizations.of(context)!.prescription,
                record.prescription!,
                Icons.medication,
                colorScheme.primaryContainer,
                colorScheme.primary,
              ),
            ],

            // Notes Section (if available)
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailSection(
                context,
                AppLocalizations.of(context)!.additionalNotes,
                record.notes!,
                Icons.note,
                colorScheme.tertiaryContainer,
                colorScheme.tertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: backgroundColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorProfileScreen extends StatelessWidget {
  const _DoctorProfileScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile),
        elevation: 0,
        backgroundColor: colorScheme.surface,
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
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: colorScheme.primary,
                    child: Icon(
                      Icons.medical_services,
                      size: 36,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${AppLocalizations.of(context)!.doctorNameWithText}: ${user?.name ?? AppLocalizations.of(context)!.doctor}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    user?.email ?? AppLocalizations.of(context)!.noEmail,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
                  title: AppLocalizations.of(context)!.professionalInformation,
                  subtitle: AppLocalizations.of(context)!.updateYourCredentials,
                  icon: Icons.medical_services,
                  color: colorScheme.primary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DoctorProfileScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title:
                      '${AppLocalizations.of(context)!.phoneLabel}: ${user?.phone ?? AppLocalizations.of(context)!.notSet}',
                  subtitle: AppLocalizations.of(context)!.contactNumber,
                  icon: Icons.phone,
                  color: colorScheme.secondary,
                  onTap: () {
                    // TODO: Implement phone update
                  },
                  showArrow: false,
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: AppLocalizations.of(context)!.scheduleSettings,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.workingHoursAndAvailability,
                  icon: Icons.schedule,
                  color: colorScheme.tertiary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ScheduleSettingsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModernActionCard(
                  title: AppLocalizations.of(context)!.notifications,
                  subtitle: AppLocalizations.of(context)!.alertPreferences,
                  icon: Icons.notifications,
                  color: colorScheme.primary,
                  onTap: () {
                    // TODO: Implement notification settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          )!.notificationSettingsComingSoon,
                        ),
                        backgroundColor: colorScheme.error,
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
                      color: colorScheme.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  color: colorScheme.error.withOpacity(0.05),
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
                              color: colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.logout,
                              color: colorScheme.error,
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
                                    color: colorScheme.error,
                                  ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? colorScheme.onSurfaceVariant
                                : Colors.black87,
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
