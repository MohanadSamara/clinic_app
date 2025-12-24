import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/service_request.dart';
import '../models/user.dart';
import '../models/appointment.dart';

class ServiceRequestProvider extends ChangeNotifier {
  List<ServiceRequest> _serviceRequests = [];
  bool _isLoading = false;

  List<ServiceRequest> get serviceRequests => _serviceRequests;
  bool get isLoading => _isLoading;

  Future<void> loadServiceRequests({
    int? assignedDoctorId,
    String? status,
    String? requestType,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DBHelper.instance.getServiceRequests(
        assignedDoctorId: assignedDoctorId,
        status: status,
        requestType: requestType,
      );
      _serviceRequests = data
          .map((item) => ServiceRequest.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error loading service requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEmergencyCases({int? assignedDoctorId}) async {
    await loadServiceRequests(
      assignedDoctorId: assignedDoctorId,
      status: 'pending',
      requestType: 'emergency',
    );
  }

  Future<bool> updateServiceRequestStatus(
    int requestId,
    String status, {
    String? rejectionReason,
    int? assignedDoctorId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'rejection_reason': rejectionReason,
      };
      if (assignedDoctorId != null) {
        updateData['assigned_doctor_id'] = assignedDoctorId;
      }

      await DBHelper.instance.updateServiceRequest(requestId, updateData);

      // Update local list
      final index = _serviceRequests.indexWhere((req) => req.id == requestId);
      if (index != -1) {
        _serviceRequests[index] = _serviceRequests[index].copyWith(
          status: status,
          rejectionReason: rejectionReason,
          assignedDoctorId:
              assignedDoctorId ?? _serviceRequests[index].assignedDoctorId,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating service request status: $e');
      return false;
    }
  }

  Future<bool> approveEmergencyCase(int requestId, int doctorId) async {
    try {
      // First update the service request status
      final success = await updateServiceRequestStatus(
        requestId,
        'approved',
        assignedDoctorId: doctorId,
      );

      if (!success) return false;

      // Get the service request details to create an appointment
      final requestIndex = _serviceRequests.indexWhere(
        (req) => req.id == requestId,
      );
      if (requestIndex == -1) return false;

      final serviceRequest = _serviceRequests[requestIndex];

      // Get the doctor's linked driver
      final doctorData = await DBHelper.instance.getUserById(doctorId);
      if (doctorData == null) return false;

      final doctor = User.fromMap(doctorData);
      final driverId = doctor.linkedDriverId;

      // Create an appointment for the driver to see on the map
      final appointmentData = {
        'owner_id': serviceRequest.ownerId,
        'pet_id': serviceRequest.petId,
        'service_type': 'Emergency Care',
        'description': serviceRequest.description,
        'scheduled_at': DateTime.now().toIso8601String(),
        'status': 'approved',
        'address': serviceRequest.address,
        'doctor_id': doctorId,
        'driver_id': driverId,
        'urgency_level': 'emergency',
        'location_lat': serviceRequest.latitude,
        'location_lng': serviceRequest.longitude,
        'service_request_id': serviceRequest.id,
      };

      final appointmentId = await DBHelper.instance.insertAppointment(
        appointmentData,
      );

      // Create a basic appointment object for local reference
      final createdAppointment = Appointment(
        id: appointmentId,
        ownerId: serviceRequest.ownerId,
        petId: serviceRequest.petId,
        serviceType: 'Emergency Care',
        description: serviceRequest.description,
        scheduledAt: DateTime.now().toIso8601String(),
        status: 'approved',
        address: serviceRequest.address,
        doctorId: doctorId,
        driverId: driverId,
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

  Future<bool> rejectEmergencyCase(int requestId, String reason) async {
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
      final id = await DBHelper.instance.insertServiceRequest(
        serviceRequest.toMap(),
      );
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







