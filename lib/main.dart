// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/service_provider.dart';
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
import 'models/van.dart';
import 'services/notification_service.dart';
import 'screens/loading_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase globally
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize auth provider to check for existing session
  final authProvider = AuthProvider();
  await authProvider.initialize();

  // Initialize sample vans for testing
  await _initializeSampleVans();

  runApp(MyApp(authProvider: authProvider));
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
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
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
            supportedLocales: const [Locale('en'), Locale('ar')],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const LoadingScreen(),
          );
        },
      ),
    );
  }
}
