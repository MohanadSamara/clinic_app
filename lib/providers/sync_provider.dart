// lib/providers/sync_provider.dart
/// Provider for managing sync state and operations
/// Provides sync status and controls to the UI

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';
import '../models/sync_tracker.dart';

/// Sync status for UI display
enum SyncUiStatus { idle, syncing, success, error, pendingChanges }

/// Provider for managing sync operations
class SyncProvider with ChangeNotifier {
  final SyncService _syncService = SyncService.instance;

  // UI State
  SyncUiStatus _status = SyncUiStatus.idle;
  String _statusMessage = 'Ready to sync';
  double _progress = 0.0;
  String _currentOperation = '';
  int _syncedCount = 0;
  int _failedCount = 0;
  DateTime? _lastSyncTime;
  String? _errorMessage;
  bool _isPeriodicSyncEnabled = true;

  // Stream subscriptions
  StreamSubscription? _syncStateSubscription;

  // ========== Initialization ==========

  /// Initialize the sync provider
  void initialize() {
    // Listen to sync state changes
    _syncStateSubscription = _syncService.syncStateStream.listen(
      _onSyncStateChanged,
    );

    // Set up callbacks
    _syncService.setProgressCallback(_onProgress);
    _syncService.setCompleteCallback(_onComplete);
    _syncService.setErrorCallback(_onError);

    // Start periodic sync if enabled
    if (_isPeriodicSyncEnabled) {
      _syncService.startPeriodicSync();
    }

    _updateStatus(SyncUiStatus.idle, 'Ready to sync');
  }

  // ========== Public Methods ==========

  /// Perform a full sync
  Future<void> performFullSync({bool clearExisting = false}) async {
    if (_status == SyncUiStatus.syncing) {
      _updateStatus(SyncUiStatus.error, 'Sync already in progress');
      return;
    }

    _updateStatus(SyncUiStatus.syncing, 'Starting full sync...');
    _progress = 0.0;
    _currentOperation = 'Initializing...';
    _syncedCount = 0;
    _failedCount = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _syncService.performFullSync(
        clearExisting: clearExisting,
      );

      if (result.success) {
        _lastSyncTime = DateTime.now();
        _updateStatus(
          SyncUiStatus.success,
          'Full sync completed: ${result.syncedCount} records synced',
        );
      } else {
        _updateStatus(
          SyncUiStatus.error,
          'Sync completed with ${result.failedCount} errors',
        );
      }
    } catch (e) {
      _updateStatus(SyncUiStatus.error, 'Sync failed: $e');
    }
  }

  /// Perform incremental sync
  Future<void> performIncrementalSync() async {
    if (_status == SyncUiStatus.syncing) {
      _updateStatus(SyncUiStatus.error, 'Sync already in progress');
      return;
    }

    _updateStatus(SyncUiStatus.syncing, 'Starting incremental sync...');
    _progress = 0.0;
    _currentOperation = 'Checking for changes...';
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _syncService.performIncrementalSync();

      if (result.success) {
        if (result.syncedCount == 0) {
          _updateStatus(SyncUiStatus.idle, 'No new changes to sync');
        } else {
          _lastSyncTime = DateTime.now();
          _updateStatus(
            SyncUiStatus.success,
            'Synced ${result.syncedCount} records',
          );
        }
      } else {
        _updateStatus(
          SyncUiStatus.error,
          'Sync completed with ${result.failedCount} errors',
        );
      }
    } catch (e) {
      _updateStatus(SyncUiStatus.error, 'Sync failed: $e');
    }
  }

  /// Sync a specific table
  Future<void> syncTable(String tableName) async {
    _updateStatus(SyncUiStatus.syncing, 'Syncing $tableName...');
    notifyListeners();

    try {
      // Get records from the table
      final db = await _syncService.dbHelper.database;
      final records = await db.query(tableName);

      int synced = 0;
      int failed = 0;

      for (int i = 0; i < records.length; i++) {
        final success = await _syncService.syncSingleRecord(
          tableName,
          records[i],
        );
        if (success) {
          synced++;
        } else {
          failed++;
        }
        _progress = (i + 1) / records.length;
        notifyListeners();
      }

      if (failed == 0) {
        _updateStatus(
          SyncUiStatus.success,
          'Synced $synced records from $tableName',
        );
      } else {
        _updateStatus(SyncUiStatus.error, 'Synced $synced, failed $failed');
      }
    } catch (e) {
      _updateStatus(SyncUiStatus.error, 'Failed to sync $tableName: $e');
    }
  }

  /// Retry failed syncs
  Future<void> retryFailedSyncs() async {
    final errors = _syncService.syncErrors;
    if (errors.isEmpty) {
      _updateStatus(SyncUiStatus.idle, 'No failed records to retry');
      return;
    }

    _updateStatus(
      SyncUiStatus.syncing,
      'Retrying ${errors.length} failed records...',
    );
    notifyListeners();

    int retried = 0;
    int failed = 0;

    for (final error in errors) {
      if (!error.retryable) continue;

      try {
        final db = await _syncService.dbHelper.database;
        final records = await db.query(
          error.tableName,
          where: 'id = ?',
          whereArgs: [error.localId],
        );

        if (records.isNotEmpty) {
          final success = await _syncService.syncSingleRecord(
            error.tableName,
            records.first,
          );
          if (success) {
            retried++;
          } else {
            failed++;
          }
        }
      } catch (e) {
        failed++;
      }
    }

    _updateStatus(
      SyncUiStatus.success,
      'Retried $retried records, $failed still failed',
    );
  }

  /// Toggle periodic sync
  void togglePeriodicSync() {
    _isPeriodicSyncEnabled = !_isPeriodicSyncEnabled;

    if (_isPeriodicSyncEnabled) {
      _syncService.startPeriodicSync();
      _updateStatus(SyncUiStatus.idle, 'Periodic sync enabled');
    } else {
      _syncService.stopPeriodicSync();
      _updateStatus(SyncUiStatus.idle, 'Periodic sync disabled');
    }

    notifyListeners();
  }

  // ========== Getters ==========

  SyncUiStatus get status => _status;
  String get statusMessage => _statusMessage;
  double get progress => _progress;
  String get currentOperation => _currentOperation;
  int get syncedCount => _syncedCount;
  int get failedCount => _failedCount;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get errorMessage => _errorMessage;
  bool get isPeriodicSyncEnabled => _isPeriodicSyncEnabled;
  bool get isSyncing => _status == SyncUiStatus.syncing;
  bool get hasPendingChanges => _status == SyncUiStatus.pendingChanges;
  bool get hasErrors => _status == SyncUiStatus.error;

  /// Get sync tracker for a specific table
  SyncTracker? getTracker(String tableName) {
    return _syncService.getTracker(tableName);
  }

  /// Get all sync errors
  List<SyncError> get syncErrors {
    return _syncService.syncErrors;
  }

  /// Get formatted last sync time
  String get lastSyncTimeFormatted {
    if (_lastSyncTime == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(_lastSyncTime!);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  // ========== Private Methods ==========

  void _onSyncStateChanged(SyncState state) {
    _syncedCount = state.syncedRecords;
    _failedCount = state.failedRecords;
    _currentOperation = state.currentOperation ?? '';

    if (state.isSyncing) {
      _status = SyncUiStatus.syncing;
      _statusMessage = state.currentOperation ?? 'Syncing...';
    } else if (state.hasPendingChanges && state.failedRecords > 0) {
      _status = SyncUiStatus.error;
      _statusMessage = state.errorMessage ?? 'Sync completed with errors';
    } else if (state.syncedRecords > 0) {
      _status = SyncUiStatus.success;
      _statusMessage = 'Sync completed successfully';
    } else {
      _status = SyncUiStatus.idle;
      _statusMessage = 'Ready to sync';
    }

    notifyListeners();
  }

  void _onProgress(String table, int current, int total) {
    _progress = total > 0 ? current / total : 0.0;
    _currentOperation = 'Syncing $table: $current/$total';
    notifyListeners();
  }

  void _onComplete(SyncResult result) {
    _progress = 1.0;
    _syncedCount = result.syncedCount;
    _failedCount = result.failedCount;

    if (result.success) {
      _lastSyncTime = DateTime.now();
      _status = SyncUiStatus.success;
      _statusMessage = result.isFullSync
          ? 'Full sync completed: ${result.syncedCount} records'
          : 'Synced ${result.syncedCount} new records';
    } else {
      _status = SyncUiStatus.error;
      _statusMessage = '${result.failedCount} records failed to sync';
    }

    notifyListeners();
  }

  void _onError(String error) {
    _errorMessage = error;
    _status = SyncUiStatus.error;
    _statusMessage = 'Sync error: $error';
    notifyListeners();
  }

  void _updateStatus(SyncUiStatus newStatus, String message) {
    _status = newStatus;
    _statusMessage = message;
    notifyListeners();
  }

  // ========== Cleanup ==========

  @override
  void dispose() {
    _syncStateSubscription?.cancel();
    _syncService.dispose();
    super.dispose();
  }
}
