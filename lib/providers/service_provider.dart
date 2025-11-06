// lib/providers/service_provider.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/service.dart';

class ServiceProvider extends ChangeNotifier {
  List<Service> _services = [];
  bool _isLoading = false;

  List<Service> get services => _services;
  bool get isLoading => _isLoading;

  Future<void> loadServices({String? category, bool? activeOnly}) async {
    _isLoading = true;
    // Removed notifyListeners() here to prevent calling during build

    try {
      final data = await DBHelper.instance.getServices(
        category: category,
        activeOnly: activeOnly,
      );
      _services = data.map((item) => Service.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error loading services: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addService(Service service) async {
    try {
      final id = await DBHelper.instance.insertService(service.toMap());
      final newService = service.copyWith(id: id);
      _services.add(newService);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding service: $e');
      return false;
    }
  }

  Future<bool> updateService(Service service) async {
    if (service.id == null) return false;

    try {
      await DBHelper.instance.updateService(service.id!, service.toMap());
      final index = _services.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _services[index] = service;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating service: $e');
      return false;
    }
  }

  Future<bool> deleteService(int id) async {
    try {
      // Note: Need to add deleteService method to DBHelper
      // await DBHelper.instance.deleteService(id);
      _services.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting service: $e');
      return false;
    }
  }

  List<Service> getServicesByCategory(String category) {
    return _services.where((service) => service.category == category).toList();
  }

  Service? getServiceById(int id) {
    return _services.firstWhere((service) => service.id == id);
  }
}
