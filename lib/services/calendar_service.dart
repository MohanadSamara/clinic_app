// lib/services/calendar_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/appointment.dart';

/// CalendarService scaffolding to support:
/// - Provider link/unlink (token persistence)
/// - Event create/update/delete mapping to appointments
/// - ICS export fallback
///
/// Notes:
/// - This is a client-side placeholder. Real integrations (Google/Outlook)
///   require OAuth2 and server-side token exchange. Use this as an interface
///   and local simulation layer until backend is ready.
class CalendarService {
  static const _prefsTokensKey =
      'calendar_tokens'; // { provider: {accessToken, refreshToken, expiresAt} }
  static const _prefsEventsKey =
      'calendar_events'; // { appointmentId: { provider, eventId } }

  Future<Map<String, dynamic>> _readJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final Map<String, dynamic> parsed =
          jsonDecode(raw) as Map<String, dynamic>;
      return parsed;
    } catch (e) {
      debugPrint('CalendarService: failed to parse $_prefsTokensKey: $e');
      return <String, dynamic>{};
    }
  }

  Future<void> _writeJson(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  // ---------------- Provider link/unlink ----------------

  /// Link a calendar provider by storing tokens locally (scaffold).
  /// provider: 'google' | 'outlook' | ...
  Future<void> linkProvider({
    required String provider,
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    final tokens = await _readJson(_prefsTokensKey);
    tokens[provider] = {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
    await _writeJson(_prefsTokensKey, tokens);
  }

  /// Retrieve stored provider token info (if present).
  Future<Map<String, dynamic>?> getProvider(String provider) async {
    final tokens = await _readJson(_prefsTokensKey);
    final obj = tokens[provider];
    if (obj is Map<String, dynamic>) return obj;
    return null;
  }

  /// Unlink a provider (remove stored tokens).
  Future<void> unlinkProvider(String provider) async {
    final tokens = await _readJson(_prefsTokensKey);
    tokens.remove(provider);
    await _writeJson(_prefsTokensKey, tokens);
  }

  // ---------------- Event mapping for appointments ----------------

  /// Create a calendar event for an appointment in the given provider.
  /// Returns a synthetic eventId and persists mapping.
  Future<String> createEventForAppointment({
    required String provider,
    required Appointment appointment,
  }) async {
    // In a real integration, call provider API to create event and get eventId.
    final eventId =
        'evt_${provider}_${appointment.id ?? DateTime.now().millisecondsSinceEpoch}';

    final events = await _readJson(_prefsEventsKey);
    events['${appointment.id}'] = {'provider': provider, 'eventId': eventId};
    await _writeJson(_prefsEventsKey, events);

    // Optional: simulate success log
    debugPrint(
      'CalendarService: created event $eventId for apt ${appointment.id}',
    );
    return eventId;
  }

  /// Update a previously created event if mapping exists.
  Future<bool> updateEventForAppointment({
    required Appointment appointment,
  }) async {
    final events = await _readJson(_prefsEventsKey);
    final entry = events['${appointment.id}'];
    if (entry is! Map) {
      debugPrint(
        'CalendarService: no mapped event for appointment ${appointment.id}',
      );
      return false;
    }
    // Real provider update would go here; we just confirm mapping exists.
    debugPrint(
      'CalendarService: updated event ${entry['eventId']} for apt ${appointment.id}',
    );
    return true;
  }

  /// Delete an event mapped to an appointment and remove mapping.
  Future<bool> deleteEventForAppointment({required int appointmentId}) async {
    final events = await _readJson(_prefsEventsKey);
    final entry = events['$appointmentId'];
    if (entry is! Map) {
      debugPrint(
        'CalendarService: no mapped event for appointment $appointmentId',
      );
      return false;
    }
    // Real provider delete would go here.
    events.remove('$appointmentId');
    await _writeJson(_prefsEventsKey, events);
    debugPrint('CalendarService: deleted event mapping for apt $appointmentId');
    return true;
  }

  // ---------------- ICS export ----------------

  /// Generate a portable ICS string for the appointment for manual import.
  String generateIcs(Appointment appointment) {
    // Basic ICS content; consumers may require CRLF (\r\n), so we use it.
    final now = DateTime.now().toUtc();
    final dtStamp = _fmtICS(now);
    // scheduledAt stored as ISO string; parse to UTC for ICS
    DateTime start;
    try {
      start = DateTime.parse(appointment.scheduledAt).toUtc();
    } catch (_) {
      start = now;
    }
    // Assume 30-minute default duration if no service duration available
    final end = start.add(const Duration(minutes: 30));

    final uid = 'apt-${appointment.id ?? now.millisecondsSinceEpoch}@vet2u';
    final summary = 'Vet2U - ${appointment.serviceType}';
    final description = (appointment.description ?? '').replaceAll('\n', '\\n');
    final location = (appointment.address ?? '').replaceAll('\n', '\\n');

    final lines = <String>[
      'BEGIN:VCALENDAR',
      'PRODID:-//Vet2U//Calendar//EN',
      'VERSION:2.0',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      'UID:$uid',
      'DTSTAMP:$dtStamp',
      'DTSTART:${_fmtICS(start)}',
      'DTEND:${_fmtICS(end)}',
      'SUMMARY:${_escapeICS(summary)}',
      if (description.isNotEmpty) 'DESCRIPTION:${_escapeICS(description)}',
      if (location.isNotEmpty) 'LOCATION:${_escapeICS(location)}',
      'END:VEVENT',
      'END:VCALENDAR',
    ];
    return lines.join('\r\n');
  }

  // ---------------- Helpers ----------------

  String _fmtICS(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y$m$d'
        'T'
        '$hh$mm$ss'
        'Z';
    // All times rendered as UTC with trailing Z
  }

  String _escapeICS(String v) {
    // Basic ICS text escaping
    return v
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,');
  }
}
