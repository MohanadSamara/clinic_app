// lib/providers/service_request_provider.dart
// Service Request Provider using Supabase as the single source of truth
// Migrated to Supabase database (PostgreSQL) - 2026-01-31

import 'package:flutter/material.dart';
import '../services/supabase_complete_service.dart';
import '../models/service_request.dart';
import '../models/user.dart';
import '../models/appointment.dart';

/// ServiceRequestProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: service_requests, users, appointments
///
/// All database operations now use Supabase client exclusively.
/// SQLite (DBHelper) has been completely removed.
class ServiceRequestProvider extends ChangeNotifier {
  List<ServiceRequest> _serviceRequests = [];
  bool _isLoading = false;

  // Supabase service instance for database operations
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  List<ServiceRequest> get serviceRequests => _serviceRequests;
  bool get isLoading => _isLoading;

  Future<void> loadServiceRequests({
    dynamic assignedDoctorId,
    String? status,
    String? requestType,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final assignedDoctorIdStr = assignedDoctorId?.toString();

      final data = await _supabaseService.getServiceRequests(
        assignedDoctorId: assignedDoctorIdStr,
        status: status,
        requestType: requestType,
      );

      // Convert String UUID to int for backward compatibility
      _serviceRequests = data.map((item) {
        item['id'] = (item['id'] as String).hashCode;
        return ServiceRequest.fromMap(item);
      }).toList();
    } catch (e) {
      debugPrint('Error loading service requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEmergencyCases({dynamic assignedDoctorId}) async {
    await loadServiceRequests(
      assignedDoctorId: assignedDoctorId?.toString(),
      status: 'pending',
      requestType: 'emergency',
    );
  }

  Future<bool> updateServiceRequestStatus(
    dynamic requestId,
    String status, {
    String? rejectionReason,
    dynamic assignedDoctorId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'rejection_reason': rejectionReason,
      };
      if (assignedDoctorId != null) {
        updateData['assigned_doctor_id'] = assignedDoctorId.toString();
      }

      final requestIdStr = requestId.toString();
      await _supabaseService.updateServiceRequest(requestIdStr, updateData);

      // Update local list
      final requestIdInt = requestId is int ? requestId : requestId.hashCode;
      final index = _serviceRequests.indexWhere(
        (req) => req.id == requestIdInt,
      );
      if (index != -1) {
        final oldRequest = _serviceRequests[index];
        _serviceRequests[index] = oldRequest.copyWith(
          status: status,
          rejectionReason: rejectionReason,
          assignedDoctorId: assignedDoctorId == null
              ? null
              : assignedDoctorId is int
              ? assignedDoctorId.toString()
              : assignedDoctorId.toString(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating service request status: $e');
      return false;
    }
  }

  Future<bool> approveEmergencyCase(dynamic requestId, dynamic doctorId) async {
    try {
      // First update the service request status
      final success = await updateServiceRequestStatus(
        requestId,
        'approved',
        assignedDoctorId: doctorId,
      );

      if (!success) return false;

      // Get the service request details to create an appointment
      final requestIdInt = requestId is int ? requestId : requestId.hashCode;
      final requestIdStr = requestId.toString();
      final requestIndex = _serviceRequests.indexWhere(
        (req) => req.id == requestIdInt,
      );
      if (requestIndex == -1) return false;

      final serviceRequest = _serviceRequests[requestIndex];

      // Get the doctor's linked driver
      final doctorIdStr = doctorId.toString();
      final doctorData = await _supabaseService.getUserById(doctorIdStr);
      if (doctorData == null) return false;

      final doctor = User.fromMap(doctorData);
      final driverId = doctor.linkedDriverId;

      // Create an appointment for the driver to see on the map
      final appointmentData = {
        'owner_id': serviceRequest.ownerId?.toString() ?? '',
        'pet_id': serviceRequest.petId?.toString() ?? '',
        'service_type': 'Emergency Care',
        'description': serviceRequest.description,
        'scheduled_at': DateTime.now().toIso8601String(),
        'status': 'approved',
        'address': serviceRequest.address,
        'doctor_id': doctorIdStr,
        'driver_id': driverId?.toString(),
        'urgency_level': 'emergency',
        'location_lat': serviceRequest.latitude,
        'location_lng': serviceRequest.longitude,
        'service_request_id': requestIdStr,
      };

      final appointmentId = await _supabaseService.insertAppointment(
        appointmentData,
      );

      // Create a basic appointment object for local reference
      Appointment(
        id: appointmentId,
        ownerId: serviceRequest.ownerId,
        petId: serviceRequest.petId,
        serviceType: 'Emergency Care',
        description: serviceRequest.description,
        scheduledAt: DateTime.now().toIso8601String(),
        status: 'approved',
        address: serviceRequest.address,
        doctorId: doctorId is int ? doctorId.toString() : doctorId.toString(),
        driverId: driverId?.toString(),
        urgencyLevel: 'emergency',
        locationLat: serviceRequest.latitude,
        locationLng: serviceRequest.longitude,
        serviceRequestId: serviceRequest.id,
      );

      return true;
    } catch (e) {
      debugPrint('Error approving emergency case: $e');
      return false;
    }
  }

  Future<bool> rejectEmergencyCase(dynamic requestId, String reason) async {
    return await updateServiceRequestStatus(
      requestId,
      'rejected',
      rejectionReason: reason,
    );
  }

  List<ServiceRequest> getEmergencyCases() {
    return _serviceRequests
        .where((req) => req.requestType == 'emergency')
        .toList();
  }

  List<ServiceRequest> getPendingEmergencyCases() {
    return _serviceRequests
        .where(
          (req) => req.requestType == 'emergency' && req.status == 'pending',
        )
        .toList();
  }

  Future<bool> createServiceRequest(ServiceRequest serviceRequest) async {
    try {
      final requestData = serviceRequest.toMap();
      requestData.remove('id'); // Remove id for insert

      final id = await _supabaseService.insertServiceRequest(requestData);
      // Convert String UUID to int for backward compatibility
      final idInt = id.hashCode;

      final newRequest = serviceRequest.copyWith(id: id);
      _serviceRequests.add(newRequest);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating service request: $e');
      return false;
    }
  }
}
