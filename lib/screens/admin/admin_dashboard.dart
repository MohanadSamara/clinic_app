import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'user_management_screen.dart';
import 'service_management_screen.dart';
import 'reporting_screen.dart';
import 'compliance_screen.dart';
import 'data_management_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
              'Welcome, ${auth.user?.name ?? 'Admin'}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            const Text(
              'Admin Functions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFunctionCard(
                    context,
                    'User Management',
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
                    'Service Management',
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
                    'Reporting & Analytics',
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
                    'Compliance & Records',
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
                    'Data Backup & Restore',
                    Icons.backup,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DataManagementScreen(),
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
}
