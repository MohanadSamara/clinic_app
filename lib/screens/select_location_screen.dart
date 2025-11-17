import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_service.dart';

class SelectLocationScreen extends StatefulWidget {
  final LatLng? destination;
  final bool isNavigationMode;

  const SelectLocationScreen({
    super.key,
    this.destination,
    this.isNavigationMode = false,
  });

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  LatLng _currentLocation = const LatLng(
    31.963158,
    35.930359,
  ); // Default to Amman, Jordan
  bool _isLoading = true;
  bool _mapReady = false;
  String? _selectedAddress;
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  final TextEditingController _addressController = TextEditingController();
  bool _showManualAddressInput = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Add timeout to prevent hanging
      await _locationService.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Location initialization timed out');
        },
      );

      final position = await _locationService.getCurrentLocation().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Location request timed out');
        },
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _updateMarkers();
        _moveMapTo(_currentLocation);
      }
    } catch (e) {
      if (mounted) {
        // Use default location (Amman) as fallback
        setState(() {
          _currentLocation = const LatLng(
            31.963158,
            35.930359,
          ); // Amman, Jordan
          _isLoading = false;
        });
        _updateMarkers();
        _moveMapTo(_currentLocation);

        // Show informative message instead of error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Using default location. You can still select a location on the map.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _selectedLocation = point;
      _updateMarkers();
    });
    _getAddressFromCoordinates(point);
  }

  void _moveMapTo(LatLng position) {
    if (_mapReady) {
      _mapController.move(position, 15.0);
    }
  }

  void _updateMarkers() {
    _markers.clear();
    _polylines.clear();

    // Current location marker (driver)
    _markers.add(
      Marker(
        point: _currentLocation,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            widget.isNavigationMode ? Icons.directions_car : Icons.location_on,
            color: Colors.blue,
            size: 40,
          ),
        ),
      ),
    );

    // Destination marker (pet owner)
    if (widget.destination != null) {
      _markers.add(
        Marker(
          point: widget.destination!,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.location_on, color: Colors.red, size: 40),
          ),
        ),
      );

      // Add polyline connecting source and destination
      _polylines.add(
        Polyline(
          points: [_currentLocation, widget.destination!],
          color: Colors.blue,
          strokeWidth: 4.0,
        ),
      );
    }

    // Selected location marker (for selection mode)
    if (_selectedLocation != null && !widget.isNavigationMode) {
      _markers.add(
        Marker(
          point: _selectedLocation!,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.location_on, color: Colors.green, size: 40),
          ),
        ),
      );
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng point) async {
    final address = await _locationService.getAddressFromCoordinates(
      point.latitude,
      point.longitude,
    );
    setState(() {
      _selectedAddress = address;
      _showManualAddressInput =
          address != null &&
          (address.contains('not available on web') ||
              address.contains('Unable to retrieve') ||
              address.contains('No address found'));
      if (_showManualAddressInput) {
        _addressController.text = '';
      }
    });
  }

  void _confirmLocation() {
    if (widget.isNavigationMode) {
      if (widget.destination != null) {
        _launchGoogleMapsDirections();
      }
    } else {
      if (_selectedLocation != null) {
        final address =
            _showManualAddressInput && _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : _selectedAddress ?? 'Selected location';
        Navigator.of(context).pop({
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          'address': address,
        });
      }
    }
  }

  Future<void> _launchGoogleMapsDirections() async {
    final origin = '${_currentLocation.latitude},${_currentLocation.longitude}';
    final destination =
        '${widget.destination!.latitude},${widget.destination!.longitude}';
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Google Maps')),
        );
      }
    }
  }

  Future<void> _openInGoogleMaps() async {
    if (_selectedLocation != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${_selectedLocation!.latitude},${_selectedLocation!.longitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  void _useCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Location request timed out');
        },
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = latLng;
        _currentLocation = latLng;
        _updateMarkers();
      });
      _moveMapTo(latLng);
      _getAddressFromCoordinates(latLng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error getting current location: ${e.toString().contains('timeout') ? 'Request timed out' : e}',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNavigationMode ? 'Navigation' : 'Select Location'),
        actions: [
          if ((widget.isNavigationMode && widget.destination != null) ||
              (!widget.isNavigationMode && _selectedLocation != null))
            TextButton(
              onPressed: _confirmLocation,
              child: Text(
                widget.isNavigationMode ? 'Start Navigation' : 'Confirm',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation,
                      initialZoom: 13.0,
                      onTap: (tapPosition, point) => _onMapTap(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.clinic_app',
                      ),
                      PolylineLayer(
                        polylineCulling: false,
                        polylines: _polylines,
                      ),
                      MarkerLayer(markers: _markers),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedAddress != null) ...[
                        const Text(
                          'Selected Address:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedAddress!,
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (_showManualAddressInput) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Enter Address Manually:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              hintText: 'Enter address for this location',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            maxLines: 2,
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _useCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Use Current Location'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _selectedLocation != null
                                  ? _confirmLocation
                                  : null,
                              child: const Text('Confirm Location'),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedLocation != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _openInGoogleMaps,
                            icon: const Icon(Icons.map),
                            label: const Text('View in Google Maps'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'Tap on the map to select a location',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
