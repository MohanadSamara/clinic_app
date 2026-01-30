// lib/models/sync_tracker.dart
/// Model for tracking sync state
class SyncTracker {
  final String tableName;
  final DateTime lastSyncTime;
  final int lastSyncCount;
  final SyncStatus status;
  final String? errorMessage;
  final DateTime? lastErrorTime;

  SyncTracker({
    required this.tableName,
    required this.lastSyncTime,
    this.lastSyncCount = 0,
    this.status = SyncStatus.idle,
    this.errorMessage,
    this.lastErrorTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'tableName': tableName,
      'lastSyncTime': lastSyncTime.toIso8601String(),
      'lastSyncCount': lastSyncCount,
      'status': status.toString(),
      'errorMessage': errorMessage,
      'lastErrorTime': lastErrorTime?.toIso8601String(),
    };
  }

  factory SyncTracker.fromMap(Map<String, dynamic> map) {
    return SyncTracker(
      tableName: map['tableName'] ?? '',
      lastSyncTime: map['lastSyncTime'] != null
          ? DateTime.parse(map['lastSyncTime'])
          : DateTime.fromMicrosecondsSinceEpoch(0),
      lastSyncCount: map['lastSyncCount'] ?? 0,
      status: SyncStatus.fromString(map['status'] ?? 'idle'),
      errorMessage: map['errorMessage'],
      lastErrorTime: map['lastErrorTime'] != null
          ? DateTime.parse(map['lastErrorTime'])
          : null,
    );
  }

  SyncTracker copyWith({
    String? tableName,
    DateTime? lastSyncTime,
    int? lastSyncCount,
    SyncStatus? status,
    String? errorMessage,
    DateTime? lastErrorTime,
  }) {
    return SyncTracker(
      tableName: tableName ?? this.tableName,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastSyncCount: lastSyncCount ?? this.lastSyncCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastErrorTime: lastErrorTime ?? this.lastErrorTime,
    );
  }
}

/// Enum representing sync status
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  retrying;

  static SyncStatus fromString(String value) {
    switch (value) {
      case 'SyncStatus.idle':
        return idle;
      case 'SyncStatus.syncing':
        return syncing;
      case 'SyncStatus.success':
        return success;
      case 'SyncStatus.error':
        return error;
      case 'SyncStatus.retrying':
        return retrying;
      default:
        return idle;
    }
  }
}

/// Global sync state for tracking overall sync progress
class SyncState {
  final bool isSyncing;
  final bool hasPendingChanges;
  final int totalRecordsToSync;
  final int syncedRecords;
  final int failedRecords;
  final String? currentOperation;
  final DateTime? lastFullSyncTime;
  final String? errorMessage;

  SyncState({
    this.isSyncing = false,
    this.hasPendingChanges = false,
    this.totalRecordsToSync = 0,
    this.syncedRecords = 0,
    this.failedRecords = 0,
    this.currentOperation,
    this.lastFullSyncTime,
    this.errorMessage,
  });

  double get progressPercentage {
    if (totalRecordsToSync == 0) return 0.0;
    return (syncedRecords / totalRecordsToSync) * 100;
  }

  SyncState copyWith({
    bool? isSyncing,
    bool? hasPendingChanges,
    int? totalRecordsToSync,
    int? syncedRecords,
    int? failedRecords,
    String? currentOperation,
    DateTime? lastFullSyncTime,
    String? errorMessage,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      hasPendingChanges: hasPendingChanges ?? this.hasPendingChanges,
      totalRecordsToSync: totalRecordsToSync ?? this.totalRecordsToSync,
      syncedRecords: syncedRecords ?? this.syncedRecords,
      failedRecords: failedRecords ?? this.failedRecords,
      currentOperation: currentOperation ?? this.currentOperation,
      lastFullSyncTime: lastFullSyncTime ?? this.lastFullSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final List<SyncError> errors;
  final Duration duration;
  final bool isFullSync;

  SyncResult({
    required this.success,
    required this.syncedCount,
    required this.failedCount,
    this.errors = const [],
    required this.duration,
    this.isFullSync = false,
  });

  int get totalRecords => syncedCount + failedCount;

  double get successRate {
    if (totalRecords == 0) return 100.0;
    return (syncedCount / totalRecords) * 100;
  }
}

/// Error details for a failed sync record
class SyncError {
  final String tableName;
  final int localId;
  final String documentId;
  final String errorMessage;
  final DateTime timestamp;
  final bool retryable;

  SyncError({
    required this.tableName,
    required this.localId,
    required this.documentId,
    required this.errorMessage,
    required this.timestamp,
    this.retryable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'tableName': tableName,
      'localId': localId,
      'documentId': documentId,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'retryable': retryable,
    };
  }

  factory SyncError.fromMap(Map<String, dynamic> map) {
    return SyncError(
      tableName: map['tableName'] ?? '',
      localId: map['localId'] ?? 0,
      documentId: map['documentId'] ?? '',
      errorMessage: map['errorMessage'] ?? 'Unknown error',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      retryable: map['retryable'] ?? true,
    );
  }
}
