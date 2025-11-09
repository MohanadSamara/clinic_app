// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/service_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/medical_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/role_based_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auth provider to check for existing session
  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(MyApp(authProvider: authProvider));
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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final localeProvider = Provider.of<LocaleProvider>(context);
          return MaterialApp(
            title: 'Vet2U',
            locale: localeProvider.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ar')],
            theme: ThemeData(
              // Light theme
              brightness: Brightness.light,
              primaryColor: const Color(0xFF2E8B57), // Sea Green
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF2E8B57),
                secondary: Color(0xFF6B8E23), // Olive Drab
                tertiary: Color(0xFFFF9800), // Orange
                surface: Color(0xFFF5F5F5),
                onSurface: Color(0xFF333333),
              ),
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF2E8B57),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              cardTheme: const CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                color: Color(0xFFFFFFFF),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E8B57),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: Color(0xFF2E8B57)),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Color(0xFF333333)),
                bodyMedium: TextStyle(color: Color(0xFF333333)),
                bodySmall: TextStyle(color: Color(0xFF666666)),
                headlineLarge: TextStyle(color: Color(0xFF333333)),
                headlineMedium: TextStyle(color: Color(0xFF333333)),
                headlineSmall: TextStyle(color: Color(0xFF333333)),
                titleLarge: TextStyle(color: Color(0xFF333333)),
                titleMedium: TextStyle(color: Color(0xFF333333)),
                titleSmall: TextStyle(color: Color(0xFF333333)),
              ),
            ),
            darkTheme: ThemeData(
              // Dark theme
              brightness: Brightness.dark,
              primaryColor: const Color(0xFF4CAF50),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF4CAF50),
                secondary: Color(0xFF81C784),
                tertiary: Color(0xFFFF9800), // Orange
                surface: Color(0xFF121212),
                onSurface: Color(0xFFE0E0E0),
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              cardTheme: const CardThemeData(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                color: Color(0xFF2A2A2A),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: Color(0xFF81C784)),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
                bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
                bodySmall: TextStyle(color: Color(0xFFB0B0B0)),
                headlineLarge: TextStyle(color: Color(0xFFE0E0E0)),
                headlineMedium: TextStyle(color: Color(0xFFE0E0E0)),
                headlineSmall: TextStyle(color: Color(0xFFE0E0E0)),
                titleLarge: TextStyle(color: Color(0xFFE0E0E0)),
                titleMedium: TextStyle(color: Color(0xFFE0E0E0)),
                titleSmall: TextStyle(color: Color(0xFFE0E0E0)),
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const RoleBasedHome(),
          );
        },
      ),
    );
  }
}
