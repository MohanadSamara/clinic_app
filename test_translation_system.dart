// Test script to verify translation system functionality
import 'dart:io';

void main() async {
  print('🔍 Testing Translation System...');

  // Read the translation mapping file
  final translationsFile = File('lib/translations.dart');
  if (!translationsFile.existsSync()) {
    print('❌ translations.dart file not found');
    return;
  }

  final translationsContent = await translationsFile.readAsString();

  // Read the AppLocalizations base class
  final appLocFile = File('lib/l10n/app_localizations.dart');
  if (!appLocFile.existsSync()) {
    print('❌ app_localizations.dart file not found');
    return;
  }

  final appLocContent = await appLocFile.readAsString();

  // Extract all translation keys from the mapping
  final keyRegex = RegExp(r"'(\w+)':\s*\(l\) => l\.(\w+)", multiLine: true);
  final keys = <String, String>{};

  for (final match in keyRegex.allMatches(translationsContent)) {
    keys[match.group(1)!] = match.group(2)!;
  }

  print('📊 Found ${keys.length} translation keys in mapping');

  // Check for missing implementations
  final missingKeys = <String>[];
  final methodRegex = RegExp(
    r'String get (\w+)|String (\w+)\(Object \w+\)',
    multiLine: true,
  );

  for (final key in keys.keys) {
    final methodName = keys[key]!;
    final hasMethod =
        methodRegex.hasMatch(appLocContent) &&
        (appLocContent.contains('get $methodName') ||
            appLocContent.contains(' $methodName(Object'));

    if (!hasMethod) {
      missingKeys.add('$key -> $methodName');
    }
  }

  if (missingKeys.isNotEmpty) {
    print('⚠️  Missing translation implementations:');
    for (final key in missingKeys) {
      print('   - $key');
    }
  } else {
    print('✅ All translation keys have implementations');
  }

  // Check for parameterized methods without proper handling
  final parameterizedKeys = <String>[];
  for (final entry in keys.entries) {
    if (appLocContent.contains('${entry.value}(Object')) {
      parameterizedKeys.add(entry.key);
    }
  }

  if (parameterizedKeys.isNotEmpty) {
    print('🔧 Found ${parameterizedKeys.length} parameterized methods:');
    for (final key in parameterizedKeys) {
      print('   - $key');
    }
  }

  // Check English translation file
  final enFile = File('lib/l10n/app_localizations_en.dart');
  if (enFile.existsSync()) {
    final enContent = await enFile.readAsString();
    print('✅ English translation file exists (${enContent.length} characters)');
  } else {
    print('❌ English translation file missing');
  }

  // Check Arabic translation file
  final arFile = File('lib/l10n/app_localizations_ar.dart');
  if (arFile.existsSync()) {
    final arContent = await arFile.readAsString();
    print('✅ Arabic translation file exists (${arContent.length} characters)');
  } else {
    print('❌ Arabic translation file missing');
  }

  // Test that key categories are well organized
  final categories = <String>[];
  final categoryRegex = RegExp(r'// (.+)', multiLine: true);
  for (final match in categoryRegex.allMatches(translationsContent)) {
    final category = match.group(1)!;
    if (category.length > 3 && !category.contains('App basics')) {
      categories.add(category);
    }
  }

  print('📂 Translation categories found: ${categories.length}');

  // Summary
  print('\n📋 Translation System Test Summary:');
  print('   Total keys: ${keys.length}');
  print('   Missing implementations: ${missingKeys.length}');
  print('   Parameterized methods: ${parameterizedKeys.length}');
  print('   Categories: ${categories.length}');

  if (missingKeys.isEmpty) {
    print('🎉 Translation mapping is complete!');
  } else {
    print('⚠️  Some translation keys need attention');
  }

  print('\n✅ Translation system test completed');
}
