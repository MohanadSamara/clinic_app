// lib/providers/inventory_provider.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/inventory_item.dart';

class InventoryProvider extends ChangeNotifier {
  List<InventoryItem> _inventoryItems = [];
  bool _isLoading = false;

  List<InventoryItem> get inventoryItems => _inventoryItems;
  bool get isLoading => _isLoading;
  List<InventoryItem> get lowStockItems =>
      _inventoryItems.where((item) => item.isLowStock).toList();

  Future<void> loadInventoryItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DBHelper.instance.getAllInventoryItems();
      _inventoryItems = data
          .map((item) => InventoryItem.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('Error loading inventory items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addInventoryItem(InventoryItem item) async {
    try {
      final id = await DBHelper.instance.insertInventoryItem(item.toMap());
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
      await DBHelper.instance.updateInventoryItem(item.id!, item.toMap());
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

  Future<bool> updateStockQuantity(int id, int newQuantity) async {
    try {
      await DBHelper.instance.updateInventoryQuantity(id, newQuantity);
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

  Future<bool> deleteInventoryItem(int id) async {
    try {
      await DBHelper.instance.deleteInventoryItem(id);
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

  InventoryItem? getItemById(int id) {
    return _inventoryItems.firstWhere((item) => item.id == id);
  }

  double getTotalInventoryValue() {
    return _inventoryItems.fold(
      0,
      (sum, item) => sum + (item.quantity * item.cost),
    );
  }
}
