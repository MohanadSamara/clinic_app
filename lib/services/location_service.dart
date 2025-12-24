import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  final List<Position> _routePoints = [];
  Timer? _locationTimer;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  List<Position> get routePoints => List.unmodifiable(_routePoints);

  // Initialize location service
  Future<void> initialize() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
    } catch (e) {
      if (e.toString().contains('LateInitializationError')) {
        throw Exception(
          'Location services not properly initialized. Please check permissions and try again.',
        );
      }
      debugPrint('Location service initialization error: $e');
      rethrow;
    }
  }

  // Get current location once
  Future<Position> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;
      notifyListeners();
      return position;
    } catch (e) {
      if (e.toString().contains('LateInitializationError')) {
        throw Exception(
          'Location services not properly initialized. Please check permissions and try again.',
        );
      }
      debugPrint('Error getting current location: $e');
      rethrow;
    }
  }

  // Start location tracking
  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      await initialize();

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              _currentPosition = position;
              _routePoints.add(position);
              notifyListeners();
            },
            onError: (error) {
              debugPrint('Location tracking error: $error');
            },
          );

      _isTracking = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      rethrow;
    }
  }

  // Stop location tracking
  Future<void> stopTracking() async {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;
    notifyListeners();
  }

  // Calculate distance between two points using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // Calculate bearing between two points
  double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double lat1Rad = _degreesToRadians(lat1);
    final double lat2Rad = _degreesToRadians(lat2);

    final double y = sin(dLon) * cos(lat2Rad);
    final double x =
        cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

    final double bearing = atan2(y, x);
    return _radiansToDegrees(bearing);
  }

  // Calculate ETA based on distance and average speed
  Duration calculateETA(double distanceKm, double averageSpeedKmh) {
    if (averageSpeedKmh <= 0) return const Duration(hours: 1);
    final double hours = distanceKm / averageSpeedKmh;
    return Duration(minutes: (hours * 60).round());
  }

  // Optimize route using nearest neighbor algorithm
  List<Map<String, double>> optimizeRoute(
    Map<String, double> startPoint,
    List<Map<String, double>> destinations,
  ) {
    if (destinations.isEmpty) return [];

    final optimized = <Map<String, double>>[];
    final remaining = List<Map<String, double>>.from(destinations);

    var current = startPoint;

    while (remaining.isNotEmpty) {
      var nearestIndex = 0;
      var minDistance = double.infinity;

      for (var i = 0; i < remaining.length; i++) {
        final distance = calculateDistance(
          current['latitude']!,
          current['longitude']!,
          remaining[i]['latitude']!,
          remaining[i]['longitude']!,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearestIndex = i;
        }
      }

      current = remaining[nearestIndex];
      optimized.add(current);
      remaining.removeAt(nearestIndex);
    }

    return optimized;
  }

  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    if (!isLocationValid(latitude, longitude)) {
      debugPrint('Invalid coordinates: $latitude, $longitude');
      return null;
    }

    try {
      if (kIsWeb) {
        // Use Nominatim API for web reverse geocoding
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
        );
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['display_name'] != null) {
            return data['display_name'];
          } else {
            return 'Address not available for these coordinates';
          }
        } else {
          return 'Unable to retrieve address: HTTP ${response.statusCode}';
        }
      } else {
        final placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final addressParts = <String>[];

          // Safely build address parts with null checks, including more components
          final street = place.street;
          if (street != null && street.trim().isNotEmpty) {
            addressParts.add(street.trim());
          }

          final subLocality = place.subLocality;
          if (subLocality != null && subLocality.trim().isNotEmpty) {
            addressParts.add(subLocality.trim());
          }

          final locality = place.locality;
          if (locality != null && locality.trim().isNotEmpty) {
            addressParts.add(locality.trim());
          }

          final administrativeArea = place.administrativeArea;
          if (administrativeArea != null &&
              administrativeArea.trim().isNotEmpty) {
            addressParts.add(administrativeArea.trim());
          }

          final country = place.country;
          if (country != null && country.trim().isNotEmpty) {
            addressParts.add(country.trim());
          }

          final postalCode = place.postalCode;
          if (postalCode != null && postalCode.trim().isNotEmpty) {
            addressParts.add(postalCode.trim());
          }

          return addressParts.isNotEmpty
              ? addressParts.join(', ')
              : 'Address not available';
        }
        return 'No address found for these coordinates';
      }
    } catch (e) {
      debugPrint(
        'Error getting address from coordinates ($latitude, $longitude): $e',
      );
      final errorMessage = e.toString();
      if (errorMessage.contains('Unexpected null value')) {
        return 'Address lookup requires internet connection or valid API configuration';
      }
      return 'Unable to retrieve address: ${errorMessage.split('.').first}';
    }
  }

  // Get coordinates from address
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return {'latitude': location.latitude, 'longitude': location.longitude};
      }
      return null;
    } catch (e) {
      debugPrint('Error getting coordinates: $e');
      return null;
    }
  }

  // Generate simple navigation instructions
  List<String> generateNavigationInstructions(List<Map<String, double>> route) {
    final instructions = <String>[];

    if (route.length < 2) return instructions;

    for (var i = 0; i < route.length - 1; i++) {
      final current = route[i];
      final next = route[i + 1];

      final distance = calculateDistance(
        current['latitude']!,
        current['longitude']!,
        next['latitude']!,
        next['longitude']!,
      );

      final bearing = calculateBearing(
        current['latitude']!,
        current['longitude']!,
        next['latitude']!,
        next['longitude']!,
      );

      final direction = _getDirectionFromBearing(bearing);
      instructions.add(
        'Head $direction for ${distance.toStringAsFixed(1)} km to next destination',
      );
    }

    return instructions;
  }

  // Check if location is within bounds
  bool isLocationValid(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  // Clear route points
  void clearRoute() {
    _routePoints.clear();
    notifyListeners();
  }

  // Get total distance traveled
  double getTotalDistance() {
    if (_routePoints.length < 2) return 0.0;

    var totalDistance = 0.0;
    for (var i = 0; i < _routePoints.length - 1; i++) {
      totalDistance += calculateDistance(
        _routePoints[i].latitude,
        _routePoints[i].longitude,
        _routePoints[i + 1].latitude,
        _routePoints[i + 1].longitude,
      );
    }
    return totalDistance;
  }

  // Helper methods
  double _degreesToRadians(double degrees) => degrees * pi / 180;
  double _radiansToDegrees(double radians) => radians * 180 / pi;

  String _getDirectionFromBearing(double bearing) {
    if (bearing >= -22.5 && bearing < 22.5) return 'North';
    if (bearing >= 22.5 && bearing < 67.5) return 'Northeast';
    if (bearing >= 67.5 && bearing < 112.5) return 'East';
    if (bearing >= 112.5 && bearing < 157.5) return 'Southeast';
    if (bearing >= 157.5 || bearing < -157.5) return 'South';
    if (bearing >= -157.5 && bearing < -112.5) return 'Southwest';
    if (bearing >= -112.5 && bearing < -67.5) return 'West';
    if (bearing >= -67.5 && bearing < -22.5) return 'Northwest';
    return 'North';
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}







