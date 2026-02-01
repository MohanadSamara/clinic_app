// lib/providers/service_provider.dart
// Service Provider using Supabase as the single source of truth
// Migrated to Supabase database (PostgreSQL) - 2026-01-31

import 'package:flutter/material.dart';
import '../services/supabase_complete_service.dart';
import '../models/service.dart';

/// ServiceProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: services
///
/// All database operations now use Supabase client exclusively.
/// SQLite (DBHelper) has been completely removed.
class ServiceProvider extends ChangeNotifier {
  List<Service> _services = [];
  bool _isLoading = false;

  // Supabase service instance for database operations
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  List<Service> get services => _services;
  bool get isLoading => _isLoading;

  Future<void> loadServices({String? category, bool? activeOnly}) async {
    _isLoading = true;
    // Removed notifyListeners() here to prevent calling during build

    try {
      final data = await _supabaseService.getServices(
        category: category,
        activeOnly: activeOnly,
      );

      // Convert String UUID to int for backward compatibility
      _services = data.map((item) {
        item['id'] = (item['id'] as String).hashCode;
        return Service.fromMap(item);
      }).toList();
    } catch (e) {
      debugPrint('Error loading services: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addService(Service service) async {
    try {
      final serviceData = service.toMap();
      serviceData.remove('id'); // Remove id for insert

      final id = await _supabaseService.insertService(serviceData);
      // Convert String UUID to int for backward compatibility
      final idInt = id.hashCode;

      final newService = service.copyWith(id: idInt);
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
      final idStr = service.id.toString();
      await _supabaseService.updateService(idStr, service.toMap());

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

  Future<bool> deleteService(dynamic id) async {
    try {
      final idStr = id.toString();
      await _supabaseService.deleteService(idStr);

      final idInt = id is int ? id : id.hashCode;
      _services.removeWhere((s) => s.id == idInt);
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

  Service? getServiceById(dynamic id) {
    final idInt = id is int ? id : id.hashCode;
    try {
      return _services.firstWhere((service) => service.id == idInt);
    } catch (e) {
      return null;
    }
  }
}
