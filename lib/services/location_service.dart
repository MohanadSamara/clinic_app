import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;

/// Service for handling GPS location and route optimization
class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permissions
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permissions
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current location
  Future<Position> getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Calculate distance between two coordinates in kilometers
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  double sin(double radians) {
    // Using Taylor series approximation for sine
    double result = radians;
    double term = radians;
    for (int i = 1; i < 10; i++) {
      term *= -radians * radians / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  /// Estimate travel time based on distance (assuming average speed of 40 km/h in city)
  int estimateTravelTime(double distanceKm) {
    const double averageSpeedKmh = 40.0;
    final hours = distanceKm / averageSpeedKmh;
    return (hours * 60).round(); // Return minutes
  }

  /// Optimize route for multiple appointments using nearest neighbor algorithm
  /// Returns list of appointment indices in optimized order
  List<int> optimizeRoute({
    required double startLat,
    required double startLon,
    required List<Map<String, dynamic>> appointments,
  }) {
    if (appointments.isEmpty) return [];
    if (appointments.length == 1) return [0];

    List<int> route = [];
    List<int> unvisited = List.generate(appointments.length, (i) => i);

    double currentLat = startLat;
    double currentLon = startLon;

    // Nearest neighbor algorithm
    while (unvisited.isNotEmpty) {
      int nearestIndex = -1;
      double nearestDistance = double.infinity;

      for (int i = 0; i < unvisited.length; i++) {
        final idx = unvisited[i];
        final apt = appointments[idx];

        if (apt['location_lat'] == null || apt['location_lng'] == null) {
          continue;
        }

        final distance = calculateDistance(
          lat1: currentLat,
          lon1: currentLon,
          lat2: apt['location_lat'],
          lon2: apt['location_lng'],
        );

        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestIndex = i;
        }
      }

      if (nearestIndex == -1) {
        // No valid location found, add remaining appointments in order
        route.addAll(unvisited);
        break;
      }

      final selectedIdx = unvisited[nearestIndex];
      route.add(selectedIdx);

      final apt = appointments[selectedIdx];
      currentLat = apt['location_lat'];
      currentLon = apt['location_lng'];

      unvisited.removeAt(nearestIndex);
    }

    return route;
  }

  /// Calculate total route distance and estimated time
  Map<String, dynamic> calculateRouteMetrics({
    required double startLat,
    required double startLon,
    required List<Map<String, dynamic>> appointments,
    required List<int> routeOrder,
  }) {
    double totalDistance = 0.0;
    double currentLat = startLat;
    double currentLon = startLon;

    for (int idx in routeOrder) {
      final apt = appointments[idx];
      if (apt['location_lat'] != null && apt['location_lng'] != null) {
        final distance = calculateDistance(
          lat1: currentLat,
          lon1: currentLon,
          lat2: apt['location_lat'],
          lon2: apt['location_lng'],
        );
        totalDistance += distance;
        currentLat = apt['location_lat'];
        currentLon = apt['location_lng'];
      }
    }

    final estimatedMinutes = estimateTravelTime(totalDistance);

    return {
      'total_distance': totalDistance,
      'estimated_duration': estimatedMinutes,
      'route_order': routeOrder,
    };
  }

  /// Get address from coordinates (reverse geocoding)
  /// Note: This is a placeholder. For actual implementation, you would need
  /// to integrate with a geocoding service like Google Maps API
  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    // Placeholder implementation
    return 'Lat: ${latitude.toStringAsFixed(6)}, Lon: ${longitude.toStringAsFixed(6)}';
  }

  /// Get coordinates from address (forward geocoding)
  /// Note: This is a placeholder. For actual implementation, you would need
  /// to integrate with a geocoding service
  Future<Map<String, double>> getCoordinatesFromAddress(String address) async {
    // Placeholder implementation
    throw UnimplementedError('Geocoding service not implemented');
  }

  /// Stream location updates
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  /// Check if a location is within a certain radius of another location
  bool isWithinRadius({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
    required double radiusKm,
  }) {
    final distance = calculateDistance(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );
    return distance <= radiusKm;
  }

  /// Format coordinates for display
  String formatCoordinates(double latitude, double longitude) {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lonDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(6)}°$latDir, ${longitude.abs().toStringAsFixed(6)}°$lonDir';
  }
}
