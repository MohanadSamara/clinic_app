import 'package:flutter/material.dart';
import '../services/supabase_complete_service.dart';
import '../models/page.dart' as page_model;

class PageProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<page_model.Page> _pages = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<page_model.Page> get pages => _pages;
  List<page_model.Page> get publishedPages =>
      _pages.where((page) => page.isPublished).toList();

  // Load all pages
  Future<void> loadPages() async {
    _setLoading(true);
    try {
      final supabaseService = SupabaseCompleteService.instance;
      final pageMaps = await supabaseService.getAllPages();
      _pages = pageMaps.map((map) => page_model.Page.fromMap(map)).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load pages: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Get page by slug
  Future<page_model.Page?> getPageBySlug(String slug) async {
    try {
      final supabaseService = SupabaseCompleteService.instance;
      final pageMap = await supabaseService.getPageBySlug(slug);
      if (pageMap != null) {
        return page_model.Page.fromMap(pageMap);
      }
      return null;
    } catch (e) {
      _error = 'Failed to get page: $e';
      return null;
    }
  }

  // Create new page
  Future<bool> createPage(page_model.Page page) async {
    _setLoading(true);
    try {
      final supabaseService = SupabaseCompleteService.instance;
      final id = await supabaseService.insertPage(page.toMap());
      final newPage = page.copyWith(id: id);
      _pages.add(newPage);
      await logAuditAction('create_page', 'Created page: ${page.title}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create page: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update page
  Future<bool> updatePage(page_model.Page page) async {
    if (page.id == null) return false;

    _setLoading(true);
    try {
      final supabaseService = SupabaseCompleteService.instance;
      await supabaseService.updatePage(page.id!, page.toMap());
      final index = _pages.indexWhere((p) => p.id == page.id);
      if (index != -1) {
        _pages[index] = page;
      }
      await logAuditAction('update_page', 'Updated page: ${page.title}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update page: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete page
  Future<bool> deletePage(page_model.Page page) async {
    if (page.id == null) return false;

    _setLoading(true);
    try {
      final supabaseService = SupabaseCompleteService.instance;
      await supabaseService.deletePage(page.id!);
      _pages.removeWhere((p) => p.id == page.id);
      await logAuditAction('delete_page', 'Deleted page: ${page.title}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete page: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Publish/unpublish page
  Future<bool> togglePublishStatus(page_model.Page page) async {
    final updatedPage = page.copyWith(isPublished: !page.isPublished);
    return await updatePage(updatedPage);
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> logAuditAction(String action, String details) async {
    try {
      final supabaseService = SupabaseCompleteService.instance;
      await supabaseService.insertAuditLog({
        'action': action,
        'details': details,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': null, // TODO: Add current user ID when auth is available
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
}
