// lib/providers/van_provider.dart
// Van Provider using Firestore as the single source of truth
// All data synced globally across devices
// OTP Authentication remains UNCHANGED

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/van.dart';

class VanProvider with ChangeNotifier {
  List<Van> _vans = [];
  bool _isLoading = false;
  String? _error;

  List<Van> get vans => _vans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper to convert any ID to int
  int _toIntId(dynamic id) {
    if (id == null) return 0;
    if (id is int) return id;
    if (id is String) {
      return int.tryParse(id) ?? id.hashCode;
    }
    return id.hashCode;
  }

  // ========== LOAD DATA ==========

  Future<void> loadVans() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('vans')
          .orderBy('name')
          .get();

      _vans = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = _toIntId(doc.id);
        return Van.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading vans: $e');
      _error = 'Error loading vans: $e';
      _vans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== ADD VAN ==========

  Future<void> addVan(Van van) async {
    try {
      _isLoading = true;
      notifyListeners();

      final docRef = await _firestore.collection('vans').add({
        'name': van.name,
        'licensePlate': van.licensePlate,
        'model': van.model,
        'capacity': van.capacity,
        'status': van.status,
        'description': van.description,
        'area': van.area,
        'assignedDriverId': van.assignedDriverId?.toString(),
        'assignedDoctorId': van.assignedDoctorId?.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await docRef.update({'id': docRef.id});

      final newVan = van.copyWith(
        id: _toIntId(docRef.id),
        createdAt: DateTime.now().toIso8601String(),
      );

      _vans.add(newVan);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding van: $e');
      _error = 'Error adding van: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== UPDATE VAN ==========

  Future<void> updateVan(dynamic id, Van updatedVan) async {
    try {
      final idInt = _toIntId(id);
      final index = _vans.indexWhere((van) => van.id == idInt);
      if (index == -1) return;

      final docIdStr =
          _vans[index].licensePlate?.replaceAll(' ', '_').toLowerCase() ??
          idInt.toString();

      await _firestore.collection('vans').doc(docIdStr).update({
        'name': updatedVan.name,
        'licensePlate': updatedVan.licensePlate,
        'model': updatedVan.model,
        'capacity': updatedVan.capacity,
        'status': updatedVan.status,
        'description': updatedVan.description,
        'area': updatedVan.area,
        'assignedDriverId': updatedVan.assignedDriverId?.toString(),
        'assignedDoctorId': updatedVan.assignedDoctorId?.toString(),
      });

      _vans[index] = updatedVan.copyWith(id: idInt);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating van: $e');
      _error = 'Error updating van: $e';
      rethrow;
    }
  }

  // ========== DELETE VAN ==========

  Future<void> deleteVan(dynamic id) async {
    try {
      final idInt = _toIntId(id);
      final index = _vans.indexWhere((van) => van.id == idInt);
      if (index == -1) return;

      final van = _vans[index];
      final docIdStr =
          van.licensePlate?.replaceAll(' ', '_').toLowerCase() ??
          idInt.toString();

      await _firestore.collection('vans').doc(docIdStr).delete();

      _vans.removeAt(index);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting van: $e');
      _error = 'Error deleting van: $e';
      rethrow;
    }
  }

  // ========== GET VAN BY ID ==========

  Van? getVanById(dynamic id) {
    final idInt = _toIntId(id);
    try {
      return _vans.firstWhere((van) => van.id == idInt);
    } catch (e) {
      return null;
    }
  }

  // ========== GET VAN BY DRIVER ID ==========

  Future<Van?> getVanByDriverId(dynamic driverId) async {
    try {
      final driverIdStr = _toIntId(driverId).toString();
      final snapshot = await _firestore
          .collection('vans')
          .where('assignedDriverId', isEqualTo: driverIdStr)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      data['id'] = _toIntId(snapshot.docs.first.id);
      return Van.fromMap(data);
    } catch (e) {
      debugPrint('Error getting van by driver id: $e');
      return null;
    }
  }

  // ========== GET VAN BY DOCTOR ID ==========

  Future<Van?> getVanByDoctorId(dynamic doctorId) async {
    try {
      final doctorIdStr = _toIntId(doctorId).toString();
      final snapshot = await _firestore
          .collection('vans')
          .where('assignedDoctorId', isEqualTo: doctorIdStr)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      data['id'] = _toIntId(snapshot.docs.first.id);
      return Van.fromMap(data);
    } catch (e) {
      debugPrint('Error getting van by doctor id: $e');
      return null;
    }
  }

  // ========== ASSIGN VAN ==========

  Future<void> assignVanToDriver(dynamic vanId, dynamic driverId) async {
    try {
      final vanIdInt = _toIntId(vanId);
      final index = _vans.indexWhere((van) => van.id == vanIdInt);
      if (index == -1) return;

      final van = _vans[index];
      final docIdStr =
          van.licensePlate?.replaceAll(' ', '_').toLowerCase() ??
          vanIdInt.toString();

      await _firestore.collection('vans').doc(docIdStr).update({
        'assignedDriverId': _toIntId(driverId).toString(),
        'status': 'assigned',
      });

      final updatedVan = van.copyWith(
        assignedDriverId: _toIntId(driverId),
        status: 'assigned',
      );

      _vans[index] = updatedVan;
      notifyListeners();
    } catch (e) {
      debugPrint('Error assigning van to driver: $e');
      _error = 'Error assigning van: $e';
      rethrow;
    }
  }

  Future<void> assignVanToDoctor(dynamic vanId, dynamic doctorId) async {
    try {
      final vanIdInt = _toIntId(vanId);
      final index = _vans.indexWhere((van) => van.id == vanIdInt);
      if (index == -1) return;

      final van = _vans[index];
      final docIdStr =
          van.licensePlate?.replaceAll(' ', '_').toLowerCase() ??
          vanIdInt.toString();

      await _firestore.collection('vans').doc(docIdStr).update({
        'assignedDoctorId': _toIntId(doctorId).toString(),
        'status': 'assigned',
      });

      final updatedVan = van.copyWith(
        assignedDoctorId: _toIntId(doctorId),
        status: 'assigned',
      );

      _vans[index] = updatedVan;
      notifyListeners();
    } catch (e) {
      debugPrint('Error assigning van to doctor: $e');
      _error = 'Error assigning van: $e';
      rethrow;
    }
  }

  Future<void> assignVanToDoctorAndDriver(
    dynamic vanId,
    dynamic doctorId,
    dynamic driverId,
  ) async {
    try {
      final vanIdInt = _toIntId(vanId);
      final index = _vans.indexWhere((van) => van.id == vanIdInt);
      if (index == -1) return;

      final van = _vans[index];
      final docIdStr =
          van.licensePlate?.replaceAll(' ', '_').toLowerCase() ??
          vanIdInt.toString();

      await _firestore.collection('vans').doc(docIdStr).update({
        'assignedDoctorId': _toIntId(doctorId).toString(),
        'assignedDriverId': _toIntId(driverId).toString(),
        'status': 'assigned',
      });

      final updatedVan = van.copyWith(
        assignedDoctorId: _toIntId(doctorId),
        assignedDriverId: _toIntId(driverId),
        status: 'assigned',
      );

      _vans[index] = updatedVan;
      notifyListeners();
    } catch (e) {
      debugPrint('Error assigning van to doctor and driver: $e');
      _error = 'Error assigning van: $e';
      rethrow;
    }
  }

  // ========== UNASSIGN VAN ==========

  Future<void> unassignVanFromDriver(dynamic vanId) async {
    try {
      final vanIdInt = _toIntId(vanId);
      final index = _vans.indexWhere((van) => van.id == vanIdInt);
      if (index == -1) return;

      final van = _vans[index];
      final docIdStr =
          van.licensePlate?.replaceAll(' ', '_').toLowerCase() ??
          vanIdInt.toString();

      await _firestore.collection('vans').doc(docIdStr).update({
        'assignedDriverId': null,
        'assignedDoctorId': null,
        'status': 'available',
      });

      final updatedVan = van.copyWith(
        assignedDriverId: null,
        assignedDoctorId: null,
        status: 'available',
      );

      _vans[index] = updatedVan;
      notifyListeners();
    } catch (e) {
      debugPrint('Error unassigning van from driver: $e');
      _error = 'Error unassigning van: $e';
      rethrow;
    }
  }

  Future<void> unassignVanFromDoctor(dynamic vanId) async {
    try {
      final vanIdInt = _toIntId(vanId);
      final index = _vans.indexWhere((van) => van.id == vanIdInt);
      if (index == -1) return;

      final van = _vans[index];
      final docIdStr =
          van.licensePlate?.replaceAll(' ', '_').toLowerCase() ??
          vanIdInt.toString();

      await _firestore.collection('vans').doc(docIdStr).update({
        'assignedDoctorId': null,
        'assignedDriverId': null,
        'status': 'available',
      });

      final updatedVan = van.copyWith(
        assignedDoctorId: null,
        assignedDriverId: null,
        status: 'available',
      );

      _vans[index] = updatedVan;
      notifyListeners();
    } catch (e) {
      debugPrint('Error unassigning van from doctor: $e');
      _error = 'Error unassigning van: $e';
      rethrow;
    }
  }

  Future<void> unassignVanFromDoctorAndDriver(dynamic vanId) async {
    try {
      final vanIdInt = _toIntId(vanId);
      final index = _vans.indexWhere((van) => van.id == vanIdInt);
      if (index == -1) return;

      final van = _vans[index];
      final docIdStr =
          van.licensePlate?.replaceAll(' ', '_').toLowerCase() ??
          vanIdInt.toString();

      await _firestore.collection('vans').doc(docIdStr).update({
        'assignedDoctorId': null,
        'assignedDriverId': null,
        'status': 'available',
      });

      final updatedVan = van.copyWith(
        assignedDoctorId: null,
        assignedDriverId: null,
        status: 'available',
      );

      _vans[index] = updatedVan;
      notifyListeners();
    } catch (e) {
      debugPrint('Error unassigning van: $e');
      _error = 'Error unassigning van: $e';
      rethrow;
    }
  }

  // ========== FILTERS ==========

  List<Van> getAvailableVans() {
    return _vans.where((van) => van.isAvailable).toList();
  }

  List<Van> getAssignedVans() {
    return _vans.where((van) => van.isAssigned).toList();
  }

  List<Van> getVansByStatus(String status) {
    return _vans.where((van) => van.status == status).toList();
  }

  // ========== CLEAR ==========

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
