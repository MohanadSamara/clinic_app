// lib/screens/role_based_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'owner/owner_dashboard.dart';
import 'doctor/doctor_dashboard.dart';
import 'driver/driver_dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'login_screen.dart';

class RoleBasedHome extends StatelessWidget {
  const RoleBasedHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn || authProvider.user == null) {
          return const LoginScreen();
        }

        final role = authProvider.user!.role?.toLowerCase();

        switch (role) {
          case 'owner':
            return const OwnerDashboard();
          case 'doctor':
            return const DoctorDashboard();
          case 'driver':
            return const DriverDashboard();
          case 'admin':
            return const AdminDashboard();
          default:
            return const OwnerDashboard(); // Default to owner dashboard
        }
      },
    );
  }
}
