// lib/services/reservation_service.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// ReservationService provides lightweight TTL-based holds on booking slots
/// to reduce race conditions during the confirm/payment step.
/// Persistence is local (SharedPreferences) and suitable for single-client or PWA.
/// For multi-client/server scenarios, mirror this logic on the backend with atomic ops.
class ReservationService {
  static const String _prefsKey =
      'slot_reservations'; // { slotKey: expiryMillis }

  ReservationService._internal();
  static final ReservationService instance = ReservationService._internal();

  /// Construct a deterministic slot key.
  /// Example: 2025-05-01T14:30:00Z|Vaccination
  static String buildKey({
    required DateTime scheduledAtUtc,
    String? serviceType,
    int? doctorId,
  }) {
    final ts = scheduledAtUtc.toIso8601String();
    final s = (serviceType ?? '').trim();
    final d = doctorId != null ? '#d$doctorId' : '';
    return '$ts|$s$d';
  }

  Future<Map<String, dynamic>> _readMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final Map<String, dynamic> parsed =
          jsonDecode(raw) as Map<String, dynamic>;
      return parsed;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _writeMap(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  Future<void> _cleanupExpired(Map<String, dynamic> data, int nowMs) async {
    final keysToRemove = <String>[];
    data.forEach((k, v) {
      final exp = (v is num) ? v.toInt() : -1;
      if (exp < nowMs) keysToRemove.add(k);
    });
    if (keysToRemove.isNotEmpty) {
      for (final k in keysToRemove) {
        data.remove(k);
      }
      await _writeMap(data);
    }
  }

  /// Try to reserve a slot for ttlSeconds.
  /// Returns true if the reservation is created/renewed, false if currently held.
  Future<bool> reserveSlot({
    required String slotKey,
    int ttlSeconds = 120,
    bool overwriteIfExpired = true,
  }) async {
    final map = await _readMap();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _cleanupExpired(map, nowMs);

    final existing = map[slotKey];
    if (existing is num) {
      final exp = existing.toInt();
      if (exp > nowMs) {
        // already reserved and not expired
        return false;
      }
      // expired
      if (!overwriteIfExpired) return false;
    }

    final expiry = nowMs + (ttlSeconds * 1000);
    map[slotKey] = expiry;
    await _writeMap(map);
    return true;
  }

  /// Check if a slot is currently reserved (not expired).
  Future<bool> isReserved(String slotKey) async {
    final map = await _readMap();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final v = map[slotKey];
    if (v is num) {
      return v.toInt() > nowMs;
    }
    return false;
  }

  /// Release a slot explicitly (e.g., after booking confirmation or cancel).
  Future<void> releaseSlot(String slotKey) async {
    final map = await _readMap();
    if (map.containsKey(slotKey)) {
      map.remove(slotKey);
      await _writeMap(map);
    }
  }
}
