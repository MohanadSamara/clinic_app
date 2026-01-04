// lib/services/app_close_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/medical_provider.dart';
import '../providers/service_request_provider.dart';
import '../providers/document_provider.dart';
import '../providers/van_provider.dart';
import '../providers/availability_provider.dart';

class AppCloseService {
  static final AppCloseService _instance = AppCloseService._internal();
  factory AppCloseService() => _instance;
  AppCloseService._internal();

  Future<void> saveDataBeforeExit({
    required AuthProvider authProvider,
    required PetProvider petProvider,
    required AppointmentProvider appointmentProvider,
    required MedicalProvider medicalProvider,
    required ServiceRequestProvider serviceRequestProvider,
    required DocumentProvider documentProvider,
    required VanProvider vanProvider,
    required AvailabilityProvider availabilityProvider,
  }) async {
    try {
      // Update user availability to offline
      if (authProvider.user?.id != null) {
        availabilityProvider.updateUserAvailability(
          authProvider.user!.id!,
          'offline',
        );
      }

      // Prepare data to save
      final appData = {
        'user': authProvider.user?.toJson(),
        'pets': petProvider.pets.map((pet) => pet.toJson()).toList(),
        'appointments': appointmentProvider.appointments
            .map((apt) => apt.toJson())
            .toList(),
        'medicalRecords': medicalProvider.medicalRecords
            .map((record) => record.toJson())
            .toList(),
        'serviceRequests': serviceRequestProvider.serviceRequests
            .map((req) => req.toJson())
            .toList(),
        'documents': documentProvider.documents
            .map((doc) => doc.toJson())
            .toList(),
        'vans': vanProvider.vans.map((van) => van.toJson()).toList(),
        'savedAt': DateTime.now().toIso8601String(),
      };

      // Save to Firebase Firestore
      if (authProvider.user?.id != null) {
        final userId = authProvider.user!.id!.toString();
        final firestore = FirebaseFirestore.instance;

        // Save backup data to user's document
        await firestore.collection('user_backups').doc(userId).set({
          'userId': userId,
          'backupData': appData,
          'lastBackup': FieldValue.serverTimestamp(),
        });

        debugPrint('App data saved to Firebase for user: $userId');
      } else {
        debugPrint('No authenticated user, cannot save to Firebase');
      }

      // Log out the user before closing the app
      authProvider.logout();

      debugPrint('Data saved before app exit');
    } catch (e) {
      debugPrint('Error saving data before exit: $e');
    }
  }

  void performAppExit() {
    if (kIsWeb) {
      // For web: Attempt to close the browser tab
      try {
        html.window.close();
      } catch (e) {
        debugPrint('Unable to close browser tab: $e');
        // Fallback: Show confirmation that data is saved
        // (This would be handled by the calling widget)
      }
    } else {
      // For mobile and desktop platforms (non-web)
      bool isMobile = false;
      try {
        // Only access Platform class on non-web platforms
        if (!kIsWeb) {
          isMobile = Platform.isAndroid || Platform.isIOS;
        }
      } catch (e) {
        // If Platform access fails, assume desktop
        isMobile = false;
      }

      if (isMobile) {
        try {
          // Note: SystemNavigator.pop() requires import 'dart:ui'
          // This will be imported in the calling file
        } catch (e) {
          debugPrint('Unable to close app on mobile platform: $e');
        }
      } else {
        // For desktop: Attempt to close the application window
        try {
          exit(0);
        } catch (e) {
          debugPrint('Unable to close desktop app: $e');
          // Fallback: Show message
          // (This would be handled by the calling widget)
        }
      }
    }
  }
}
