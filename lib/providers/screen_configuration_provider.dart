import 'package:flutter/material.dart';
import '../services/supabase_complete_service.dart';
import '../models/screen_configuration.dart';

class ScreenConfigurationProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<ScreenConfiguration> _configurations = [];
  String? _currentRole;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ScreenConfiguration> get configurations => _configurations;
  String? get currentRole => _currentRole;

  // Get configurations for a specific role
  List<ScreenConfiguration> getConfigurationsForRole(String role) {
    return _configurations
        .where((config) => config.role.toLowerCase() == role.toLowerCase())
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  // Get enabled and visible configurations for a role
  List<ScreenConfiguration> getVisibleScreensForRole(String role) {
    return getConfigurationsForRole(role)
        .where((config) => config.isEnabled && config.isVisible)
        .toList();
  }

  // Get configuration by screen ID and role
  ScreenConfiguration? getConfiguration(String role, String screenId) {
    try {
      return _configurations.firstWhere(
        (config) =>
            config.role.toLowerCase() == role.toLowerCase() &&
            config.screenId == screenId,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if a screen is enabled for a role
  bool isScreenEnabled(String role, String screenId) {
    final config = getConfiguration(role, screenId);
    return config?.isEnabled ?? true;
  }

  // Check if a screen is visible for a role
  bool isScreenVisible(String role, String screenId) {
    final config = getConfiguration(role, screenId);
    return config?.isVisible ?? true;
  }

  // Load all screen configurations
  Future<void> loadConfigurations() async {
    _setLoading(true);
    try {
      final supabaseService = SupabaseCompleteService.instance;
      final configs = await supabaseService.getAllScreenConfigurations();
      _configurations = configs
          .map((map) => ScreenConfiguration.fromMap(map))
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load screen configurations: $e';
      // If database fails, use default configurations
      _loadDefaultConfigurations();
    } finally {
      _setLoading(false);
    }
  }

  // Load configurations for a specific role
  Future<void> loadConfigurationsForRole(String role) async {
    _setLoading(true);
    _currentRole = role;
    try {
      final supabaseService = SupabaseCompleteService.instance;
      final configs = await supabaseService.getScreenConfigurationsForRole(role);
      
      // Remove existing configs for this role
      _configurations.removeWhere(
        (config) => config.role.toLowerCase() == role.toLowerCase(),
      );
      
      // Add new configs
      _configurations.addAll(
        configs.map((map) => ScreenConfiguration.fromMap(map)),
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to load configurations for $role: $e';
      // Load defaults for this role
      final defaults = ScreenConfiguration.getDefaultScreensForRole(role);
      _configurations.removeWhere(
        (config) => config.role.toLowerCase() == role.toLowerCase(),
      );
      _configurations.addAll(defaults);
    } finally {
      _setLoading(false);
    }
  }

  // Initialize default configurations for all roles
  Future<void> initializeDefaultConfigurations() async {
    _setLoading(true);
    try {
      final supabaseService = SupabaseCompleteService.instance;
      
      for (final role in ScreenConfiguration.availableRoles) {
        // Check if configurations exist for this role
        final existing = await supabaseService.getScreenConfigurationsForRole(role);
        
        if (existing.isEmpty) {
          // Insert default configurations
          final defaults = ScreenConfiguration.getDefaultScreensForRole(role);
          for (final config in defaults) {
            await supabaseService.insertScreenConfiguration(config.toMap());
          }
        }
      }
      
      await loadConfigurations();
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize default configurations: $e';
      _loadDefaultConfigurations();
    } finally {
      _setLoading(false);
    }
  }

  // Create new screen configuration
  Future<bool> createConfiguration(ScreenConfiguration config) async {
    _setLoading(true);
    try {
      final supabaseService = SupabaseCompleteService.instance;
      final id = await supabaseService.insertScreenConfiguration(config.toMap());
      final newConfig = config.copyWith(id: id);
      _configurations.add(newConfig);
      await _logAuditAction('create_screen_config', 'Created screen config: ${config.screenName} for ${config.role}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create configuration: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update screen configuration
  Future<bool> updateConfiguration(ScreenConfiguration config) async {
    if (config.id == null) return false;

    _setLoading(true);
    try {
      final supabaseService = SupabaseCompleteService.instance;
      await supabaseService.updateScreenConfiguration(config.id!, config.toMap());
      final index = _configurations.indexWhere((c) => c.id == config.id);
      if (index != -1) {
        _configurations[index] = config;
      }
      await _logAuditAction('update_screen_config', 'Updated screen config: ${config.screenName} for ${config.role}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update configuration: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle screen enabled status
  Future<bool> toggleScreenEnabled(String role, String screenId) async {
    final config = getConfiguration(role, screenId);
    if (config == null) return false;

    final updated = config.copyWith(isEnabled: !config.isEnabled);
    return await updateConfiguration(updated);
  }

  // Toggle screen visibility
  Future<bool> toggleScreenVisibility(String role, String screenId) async {
    final config = getConfiguration(role, screenId);
    if (config == null) return false;

    final updated = config.copyWith(isVisible: !config.isVisible);
    return await updateConfiguration(updated);
  }

  // Update screen sort order
  Future<bool> updateSortOrder(String role, String screenId, int newOrder) async {
    final config = getConfiguration(role, screenId);
    if (config == null) return false;

    final updated = config.copyWith(sortOrder: newOrder);
    return await updateConfiguration(updated);
  }

  // Delete screen configuration
  Future<bool> deleteConfiguration(ScreenConfiguration config) async {
    if (config.id == null) return false;

    _setLoading(true);
    try {
      final supabaseService = SupabaseCompleteService.instance;
      await supabaseService.deleteScreenConfiguration(config.id!);
      _configurations.removeWhere((c) => c.id == config.id);
      await _logAuditAction('delete_screen_config', 'Deleted screen config: ${config.screenName} for ${config.role}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete configuration: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Bulk update configurations for a role
  Future<bool> bulkUpdateForRole(String role, List<ScreenConfiguration> configs) async {
    _setLoading(true);
    try {
      final supabaseService = SupabaseCompleteService.instance;
      
      // Delete existing configs for this role
      await supabaseService.deleteScreenConfigurationsForRole(role);
      _configurations.removeWhere(
        (config) => config.role.toLowerCase() == role.toLowerCase(),
      );
      
      // Insert new configs
      for (final config in configs) {
        final id = await supabaseService.insertScreenConfiguration(config.toMap());
        _configurations.add(config.copyWith(id: id));
      }
      
      await _logAuditAction('bulk_update_screen_configs', 'Bulk updated screen configs for $role');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to bulk update configurations: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset to defaults for a role
  Future<bool> resetToDefaults(String role) async {
    _setLoading(true);
    try {
      final defaults = ScreenConfiguration.getDefaultScreensForRole(role);
      return await bulkUpdateForRole(role, defaults);
    } catch (e) {
      _error = 'Failed to reset configurations: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get available icons
  Map<String, String> get availableIcons => ScreenConfiguration.iconMapping;

  // Get available categories
  List<String> get availableCategories => ScreenConfiguration.availableCategories;

  // Get available roles
  List<String> get availableRoles => ScreenConfiguration.availableRoles;

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _loadDefaultConfigurations() {
    _configurations = [];
    for (final role in ScreenConfiguration.availableRoles) {
      _configurations.addAll(
        ScreenConfiguration.getDefaultScreensForRole(role),
      );
    }
    notifyListeners();
  }

  Future<void> _logAuditAction(String action, String details) async {
    try {
      final supabaseService = SupabaseCompleteService.instance;
      await supabaseService.insertAuditLog({
        'action': action,
        'details': details,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': null,
        'document_id': null,
      });
    } catch (e) {
      debugPrint('Failed to log audit action: $e');
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh configurations
  Future<void> refresh() async {
    await loadConfigurations();
  }
}
