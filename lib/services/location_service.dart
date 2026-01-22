import 'package:geolocator/geolocator.dart';
import 'package:civicfix/models/location_model.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<LocationModel?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        debugPrint('Location permission denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      final address = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      debugPrint('Failed to get current location: $e');
      return null;
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  LocationModel getMockLocation(String city) {
    final mockLocations = {
      'Downtown': LocationModel(
        latitude: 40.7589,
        longitude: -73.9851,
        address: 'Times Square, New York, NY 10036',
        landmark: 'Near Times Square',
      ),
      'Midtown': LocationModel(
        latitude: 40.7505,
        longitude: -73.9934,
        address: '5th Avenue, New York, NY 10001',
        landmark: 'Near Empire State Building',
      ),
      'Brooklyn': LocationModel(
        latitude: 40.6782,
        longitude: -73.9442,
        address: 'Brooklyn Heights, Brooklyn, NY 11201',
        landmark: 'Near Brooklyn Bridge',
      ),
      'Queens': LocationModel(
        latitude: 40.7282,
        longitude: -73.7949,
        address: 'Flushing, Queens, NY 11354',
        landmark: 'Near Queens Center',
      ),
    };

    return mockLocations[city] ?? mockLocations['Downtown']!;
  }
}
