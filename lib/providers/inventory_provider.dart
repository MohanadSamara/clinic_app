// lib/providers/inventory_provider.dart
// Inventory Provider using Supabase as the single source of truth
// Migrated to Supabase database (PostgreSQL) - 2026-01-31

import 'package:flutter/material.dart';
import '../services/supabase_complete_service.dart';
import '../models/inventory_item.dart';

/// InventoryProvider - Supabase Database Integration
///
/// Database: Supabase (PostgreSQL)
/// Tables used: inventory
///
/// All database operations now use Supabase client exclusively.
/// SQLite (DBHelper) has been completely removed.
class InventoryProvider extends ChangeNotifier {
  List<InventoryItem> _inventoryItems = [];
  bool _isLoading = false;

  // Supabase service instance for database operations
  final SupabaseCompleteService _supabaseService =
      SupabaseCompleteService.instance;

  List<InventoryItem> get inventoryItems => _inventoryItems;
  bool get isLoading => _isLoading;
  List<InventoryItem> get lowStockItems =>
      _inventoryItems.where((item) => item.isLowStock).toList();

  Future<void> loadInventoryItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _supabaseService.getAllInventoryItems();
      _inventoryItems = data.map((item) => InventoryItem.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error loading inventory items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addInventoryItem(InventoryItem item) async {
    try {
      final itemData = item.toMap();
      itemData.remove('id'); // Remove id for insert

      final id = await _supabaseService.insertInventoryItem(itemData);
      final newItem = item.copyWith(id: id);
      _inventoryItems.add(newItem);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding inventory item: $e');
      return false;
    }
  }

  Future<bool> updateInventoryItem(InventoryItem item) async {
    if (item.id == null) return false;

    try {
      await _supabaseService.updateInventoryItem(item.id!, item.toMap());

      final index = _inventoryItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _inventoryItems[index] = item;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating inventory item: $e');
      return false;
    }
  }

  Future<bool> updateStockQuantity(String id, int newQuantity) async {
    try {
      await _supabaseService.updateInventoryQuantity(id, newQuantity);

      final index = _inventoryItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _inventoryItems[index] = _inventoryItems[index].copyWith(
          quantity: newQuantity,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating stock quantity: $e');
      return false;
    }
  }

  Future<bool> deleteInventoryItem(String id) async {
    try {
      await _supabaseService.deleteInventoryItem(id);

      _inventoryItems.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting inventory item: $e');
      return false;
    }
  }

  List<InventoryItem> getItemsByCategory(String category) {
    return _inventoryItems.where((item) => item.category == category).toList();
  }

  InventoryItem? getItemById(String id) {
    try {
      return _inventoryItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  double getTotalInventoryValue() {
    return _inventoryItems.fold(
      0,
      (sum, item) => sum + (item.quantity * item.cost),
    );
  }
}
