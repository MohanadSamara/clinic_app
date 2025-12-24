// Comprehensive test for AR/EN language switching
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/l10n/app_localizations.dart';

void main() {
  group('Translation System Tests', () {
    testWidgets('English translations work correctly', (
      WidgetTester tester,
    ) async {
      // Build a widget tree with English locale
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              // Test some basic English translations
              expect(AppLocalizations.of(context)?.appTitle, equals('Vet2U'));
              expect(AppLocalizations.of(context)?.home, equals('Home'));
              expect(AppLocalizations.of(context)?.pets, equals('Pets'));
              expect(AppLocalizations.of(context)?.book, equals('Book'));
              expect(AppLocalizations.of(context)?.cancel, equals('Cancel'));
              return const Text('Test');
            },
          ),
        ),
      );
    });

    testWidgets('Arabic translations work correctly', (
      WidgetTester tester,
    ) async {
      // Build a widget tree with Arabic locale
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          home: Builder(
            builder: (context) {
              // Test some basic Arabic translations
              expect(AppLocalizations.of(context)?.appTitle, equals('فط2ي'));
              expect(AppLocalizations.of(context)?.home, equals('الرئيسية'));
              expect(
                AppLocalizations.of(context)?.pets,
                equals('الحيوانات الأليفة'),
              );
              expect(AppLocalizations.of(context)?.book, equals('حجز'));
              expect(AppLocalizations.of(context)?.cancel, equals('إلغاء'));
              return const Text('Test');
            },
          ),
        ),
      );
    });

    testWidgets('Parameterized translations work correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context);

              // Test parameterized translations in English
              expect(
                localizations?.welcomeBackUser('John'),
                equals('Welcome back, John!'),
              );

              expect(
                localizations?.petsRegistered,
                equals('pet(s) registered'),
              );

              return const Text('Test');
            },
          ),
        ),
      );
    });

    testWidgets('Arabic parameterized translations work correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          home: Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context);

              // Test parameterized translations in Arabic
              expect(
                localizations?.welcomeBackUser('أحمد'),
                equals('مرحباً بعودتك، أحمد!'),
              );

              expect(
                localizations?.petsRegistered,
                equals('حيوان(حيوانات) مسجل'),
              );

              return const Text('Test');
            },
          ),
        ),
      );
    });

    testWidgets('No fallback to English keys occurs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          home: Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context);

              // These should NOT return the English key as fallback
              final appTitle = localizations?.appTitle;
              final home = localizations?.home;

              // Verify we get actual Arabic text, not English keys
              expect(
                appTitle,
                isNot(equals('appTitle')),
              ); // Should not be the key
              expect(appTitle, equals('فط2ي')); // Should be Arabic

              expect(home, isNot(equals('home'))); // Should not be the key
              expect(home, equals('الرئيسية')); // Should be Arabic

              return const Text('Test');
            },
          ),
        ),
      );
    });

    testWidgets('Language switching works correctly', (
      WidgetTester tester,
    ) async {
      final localeList = <Locale>[const Locale('en'), const Locale('ar')];

      await tester.pumpWidget(
        MaterialApp(
          locale: localeList.first,
          supportedLocales: localeList,
          home: LanguageSwitchTest(),
        ),
      );

      // Initially in English
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('الرئيسية'), findsNothing);

      // Switch to Arabic
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Now in Arabic
      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('All translation categories are accessible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context);

              // Test various categories
              // App basics
              expect(localizations?.appTitle, isNotNull);
              expect(localizations?.welcomeBack, isNotNull);

              // Navigation
              expect(localizations?.home, isNotNull);
              expect(localizations?.pets, isNotNull);
              expect(localizations?.book, isNotNull);

              // Booking
              expect(localizations?.bookAppointment, isNotNull);
              expect(localizations?.selectDate, isNotNull);
              expect(localizations?.selectTime, isNotNull);

              // Profile
              expect(localizations?.profile, isNotNull);
              expect(localizations?.editProfile, isNotNull);

              // Emergency
              expect(localizations?.emergencyRequest, isNotNull);
              expect(localizations?.emergency, isNotNull);

              // Medical
              expect(localizations?.medicalHistory, isNotNull);
              expect(localizations?.prescription, isNotNull);

              return const Text('All categories accessible');
            },
          ),
        ),
      );
    });
  });
}

class LanguageSwitchTest extends StatefulWidget {
  @override
  _LanguageSwitchTestState createState() => _LanguageSwitchTestState();
}

class _LanguageSwitchTestState extends State<LanguageSwitchTest> {
  Locale _currentLocale = const Locale('en');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _currentLocale,
      home: Scaffold(
        body: Column(
          children: [
            Text(AppLocalizations.of(context)?.home ?? 'Missing'),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentLocale = _currentLocale.languageCode == 'en'
                      ? const Locale('ar')
                      : const Locale('en');
                });
              },
              child: const Text('Switch Language'),
            ),
          ],
        ),
      ),
    );
  }
}
