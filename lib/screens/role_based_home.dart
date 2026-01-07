// lib/screens/role_based_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import 'doctor/doctor_dashboard.dart';
import 'doctor/doctor_verification_screen.dart';
import 'doctor/doctor_verification_status_screen.dart';
import 'admin/admin_dashboard.dart';
import 'driver/driver_dashboard.dart';
import 'owner/owner_dashboard.dart';
import 'login_screen.dart';
import 'doctor/doctor_registration_documents_screen.dart';
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

        // Check if doctor has pending registration (documents uploaded but user not saved)
        if (authProvider.hasPendingDoctorRegistration) {
          final pendingData = authProvider.pendingDoctorRegistration;
          if (pendingData != null) {
            return DoctorRegistrationDocumentsScreen(
              name: pendingData['name'] as String,
              email: pendingData['email'] as String,
              password: pendingData['password'] as String,
              phone: pendingData['phone']?.toString().isEmpty == true
                  ? null
                  : pendingData['phone']?.toString(),
              area: pendingData['area'] as String,
            );
          }
        }

        // Redirect to login if not authenticated
        if (!authProvider.isLoggedIn || authProvider.user == null) {
          return const LoginScreen();
        }

        final user = authProvider.user!;
        final role = user.role.toLowerCase();

        // Check if doctor needs verification
        if (role == 'doctor' && user.verificationStatus != 'verified') {
          // Show verification status screen for pending/approved/rejected status
          return const DoctorVerificationStatusScreen();
        }

        // Driver verification check removed - drivers can access dashboard directly

        // Route based on user role with proper error handling
        switch (role) {
          case 'doctor':
            return const DoctorDashboard();
          case 'admin':
            return const AdminDashboard();
          case 'driver':
            return const DriverDashboard();
          case 'owner':
            return const OwnerDashboard();
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
