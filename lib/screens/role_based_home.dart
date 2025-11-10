// lib/screens/role_based_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'owner/owner_dashboard.dart';
import 'doctor/doctor_dashboard.dart';
import 'login_screen.dart';
import 'driver/driver_dashboard.dart';

class RoleBasedHome extends StatelessWidget {
  const RoleBasedHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading indicator while initializing
        if (!authProvider.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Redirect to login if not authenticated
        if (!authProvider.isLoggedIn || authProvider.user == null) {
          return const LoginScreen();
        }

        final user = authProvider.user!;
        final role = user.role.toLowerCase();

        // Route based on user role with proper error handling
        switch (role) {
          case 'owner':
            return const OwnerDashboard();
          case 'doctor':
            return const DoctorDashboard();
          case 'admin':
            // TODO: Implement AdminDashboard when needed
            return const Scaffold(
              body: Center(child: Text('Admin Dashboard - Coming Soon')),
            );
          case 'driver':
            return const DriverDashboard();
          default:
            // Log unexpected role for debugging
            debugPrint(
              'Unexpected user role: $role, defaulting to owner dashboard',
            );
            return const OwnerDashboard();
        }
      },
    );
  }
}
