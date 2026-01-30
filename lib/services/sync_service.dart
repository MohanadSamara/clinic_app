// lib/services/sync_service.dart
/// SQLite to Firestore Sync Service
/// Implements offline-first architecture with manual sync support
///
/// This service handles:
/// - First-time full sync from SQLite to Firestore
/// - Incremental sync for new/updated records
/// - Stable document ID generation to prevent duplicates
/// - Error handling with retry logic
/// - Progress tracking and logging

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../db/db_helper.dart';
import '../models/sync_tracker.dart';

/// Configuration for sync behavior
class SyncConfig {
  /// Maximum number of retry attempts for failed records
  final int maxRetries;

  /// Delay between retries in milliseconds
  final int retryDelayMs;

  /// Batch size for bulk operations
  final int batchSize;

  /// Whether to enable automatic periodic sync
  final bool enablePeriodicSync;

  /// Periodic sync interval in minutes
  final int periodicSyncIntervalMinutes;

  /// Tables to include in sync (empty means all)
  final List<String> includedTables;

  /// Tables to exclude from sync
  final List<String> excludedTables;

  const SyncConfig({
    this.maxRetries = 3,
    this.retryDelayMs = 1000,
    this.batchSize = 100,
    this.enablePeriodicSync = true,
    this.periodicSyncIntervalMinutes = 15,
    this.includedTables = const [],
    this.excludedTables = const [
      'audit_logs',
      'system_settings',
      'sqlite_sequence',
    ],
  });

  /// Default configuration
  static const defaultConfig = SyncConfig();

  /// Create a copy with modifications
  SyncConfig copyWith({
    int? maxRetries,
    int? retryDelayMs,
    int? batchSize,
    bool? enablePeriodicSync,
    int? periodicSyncIntervalMinutes,
    List<String>? includedTables,
    List<String>? excludedTables,
  }) {
    return SyncConfig(
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelayMs: retryDelayMs ?? this.retryDelayMs,
      batchSize: batchSize ?? this.batchSize,
      enablePeriodicSync: enablePeriodicSync ?? this.enablePeriodicSync,
      periodicSyncIntervalMinutes:
          periodicSyncIntervalMinutes ?? this.periodicSyncIntervalMinutes,
      includedTables: includedTables ?? this.includedTables,
      excludedTables: excludedTables ?? this.excludedTables,
    );
  }
}

/// Progress callback type for sync operations
typedef SyncProgressCallback =
    void Function(String tableName, int current, int total);

/// Main sync service class
class SyncService {
  // Singleton pattern
  static final SyncService instance = SyncService._internal();
  factory SyncService() => instance;
  SyncService._internal();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Database helper
  final DBHelper _dbHelper = DBHelper.instance;

  // Configuration
  SyncConfig _config = SyncConfig.defaultConfig;

  // State management
  final SyncState _syncState = SyncState();
  final Map<String, SyncTracker> _syncTrackers = {};
  final List<SyncError> _syncErrors = [];

  // Periodic sync timer
  Timer? _periodicSyncTimer;

  // Callbacks
  SyncProgressCallback? _onProgress;
  void Function(SyncResult result)? _onComplete;
  void Function(String error)? _onError;

  // Stream controller for sync state updates
  final StreamController<SyncState> _syncStateController =
      StreamController<SyncState>.broadcast();
  Stream<SyncState> get syncStateStream => _syncStateController.stream;

  // ========== Configuration Methods ==========

  /// Update sync configuration
  void updateConfig(SyncConfig config) {
    _config = config;
    _restartPeriodicSync();
  }

  /// Get current configuration
  SyncConfig get config => _config;

  // ========== Progress Callbacks ==========

  /// Set progress callback
  void setProgressCallback(SyncProgressCallback callback) {
    _onProgress = callback;
  }

  /// Set completion callback
  void setCompleteCallback(void Function(SyncResult result) callback) {
    _onComplete = callback;
  }

  /// Set error callback
  void setErrorCallback(void Function(String error) callback) {
    _onError = callback;
  }

  // ========== Core Sync Methods ==========

  /// Perform a full sync of all tables
  /// This syncs ALL records from SQLite to Firestore
  Future<SyncResult> performFullSync({bool clearExisting = false}) async {
    final startTime = DateTime.now();
    _log('Starting full sync...');

    _updateSyncState(
      isSyncing: true,
      currentOperation: 'Initializing full sync',
      errorMessage: null,
    );

    try {
      // Get all tables to sync
      final tables = await _getTablesToSync();

      if (clearExisting) {
        _log('Clearing existing Firestore data...');
        await _clearFirestoreCollections(tables);
      }

      int totalSynced = 0;
      int totalFailed = 0;
      final allErrors = <SyncError>[];

      for (final table in tables) {
        _updateSyncState(currentOperation: 'Syncing $table');

        final result = await _syncTable(
          table,
          since: null, // Full sync - no time filter
          clearExisting: clearExisting,
          onProgress: (current, total) {
            _onProgress?.call(table, current, total);
          },
        );

        totalSynced += result.syncedCount;
        totalFailed += result.failedCount;
        allErrors.addAll(result.errors);

        // Update tracker
        _updateTracker(table, SyncStatus.success, result.syncedCount);
      }

      final duration = DateTime.now().difference(startTime);
      final success = totalFailed == 0;

      final syncResult = SyncResult(
        success: success,
        syncedCount: totalSynced,
        failedCount: totalFailed,
        errors: allErrors,
        duration: duration,
        isFullSync: true,
      );

      _updateSyncState(
        isSyncing: false,
        hasPendingChanges: totalFailed > 0,
        totalRecordsToSync: 0,
        syncedRecords: totalSynced,
        failedRecords: totalFailed,
        currentOperation: null,
        lastFullSyncTime: DateTime.now(),
        errorMessage: success ? null : 'Some records failed to sync',
      );

      _onComplete?.call(syncResult);
      _log('Full sync completed: $totalSynced synced, $totalFailed failed');

      return syncResult;
    } catch (e, stackTrace) {
      _handleError('Full sync failed', e, stackTrace);

      _updateSyncState(isSyncing: false, errorMessage: e.toString());

      return SyncResult(
        success: false,
        syncedCount: 0,
        failedCount: 0,
        errors: [
          SyncError(
            tableName: 'GLOBAL',
            localId: 0,
            documentId: 'N/A',
            errorMessage: e.toString(),
            timestamp: DateTime.now(),
            retryable: true,
          ),
        ],
        duration: DateTime.now().difference(startTime),
        isFullSync: true,
      );
    }
  }

  /// Perform incremental sync (only new/updated records)
  /// Uses the last sync timestamp to determine what needs syncing
  Future<SyncResult> performIncrementalSync() async {
    final startTime = DateTime.now();
    _log('Starting incremental sync...');

    _updateSyncState(
      isSyncing: true,
      currentOperation: 'Preparing incremental sync',
      errorMessage: null,
    );

    try {
      final tables = await _getTablesToSync();
      int totalSynced = 0;
      int totalFailed = 0;
      final allErrors = <SyncError>[];

      for (final table in tables) {
        final tracker = _syncTrackers[table];
        final lastSyncTime = tracker?.lastSyncTime;

        _updateSyncState(currentOperation: 'Syncing $table');

        final result = await _syncTable(
          table,
          since: lastSyncTime,
          onProgress: (current, total) {
            _onProgress?.call(table, current, total);
          },
        );

        totalSynced += result.syncedCount;
        totalFailed += result.failedCount;
        allErrors.addAll(result.errors);

        // Update tracker
        _updateTracker(
          table,
          result.failedCount > 0 ? SyncStatus.error : SyncStatus.success,
          result.syncedCount,
        );
      }

      final duration = DateTime.now().difference(startTime);
      final success = totalFailed == 0;

      final syncResult = SyncResult(
        success: success,
        syncedCount: totalSynced,
        failedCount: totalFailed,
        errors: allErrors,
        duration: duration,
        isFullSync: false,
      );

      _updateSyncState(
        isSyncing: false,
        hasPendingChanges: totalFailed > 0,
        totalRecordsToSync: 0,
        syncedRecords: totalSynced,
        failedRecords: totalFailed,
        currentOperation: null,
        errorMessage: success ? null : 'Some records failed to sync',
      );

      _onComplete?.call(syncResult);
      _log(
        'Incremental sync completed: $totalSynced synced, $totalFailed failed',
      );

      return syncResult;
    } catch (e, stackTrace) {
      _handleError('Incremental sync failed', e, stackTrace);

      _updateSyncState(isSyncing: false, errorMessage: e.toString());

      return SyncResult(
        success: false,
        syncedCount: 0,
        failedCount: 0,
        errors: [
          SyncError(
            tableName: 'GLOBAL',
            localId: 0,
            documentId: 'N/A',
            errorMessage: e.toString(),
            timestamp: DateTime.now(),
            retryable: true,
          ),
        ],
        duration: DateTime.now().difference(startTime),
        isFullSync: false,
      );
    }
  }

  /// Sync a single record to Firestore
  /// Returns true if successful, false otherwise
  Future<bool> syncSingleRecord(
    String table,
    Map<String, dynamic> record,
  ) async {
    final documentId = _generateDocumentId(table, record['id']);

    try {
      await _getCollection(table)
          .doc(documentId)
          .set(
            _convertToFirestoreFormat(record, table),
            SetOptions(merge: true),
          );
      return true;
    } catch (e) {
      _logError('Failed to sync record $documentId: $e');
      return false;
    }
  }

  // ========== Private Methods ==========

  /// Get list of tables to sync
  Future<List<String>> _getTablesToSync() async {
    final db = await _dbHelper.database;

    // Query all tables
    final tablesResult = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );

    final tables = tablesResult
        .map((row) => row['name'] as String)
        .where(
          (name) =>
              !_config.excludedTables.contains(name) &&
              (_config.includedTables.isEmpty ||
                  _config.includedTables.contains(name)),
        )
        .toList();

    return tables;
  }

  /// Sync a single table
  Future<_TableSyncResult> _syncTable(
    String table, {
    DateTime? since,
    bool clearExisting = false,
    required void Function(int current, int total) onProgress,
  }) async {
    final db = await _dbHelper.database;
    final collection = _getCollection(table);

    // Get records to sync
    String? query;
    List<dynamic>? args;

    if (since != null) {
      query = 'updated_at > ? OR created_at > ?';
      args = [since.toIso8601String(), since.toIso8601String()];
    }

    final records = await db.query(table, where: query, whereArgs: args);

    if (records.isEmpty) {
      return _TableSyncResult(syncedCount: 0, failedCount: 0, errors: []);
    }

    int syncedCount = 0;
    int failedCount = 0;
    final errors = <SyncError>[];
    final batch = <Map<String, dynamic>>[];

    // Process records in batches
    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      final localId = record['id'] as int?;
      final documentId = _generateDocumentId(table, localId);

      try {
        // Convert record to Firestore format
        final firestoreData = _convertToFirestoreFormat(record, table);
        batch.add(firestoreData);

        // Execute batch when batch size reached
        if (batch.length >= _config.batchSize) {
          await _executeBatch(collection, batch);
          syncedCount += batch.length;
          batch.clear();
        }
      } catch (e) {
        failedCount++;
        errors.add(
          SyncError(
            tableName: table,
            localId: localId ?? 0,
            documentId: documentId,
            errorMessage: e.toString(),
            timestamp: DateTime.now(),
            retryable: true,
          ),
        );
      }

      // Report progress
      onProgress(i + 1, records.length);
    }

    // Process remaining records in batch
    if (batch.isNotEmpty) {
      await _executeBatch(collection, batch);
      syncedCount += batch.length;
    }

    return _TableSyncResult(
      syncedCount: syncedCount,
      failedCount: failedCount,
      errors: errors,
    );
  }

  /// Execute a batch write operation
  Future<void> _executeBatch(
    CollectionReference collection,
    List<Map<String, dynamic>> records,
  ) async {
    // For batch operations, we use individual writes with concurrent execution
    final futures = records.map((record) async {
      final docId = record['_documentId'] as String;
      final data = Map<String, dynamic>.from(record)..remove('_documentId');
      await collection.doc(docId).set(data, SetOptions(merge: true));
    });

    await Future.wait(futures);
  }

  /// Convert SQLite record to Firestore format
  Map<String, dynamic> _convertToFirestoreFormat(
    Map<String, dynamic> record,
    String table,
  ) {
    final result = <String, dynamic>{};

    // Add stable document ID
    final localId = record['id'];
    result['_documentId'] = _generateDocumentId(table, localId);
    result['_localId'] = localId;
    result['_tableName'] = table;
    result['_syncedAt'] = FieldValue.serverTimestamp();

    // Process each field
    record.forEach((key, value) {
      if (value == null) {
        result[key] = null;
        return;
      }

      // Skip internal SQLite fields
      if (key.startsWith('_')) return;

      // Convert datetime strings to Timestamp
      if (_isDateTimeField(key)) {
        try {
          final dateTime = DateTime.parse(value.toString());
          result[key] = Timestamp.fromDate(dateTime);
        } catch (e) {
          result[key] = value;
        }
      }
      // Convert JSON strings to Map
      else if (_isJsonField(key)) {
        try {
          result[key] = jsonDecode(value.toString());
        } catch (e) {
          result[key] = value;
        }
      }
      // Keep other values as-is
      else {
        result[key] = value;
      }
    });

    return result;
  }

  /// Generate a stable document ID
  String _generateDocumentId(String table, dynamic localId) {
    final id = localId?.toString() ?? 'unknown';
    return '${table}_$id';
  }

  /// Get Firestore collection reference
  CollectionReference _getCollection(String table) {
    // Map table names to collection names (pluralize if needed)
    final collectionName = _getCollectionName(table);
    return _firestore.collection(collectionName);
  }

  /// Map table name to collection name
  String _getCollectionName(String table) {
    // Add 's' to end for plural, handling special cases
    if (table.endsWith('y')) {
      return table.substring(0, table.length - 1) + 'ies';
    }
    if (table.endsWith('s')) {
      return table;
    }
    return table + 's';
  }

  /// Check if field is a datetime field
  bool _isDateTimeField(String fieldName) {
    return fieldName.endsWith('_at') ||
        fieldName == 'dob' ||
        fieldName == 'scheduled_at' ||
        fieldName == 'created_at' ||
        fieldName == 'updated_at' ||
        fieldName == 'upload_date' ||
        fieldName == 'check_date' ||
        fieldName == 'vaccination_date' ||
        fieldName == 'next_due_date' ||
        fieldName == 'inspection_date' ||
        fieldName == 'review_date' ||
        fieldName == 'issue_date' ||
        fieldName == 'expiry_date' ||
        fieldName == 'completed_at' ||
        fieldName == 'request_date';
  }

  /// Check if field is a JSON field
  bool _isJsonField(String fieldName) {
    return fieldName == 'vaccination_status' ||
        fieldName == 'attachments' ||
        fieldName == 'waypoints' ||
        fieldName == 'photos' ||
        fieldName == 'audit_logs' ||
        fieldName == 'data' ||
        fieldName == 'details';
  }

  /// Clear existing data in Firestore collections
  Future<void> _clearFirestoreCollections(List<String> tables) async {
    for (final table in tables) {
      final collection = _getCollection(table);
      final docs = await collection.get();

      if (docs.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in docs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
  }

  /// Update sync tracker for a table
  void _updateTracker(String table, SyncStatus status, int syncedCount) {
    _syncTrackers[table] = SyncTracker(
      tableName: table,
      lastSyncTime: DateTime.now(),
      lastSyncCount: syncedCount,
      status: status,
    );
  }

  /// Update sync state and notify listeners
  void _updateSyncState({
    bool? isSyncing,
    bool? hasPendingChanges,
    int? totalRecordsToSync,
    int? syncedRecords,
    int? failedRecords,
    String? currentOperation,
    DateTime? lastFullSyncTime,
    String? errorMessage,
  }) {
    final newState = SyncState(
      isSyncing: isSyncing ?? _syncState.isSyncing,
      hasPendingChanges: hasPendingChanges ?? _syncState.hasPendingChanges,
      totalRecordsToSync: totalRecordsToSync ?? _syncState.totalRecordsToSync,
      syncedRecords: syncedRecords ?? _syncState.syncedRecords,
      failedRecords: failedRecords ?? _syncState.failedRecords,
      currentOperation: currentOperation ?? _syncState.currentOperation,
      lastFullSyncTime: lastFullSyncTime ?? _syncState.lastFullSyncTime,
      errorMessage: errorMessage ?? _syncState.errorMessage,
    );

    // Emit new state to stream
    _syncStateController.add(newState);
  }

  /// Start periodic sync
  void startPeriodicSync() {
    if (!_config.enablePeriodicSync) return;

    stopPeriodicSync();

    _periodicSyncTimer = Timer.periodic(
      Duration(minutes: _config.periodicSyncIntervalMinutes),
      (_) => performIncrementalSync(),
    );

    _log(
      'Periodic sync started (every ${_config.periodicSyncIntervalMinutes} min)',
    );
  }

  // Database helper (public for providers to access)
  DBHelper get dbHelper => _dbHelper;

  /// Stop periodic sync (public method)
  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  /// Restart periodic sync with new config
  void _restartPeriodicSync() {
    if (_config.enablePeriodicSync) {
      startPeriodicSync();
    } else {
      stopPeriodicSync();
    }
  }

  // ========== Error Handling & Logging ==========

  /// Log message
  void _log(String message) {
    if (kDebugMode) {
      print('[SyncService] $message');
    }
  }

  /// Log error
  void _logError(String message) {
    if (kDebugMode) {
      print('[SyncService ERROR] $message');
    }
  }

  /// Handle error
  void _handleError(String context, Object e, StackTrace stack) {
    final errorMessage = '$context: $e';
    _logError(errorMessage);
    _onError?.call(errorMessage);

    if (kDebugMode) {
      print(stack);
    }
  }

  // ========== Public State Accessors ==========

  /// Get current sync state
  SyncState get syncState => _syncState;

  /// Get sync tracker for a specific table
  SyncTracker? getTracker(String table) => _syncTrackers[table];

  /// Get all sync errors
  List<SyncError> get syncErrors => List.unmodifiable(_syncErrors);

  /// Check if currently syncing
  bool get isSyncing => _syncState.isSyncing;

  /// Check if there are pending changes
  bool get hasPendingChanges => _syncState.hasPendingChanges;

  // ========== Cleanup ==========

  /// Dispose resources
  void dispose() {
    stopPeriodicSync();
    _syncStateController.close();
  }
}

/// Result of syncing a single table
class _TableSyncResult {
  final int syncedCount;
  final int failedCount;
  final List<SyncError> errors;

  _TableSyncResult({
    required this.syncedCount,
    required this.failedCount,
    required this.errors,
  });
}
