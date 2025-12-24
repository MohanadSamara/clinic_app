// lib/screens/role_based_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import 'owner/owner_dashboard.dart';
import 'doctor/doctor_dashboard.dart';
import 'driver/driver_dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'login_screen.dart';
import '../../translations.dart';

class RoleBasedHome extends StatelessWidget {
  const RoleBasedHome({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading indicator while initializing
        if (!authProvider.isInitialized) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('loadingYourDashboard'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
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
            return const AdminDashboard();
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







