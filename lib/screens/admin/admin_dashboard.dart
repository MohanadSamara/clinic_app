// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _AdminHomeScreen(),
    const _UserManagementScreen(),
    const _ServiceManagementScreen(),
    const _ReportingScreen(),
    const _AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Services'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _AdminHomeScreen extends StatelessWidget {
  const _AdminHomeScreen();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet2U - Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${user?.name ?? 'Admin'}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    title: 'Total Users',
                    icon: const Icon(Icons.people, color: Colors.white),
                    color: Colors.blue,
                    count: '150', // TODO: Get from provider
                    onTap: () => DefaultTabController.of(context).animateTo(1),
                  ),
                  _DashboardCard(
                    title: 'Active Appointments',
                    icon: const Icon(Icons.schedule, color: Colors.white),
                    color: Colors.green,
                    count: '24', // TODO: Get from provider
                    onTap: () => DefaultTabController.of(context).animateTo(2),
                  ),
                  _DashboardCard(
                    title: 'Revenue Today',
                    icon: const Icon(Icons.attach_money, color: Colors.white),
                    color: Colors.orange,
                    count: '\$1,250', // TODO: Get from provider
                    onTap: () => DefaultTabController.of(context).animateTo(3),
                  ),
                  _DashboardCard(
                    title: 'System Health',
                    icon: const Icon(
                      Icons.health_and_safety,
                      color: Colors.white,
                    ),
                    color: Colors.green,
                    count: '98%', // TODO: Get from provider
                    onTap: () => _showSystemHealth(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSystemHealth(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Health'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Database'),
              subtitle: Text('Operational'),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('API Services'),
              subtitle: Text('Operational'),
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('Backup'),
              subtitle: Text('Last backup: 2 hours ago'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final Color color;
  final String? count;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: icon,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (count != null) ...[
                const SizedBox(height: 4),
                Text(
                  count!,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserManagementScreen extends StatelessWidget {
  const _UserManagementScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: const Center(child: Text('User Management Screen - Coming Soon')),
    );
  }
}

class _ServiceManagementScreen extends StatelessWidget {
  const _ServiceManagementScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Management')),
      body: const Center(
        child: Text('Service Management Screen - Coming Soon'),
      ),
    );
  }
}

class _ReportingScreen extends StatelessWidget {
  const _ReportingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: const Center(child: Text('Reporting Screen - Coming Soon')),
    );
  }
}

class _AdminProfileScreen extends StatelessWidget {
  const _AdminProfileScreen();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.admin_panel_settings,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text('Name: ${user?.name ?? 'N/A'}'),
            Text('Email: ${user?.email ?? 'N/A'}'),
            Text('Phone: ${user?.phone ?? 'N/A'}'),
            Text('Role: ${user?.role ?? 'admin'}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => authProvider.logout(),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
