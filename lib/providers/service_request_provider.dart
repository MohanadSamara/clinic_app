// lib/providers/service_request_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/service_request.dart';

class ServiceRequestProvider extends ChangeNotifier {
  final List<ServiceRequest> _requests = [];
  bool _isLoading = false;

  List<ServiceRequest> get requests => List.unmodifiable(_requests);
  bool get isLoading => _isLoading;

  Future<void> loadRequests({
    int? ownerId,
    String? status,
    String? requestType,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await DBHelper.instance.getServiceRequests(
        ownerId: ownerId,
        status: status,
        requestType: requestType,
      );
      _requests
        ..clear()
        ..addAll(data.map(ServiceRequest.fromMap));
    } catch (e) {
      debugPrint('Failed to load service requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRequest(ServiceRequest request) async {
    try {
      final id = await DBHelper.instance.insertServiceRequest(request.toMap());
      _requests.insert(0, request.copyWith(id: id));
      await _notifyDoctorsAboutRequest(request.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to create service request: $e');
      return false;
    }
  }

  Future<bool> updateStatus(
    int requestId,
    String status, {
    int? assignedDoctorId,
    DateTime? scheduledDate,
    String? rejectionReason,
  }) async {
    try {
      final updates = {
        'status': status,
        if (assignedDoctorId != null) 'assigned_doctor_id': assignedDoctorId,
        if (scheduledDate != null) 'scheduled_date': scheduledDate.toIso8601String(),
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
      };
      await DBHelper.instance.updateServiceRequest(requestId, updates);
      final index = _requests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _requests[index] = _requests[index].copyWith(
          status: status,
          assignedDoctorId: assignedDoctorId,
          scheduledDate: scheduledDate,
          rejectionReason: rejectionReason,
        );
        if (status == 'approved') {
          await _notifyDriversAboutApproval(_requests[index]);
          await _notifyOwnerAboutUpdate(_requests[index]);
        }
        if (status == 'rejected') {
          await _notifyOwnerAboutUpdate(_requests[index]);
        }
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Failed to update service request: $e');
      return false;
    }
  }

  Future<void> _notifyDoctorsAboutRequest(ServiceRequest request) async {
    try {
      final doctors = await DBHelper.instance.getAllUsers(role: 'doctor');
      for (final doc in doctors) {
        await DBHelper.instance.insertNotification({
          'user_id': doc['id'],
          'title': 'New ${request.requestType} request',
          'message':
              'A ${request.requestType} visit has been requested and needs review.',
          'type': 'alert',
          'is_read': 0,
          'created_at': DateTime.now().toIso8601String(),
          'data': request.id != null ? '{"request_id": ${request.id}}' : null,
        });
      }
    } catch (e) {
      debugPrint('Failed to notify doctors: $e');
    }
  }

  Future<void> _notifyDriversAboutApproval(ServiceRequest request) async {
    try {
      final drivers = await DBHelper.instance.getAllUsers(role: 'driver');
      if (drivers.isEmpty) return;
      for (final driver in drivers) {
        await DBHelper.instance.insertNotification({
          'user_id': driver['id'],
          'title': 'Urgent case approved',
          'message':
              'A ${request.requestType} case is ready for dispatch to ${request.address ?? 'the provided location'}.',
          'type': 'dispatch',
          'is_read': 0,
          'created_at': DateTime.now().toIso8601String(),
          'data': request.id != null ? '{"request_id": ${request.id}}' : null,
        });
      }
    } catch (e) {
      debugPrint('Failed to notify drivers: $e');
    }
  }

  Future<void> _notifyOwnerAboutUpdate(ServiceRequest request) async {
    try {
      final formatter = DateFormat('yMMMd – jm');
      final scheduleText = formatter
          .format((request.scheduledDate ?? DateTime.now()).toLocal());
      await DBHelper.instance.insertNotification({
        'user_id': request.ownerId,
        'title': request.status == 'approved'
            ? 'Urgent visit approved'
            : 'Service request update',
        'message': request.status == 'approved'
            ? 'A medical team is en route. Estimated arrival: $scheduleText.'
            : 'Your request was rejected: ${request.rejectionReason ?? 'Please contact support'}',
        'type': 'reminder',
        'is_read': 0,
        'created_at': DateTime.now().toIso8601String(),
        'data': request.id != null ? '{"request_id": ${request.id}}' : null,
      });
    } catch (e) {
      debugPrint('Failed to notify owner about request update: $e');
    }
  }
}
