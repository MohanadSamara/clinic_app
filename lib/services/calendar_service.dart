// lib/services/calendar_service.dart
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/appointment.dart';

class CalendarService {
  static const String _calendarId = 'primary'; // Use primary calendar
  static const String _clientId =
      '668191545214-hqk4trrdjh3tivmdvmd2pkhn7la1sard.apps.googleusercontent.com'; // Replace with actual client ID
  static const String _clientSecret = ''; // Add client secret for web
  static final List<String> _scopes = [
    calendar.CalendarApi.calendarEventsScope,
  ];

  static GoogleSignIn? _googleSignIn;
  static calendar.CalendarApi? _calendarApi;

  static Future<void> initialize() async {
    _googleSignIn = GoogleSignIn(scopes: _scopes, clientId: _clientId);
  }

  static Future<bool> ensureAuthenticated() async {
    try {
      if (_googleSignIn == null) {
        await initialize();
      }

      final account = await _googleSignIn!.signInSilently();
      if (account == null) {
        // User needs to sign in
        final account = await _googleSignIn!.signIn();
        if (account == null) {
          return false; // User cancelled
        }
      }

      final auth = await account!.authentication;
      final credentials = AccessCredentials(
        AccessToken(
          'Bearer',
          auth.accessToken!,
          DateTime.now().add(Duration(hours: 1)),
        ),
        auth.idToken,
        _scopes,
      );

      final client = authenticatedClient(http.Client(), credentials);
      _calendarApi = calendar.CalendarApi(client);

      return true;
    } catch (e) {
      print('Error authenticating for calendar: $e');
      return false;
    }
  }

  static Future<String?> addAppointmentToCalendar(
    Appointment appointment,
  ) async {
    try {
      // Ensure we have authentication
      final authenticated = await ensureAuthenticated();
      if (!authenticated || _calendarApi == null) {
        // Fallback to URL launch if API auth fails
        return await _addViaUrl(appointment);
      }

      // Create calendar event
      final startDateTime = calendar.EventDateTime()
        ..dateTime = DateTime.parse(appointment.scheduledAt).toUtc()
        ..timeZone = 'UTC';

      final endDateTime = calendar.EventDateTime()
        ..dateTime = DateTime.parse(
          appointment.scheduledAt,
        ).add(Duration(hours: 1)).toUtc()
        ..timeZone = 'UTC';

      final event = calendar.Event()
        ..summary = 'Vet Appointment - ${appointment.serviceType}'
        ..description =
            '''
Pet: ${appointment.petId}
Doctor: ${appointment.doctorName ?? 'TBD'}
Service: ${appointment.serviceType}
${appointment.description != null ? 'Description: ${appointment.description}' : ''}
Address: ${appointment.address ?? 'TBD'}
Urgency: ${appointment.urgencyLevel}
'''
        ..location = appointment.address
        ..start = startDateTime
        ..end = endDateTime;

      final createdEvent = await _calendarApi!.events.insert(
        event,
        _calendarId,
      );
      print('Event created: ${createdEvent.id}');

      return createdEvent.id;
    } catch (e) {
      print('Error adding appointment to calendar: $e');
      // Fallback to URL method
      return await _addViaUrl(appointment);
    }
  }

  static Future<String?> _addViaUrl(Appointment appointment) async {
    try {
      final eventUrl = _generateCalendarEventUrl(appointment);
      if (await canLaunchUrl(Uri.parse(eventUrl))) {
        await launchUrl(Uri.parse(eventUrl));
        return null; // URL method doesn't provide event ID
      }
      return null;
    } catch (e) {
      print('Error with URL fallback: $e');
      return null;
    }
  }

  static String _generateCalendarEventUrl(Appointment appointment) {
    final startDateTime = DateTime.parse(appointment.scheduledAt);
    final endDateTime = startDateTime.add(
      const Duration(hours: 1),
    ); // Assume 1 hour duration

    final title = 'Vet Appointment - ${appointment.serviceType}';
    final description =
        '''
Pet: ${appointment.petId}
Doctor: ${appointment.doctorName ?? 'TBD'}
Service: ${appointment.serviceType}
${appointment.description != null ? 'Description: ${appointment.description}' : ''}
Address: ${appointment.address ?? 'TBD'}
Urgency: ${appointment.urgencyLevel}
''';

    // Format dates for Google Calendar URL
    final startFormatted =
        startDateTime
            .toUtc()
            .toIso8601String()
            .replaceAll('-', '')
            .replaceAll(':', '')
            .split('.')
            .first +
        'Z';
    final endFormatted =
        endDateTime
            .toUtc()
            .toIso8601String()
            .replaceAll('-', '')
            .replaceAll(':', '')
            .split('.')
            .first +
        'Z';

    final baseUrl = 'https://calendar.google.com/calendar/render';
    final params = {
      'action': 'TEMPLATE',
      'text': Uri.encodeComponent(title),
      'dates': '$startFormatted/$endFormatted',
      'details': Uri.encodeComponent(description),
      'location': Uri.encodeComponent(appointment.address ?? ''),
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '$baseUrl?$queryString';
  }

  static Future<bool> removeAppointmentFromCalendar(String eventId) async {
    // Placeholder for removing events
    // Would require proper API integration
    return false;
  }

  static Future<List<calendar.Event>> getCalendarEvents() async {
    // Placeholder for fetching events
    // Would require proper API integration
    return [];
  }
}







