// lib/services/gis_calendar_web.dart
// Google Identity Services (GIS) Calendar Integration for Flutter Web
// Uses Google Identity Services Token Client for OAuth 2.0
// Documentation: https://developers.google.com/identity/oauth2/web/guides/overview

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// GIS Calendar Web Service
/// Handles Google Calendar OAuth using Google Identity Services (GIS) 2.0
///
/// IMPORTANT: Token storage notes:
/// - Tokens are stored in memory only (JavaScript variable)
/// - Tokens are NOT persisted to Firestore or any database
/// - Tokens are cleared on page refresh/navigation
/// - User must re-authenticate if token expires or page is refreshed
class GisCalendarWeb {
  // ==================== CONFIGURATION ====================

  /// Your OAuth 2.0 Client ID from Google Cloud Console
  /// Get it from: https://console.cloud.google.com/apis/credentials
  /// OAuth 2.0 Client ID: 668191545214-hqk4trrdjh3tivmdvmd2pkhn7la1sard.apps.googleusercontent.com
  static const String _clientId =
      '34061023916-3n5n4gu2atvbi6l0gq4nltoub75bo2er.apps.googleusercontent.com';

  /// Calendar API scope for creating events
  /// This scope allows creating/updating/deleting calendar events
  /// Learn more: https://developers.google.com/identity/protocols/oauth2/scopes#calendar
  static const String _calendarScope =
      'https://www.googleapis.com/auth/calendar.events';

  // ==================== STATE ====================

  /// Whether the GIS client has been initialized
  static bool _isInitialized = false;

  /// Whether we have requested consent before
  static bool _hasConsented = false;

  /// Unique callback ID for this instance
  static String _generateCallbackId() {
    return 'gis_calendar_${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
  }

  static int _counter = 0;

  // ==================== TOKEN MANAGEMENT ====================

  /// Initialize the GIS Token Client
  /// Must be called before requesting tokens
  static Future<void> initialize() async {
    if (!kIsWeb) return;
    if (_isInitialized) return;

    // Verify GIS script is loaded
    final gsiLoaded = _checkGsiLoaded();
    if (!gsiLoaded) {
      throw Exception(
        'Google Identity Services (GIS) script not loaded. '
        'Ensure https://accounts.google.com/gsi/client is in index.html',
      );
    }

    final callbackId = _generateCallbackId();

    // Call JS to initialize token client
    js.context.callMethod('gisInitTokenClient', [
      _clientId,
      _calendarScope,
      callbackId,
    ]);

    _isInitialized = true;
    print('GIS Calendar Token Client initialized');
  }

  /// Request a calendar access token
  ///
  /// [requestConsent] - If true, shows consent prompt; if false, uses incremental auth
  ///   - First call: set to true (to get user consent)
  ///   - Subsequent calls: set to false (token cached, no prompt)
  ///
  /// Returns: Future<String> - The access token
  /// Throws: GisException on error
  static Future<String> requestCalendarToken({
    bool requestConsent = true,
  }) async {
    if (!kIsWeb) {
      throw GisException(
        GisErrorType.notSupported,
        'GIS Calendar is only supported on web platform',
      );
    }

    if (!_isInitialized) {
      await initialize();
    }

    final callbackId = _generateCallbackId();
    final completer = Completer<String>();

    // Set up one-time listener for this request
    final subscription = html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is! Map) return;

      if (data['callbackId'] != callbackId) return;

      final type = data['type'] as String?;
      if (type == 'GIS_TOKEN_SUCCESS') {
        final token = data['accessToken'] as String;
        _hasConsented = true;
        if (!completer.isCompleted) {
          completer.complete(token);
        }
      } else if (type == 'GIS_TOKEN_ERROR') {
        final errorType = data['errorType'] as String;
        final errorMessage = data['errorMessage'] as String;

        if (errorType == 'USER_CANCELLED') {
          if (!completer.isCompleted) {
            completer.completeError(
              GisException(GisErrorType.userCancelled, errorMessage),
            );
          }
        } else if (errorType == 'NETWORK_ERROR') {
          if (!completer.isCompleted) {
            completer.completeError(
              GisException(GisErrorType.networkError, errorMessage),
            );
          }
        } else if (errorType == 'CONSENT_REQUIRED') {
          if (!completer.isCompleted) {
            completer.completeError(
              GisException(GisErrorType.consentRequired, errorMessage),
            );
          }
        } else {
          if (!completer.isCompleted) {
            completer.completeError(
              GisException(GisErrorType.unknown, errorMessage),
            );
          }
        }
      }
    });

    // Request token from JS
    js.context.callMethod('gisRequestCalendarToken', [
      requestConsent,
      callbackId,
    ]);

    try {
      return await completer.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          subscription.cancel();
          throw GisException(
            GisErrorType.timeout,
            'Token request timed out (popup may be blocked)',
          );
        },
      );
    } finally {
      subscription.cancel();
    }
  }

  /// Clear stored token (for logout)
  static void clearToken() {
    if (!kIsWeb) return;

    try {
      js.context.callMethod('gisClearToken', []);
      _hasConsented = false;
      print('Token cleared');
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  // ==================== CALENDAR REST API ====================

  /// Create a calendar event using REST API
  ///
  /// [accessToken] - OAuth 2.0 access token with calendar.events scope
  /// [eventData] - Event details to create
  ///
  /// Returns: String - The created event's ID
  static Future<String> createCalendarEvent({
    required String accessToken,
    required Map<String, dynamic> eventData,
  }) async {
    if (!kIsWeb) {
      throw GisException(
        GisErrorType.notSupported,
        'Calendar REST API is only supported on web',
      );
    }

    // Validate required fields
    if (eventData['summary'] == null ||
        eventData['summary'].toString().isEmpty) {
      throw GisException(
        GisErrorType.invalidRequest,
        'Event summary is required',
      );
    }

    if (eventData['start'] == null || eventData['start']['dateTime'] == null) {
      throw GisException(
        GisErrorType.invalidRequest,
        'Event start time is required',
      );
    }

    if (eventData['end'] == null || eventData['end']['dateTime'] == null) {
      throw GisException(
        GisErrorType.invalidRequest,
        'Event end time is required',
      );
    }

    // Prepare request body using dart:convert
    final requestBody = jsonEncode(eventData);

    // Create HTTP request
    final request = html.HttpRequest();
    request.open(
      'POST',
      'https://www.googleapis.com/calendar/v3/calendars/primary/events',
    );
    request.setRequestHeader('Authorization', 'Bearer $accessToken');
    request.setRequestHeader('Content-Type', 'application/json');

    final completer = Completer<String>();

    request.onLoad.listen((_) {
      if (request.status == 200) {
        final response = jsonDecode(request.responseText as String);
        final eventId = response['id'] as String?;
        if (eventId != null) {
          completer.complete(eventId);
        } else {
          completer.completeError(
            GisException(GisErrorType.apiError, 'No event ID in response'),
          );
        }
      } else {
        final errorMsg = request.statusText ?? 'Unknown error';
        completer.completeError(
          GisException(
            GisErrorType.apiError,
            'Failed to create event: ${request.status} $errorMsg',
          ),
        );
      }
    });

    request.onError.listen((_) {
      completer.completeError(
        GisException(
          GisErrorType.networkError,
          'Network error during API call',
        ),
      );
    });

    request.send(requestBody);

    return await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw GisException(GisErrorType.timeout, 'API request timed out');
      },
    );
  }

  // ==================== HELPER METHODS ====================

  /// Check if GIS script is loaded
  static bool _checkGsiLoaded() {
    try {
      final result = js.context.hasProperty('google');
      if (!result) return false;
      final gis = js.context['google'];
      return gis != null && gis['accounts'] != null;
    } catch (e) {
      return false;
    }
  }

  // ==================== EVENT DATA BUILDER ====================

  /// Build calendar event data structure
  static Map<String, dynamic> buildEventData({
    required String summary,
    String? description,
    String? location,
    required String startDateTime,
    required String endDateTime,
    String timeZone = 'UTC',
  }) {
    return {
      'summary': summary,
      'description': description ?? '',
      'location': location ?? '',
      'start': {'dateTime': startDateTime, 'timeZone': timeZone},
      'end': {'dateTime': endDateTime, 'timeZone': timeZone},
      'reminders': {
        'useDefault': false,
        'overrides': [
          {'method': 'email', 'minutes': 24 * 60},
          {'method': 'popup', 'minutes': 30},
        ],
      },
    };
  }
}

// ==================== ERROR TYPES ====================

/// Error types for GIS Calendar operations
enum GisErrorType {
  notSupported,
  userCancelled,
  networkError,
  consentRequired,
  invalidRequest,
  apiError,
  timeout,
  unknown,
}

/// Exception thrown by GIS Calendar operations
class GisException implements Exception {
  final GisErrorType type;
  final String message;

  GisException(this.type, this.message);

  @override
  String toString() => 'GisException[$type]: $message';
}
