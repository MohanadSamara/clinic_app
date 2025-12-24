import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../../translations.dart';
import 'user_management_screen.dart';
import 'service_management_screen.dart';
import 'reporting_screen.dart';
import 'compliance_screen.dart';
import 'data_management_screen.dart';
import 'van_management_screen.dart';
import 'area_management_screen.dart';
import 'system_settings_screen.dart';
import 'audit_logs_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Check if user is admin
    if (auth.user?.role.toLowerCase() != 'admin') {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('accessDenied'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                context.tr('accessDenied'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(context.tr('noPermissionToAccessPage')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('adminDashboard')),
        actions: [
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              return IconButton(
                icon: Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => _showLanguageDialog(context, localeProvider),
                tooltip: context.tr('changeLanguage'),
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
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                'welcomeName',
                args: {'name': auth.user?.name ?? context.tr('admin')},
              ),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('adminFunctions'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildFunctionCard(
                    context,
                    context.tr('userManagement'),
                    Icons.people,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserManagementScreen(),
                      ),
                    ),
                  ),
                  _buildFunctionCard(
                    context,
                    context.tr('serviceManagement'),
                    Icons.medical_services,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ServiceManagementScreen(),
                      ),
                    ),
                  ),
                  _buildFunctionCard(
                    context,
                    context.tr('reportingAnalytics'),
                    Icons.analytics,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportingScreen(),
                      ),
                    ),
                  ),
                  _buildFunctionCard(
                    context,
                    context.tr('complianceRecords'),
                    Icons.verified,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ComplianceScreen(),
                      ),
                    ),
                  ),
                  _buildFunctionCard(
                    context,
                    context.tr('dataBackupRestore'),
                    Icons.backup,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DataManagementScreen(),
                      ),
                    ),
                  ),
                  _buildFunctionCard(
                    context,
                    context.tr('vanManagement'),
                    Icons.directions_car,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VanManagementScreen(),
                      ),
                    ),
                  ),
                  _buildFunctionCard(
                    context,
                    context.tr('areaManagement'),
                    Icons.location_on,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AreaManagementScreen(),
                      ),
                    ),
                  ),
                  _buildFunctionCard(
                    context,
                    context.tr('systemSettings'),
                    Icons.settings,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SystemSettingsScreen(),
                      ),
                    ),
                  ),
                  _buildFunctionCard(
                    context,
                    context.tr('auditLogs'),
                    Icons.history,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AuditLogsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
