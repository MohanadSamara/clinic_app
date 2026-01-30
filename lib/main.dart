import 'dart:ui' show Locale;
import 'package:flutter/material.dart' hide Locale;
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/service_provider.dart';
import 'providers/service_request_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/medical_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/document_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/van_provider.dart';
import 'providers/availability_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/driver_verification_provider.dart';
import 'providers/page_provider.dart';
import 'models/van.dart';
import 'services/notification_service.dart';
import 'services/calendar_service.dart';
import 'services/qdrant_service.dart';
import 'screens/loading_screen.dart';
import 'screens/login_screen.dart';
import 'screens/role_based_home.dart';
import 'screens/page_viewer_screen.dart';
import 'screens/doctor/document_upload_screen.dart';
import 'screens/doctor/medical_record_form_screen.dart';
import 'models/medical_record.dart';
import 'models/pet.dart';
import 'models/appointment.dart';
import 'theme/vet_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Web-specific imports
import 'package:universal_html/universal_html.dart' as html;

void _setupWebCloseHandling() {
  if (kIsWeb) {
    // Add beforeunload event listener to ensure data is saved before page closes
    html.window.onBeforeUnload.listen((event) {
      // Note: We can't do async operations here due to browser limitations
      // But we can show a confirmation dialog
      // The actual data saving happens through the app lifecycle events we already implemented

      // Optional: Show confirmation dialog (browsers may ignore this)
      // event.returnValue = 'Are you sure you want to leave? Data will be saved automatically.';

      debugPrint(
        'Browser close detected - data should be saved via lifecycle events',
      );
    });
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional: provide proxy base at build time for web via --dart-define
  const String qdrantProxyBase = String.fromEnvironment(
    'QDRANT_PROXY_BASE',
    defaultValue: '',
  );

  try {
    // Initialize Firebase globally
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize calendar service
    await CalendarService.initialize();

    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Test Qdrant connection — uses proxy on web when provided via --dart-define
    try {
      final qdrantService = QdrantService.auto(proxyBaseUrl: qdrantProxyBase);
      if (!kIsWeb) {
        await qdrantService.testConnection();
        debugPrint('Qdrant connection test successful');
      } else {
        debugPrint(
          'Using proxy base: ${qdrantProxyBase.isEmpty ? '<none>' : qdrantProxyBase}',
        );
      }
    } catch (e) {
      debugPrint('Qdrant connection test failed: $e');
    }

    // Initialize auth provider to check for existing session
    final authProvider = AuthProvider();
    await authProvider.initialize();

    // Load pending doctor registration if exists
    await authProvider.loadPendingDoctorRegistration();

    // Initialize sample vans for testing
    await _initializeSampleVans();

    // Create a file in Documents directory (skip on web)
    if (!kIsWeb) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/created_file.txt');
        await file.writeAsString(
          'This file was created by the Vet2U app on ${DateTime.now()}.',
        );
        debugPrint('File created at: ${file.path}');
      } catch (e) {
        debugPrint('Error creating file: $e');
      }
    }

    runApp(MyApp(authProvider: authProvider));

    // Setup web-specific close handling
    if (kIsWeb) {
      _setupWebCloseHandling();
    }
  } catch (e, stackTrace) {
    debugPrint('Error in main: $e');
    debugPrint('Stack trace: $stackTrace');
    // Fallback to basic app without providers
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error initializing app: $e'))),
      ),
    );
  }
}

Future<void> _initializeSampleVans() async {
  try {
    final vanProvider = VanProvider();
    await vanProvider.loadVans();

    // Only add sample vans if none exist
    if (vanProvider.vans.isEmpty) {
      final sampleVans = [
        Van(
          name: "Vet Van Alpha",
          licensePlate: "VET-001",
          model: "Ford Transit",
          capacity: 2,
          status: "available",
          description: "Primary emergency response van",
          createdAt: DateTime.now().toIso8601String(),
        ),
        Van(
          name: "Vet Van Beta",
          licensePlate: "VET-002",
          model: "Mercedes Sprinter",
          capacity: 1,
          status: "available",
          description: "Secondary service van",
          createdAt: DateTime.now().toIso8601String(),
        ),
        Van(
          name: "Emergency Van",
          licensePlate: "EMG-001",
          model: "VW Crafter",
          capacity: 3,
          status: "available",
          description: "Heavy-duty emergency van",
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];

      for (final van in sampleVans) {
        await vanProvider.addVan(van);
      }
      debugPrint('Sample vans initialized successfully');
    }
  } catch (e) {
    debugPrint('Error initializing sample vans: $e');
  }
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => ServiceRequestProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => MedicalProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DocumentProvider>(
          create: (context) => DocumentProvider(authProvider),
          update: (context, auth, previous) =>
              previous ?? DocumentProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => VanProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = AvailabilityProvider();
            provider.startStatusUpdates();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DriverVerificationProvider>(
          create: (context) => DriverVerificationProvider(authProvider),
          update: (context, auth, previous) =>
              previous ?? DriverVerificationProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => PageProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            title: 'Vet2U',
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('ar'), // Arabic
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              // Check if the current device locale is supported
              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale?.languageCode) {
                  return supportedLocale;
                }
              }
              // If device locale is not supported, use English as default
              return const Locale('en');
            },
            theme: VetTheme.light(),
            darkTheme: VetTheme.dark(),
            themeMode: themeProvider.themeMode,
            home: const LoadingScreen(),
            routes: {
              '/role-based-home': (context) => const RoleBasedHome(),
              '/login': (context) => const LoginScreen(),
            },
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/doctor/document-upload':
                  final args = settings.arguments as Map<String, dynamic>?;
                  return MaterialPageRoute(
                    builder: (context) => DocumentUploadScreen(),
                    settings: settings,
                  );
                case '/doctor/medical-record-form':
                  final args = settings.arguments as Map<String, dynamic>?;
                  return MaterialPageRoute(
                    builder: (context) => MedicalRecordFormScreen(
                      record: args?['record'] as MedicalRecord?,
                      pet: args?['pet'] as Pet?,
                      appointment: args?['appointment'] as Appointment?,
                    ),
                    settings: settings,
                  );
                case '/page':
                  final slug = settings.arguments as String?;
                  if (slug != null) {
                    return MaterialPageRoute(
                      builder: (context) => PageViewerScreen(slug: slug),
                      settings: settings,
                    );
                  }
                  return null;
                default:
                  return null;
              }
            },
          );
        },
      ),
    );
  }
}
