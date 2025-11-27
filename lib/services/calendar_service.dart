// lib/services/calendar_service.dart
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/appointment.dart';

class CalendarService {
  static const String _calendarId = 'primary'; // Use primary calendar
  static const String _clientId =
      '668191545214-hqk4trrdjh3tivmdvmd2pkhn7la1sard.apps.googleusercontent.com'; // Replace with actual client ID
  static final List<String> _scopes = [
    calendar.CalendarApi.calendarEventsScope,
  ];

  static Future<bool> addAppointmentToCalendar(Appointment appointment) async {
    try {
      // For now, we'll use a simplified approach
      // In production, you'd need proper OAuth flow
      final client = http.Client();

      // This is a placeholder - proper implementation would require:
      // 1. OAuth 2.0 flow with Google Sign-In
      // 2. Proper client credentials
      // 3. Token management

      // For demonstration, we'll create a calendar event URL
      final eventUrl = _generateCalendarEventUrl(appointment);

      // Launch the URL to add to Google Calendar
      if (await canLaunchUrl(Uri.parse(eventUrl))) {
        await launchUrl(Uri.parse(eventUrl));
        return true;
      }

      return false;
    } catch (e) {
      print('Error adding appointment to calendar: $e');
      return false;
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
