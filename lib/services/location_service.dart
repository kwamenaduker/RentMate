import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  // Default location (can be used as a fallback)
  final LatLng defaultLocation = const LatLng(37.7749, -122.4194); // San Francisco

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Request location permission
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  // Get the current position of the device
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Request permission
      LocationPermission permission = await requestPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  // Get LatLng from current position
  Future<LatLng> getCurrentLatLng() async {
    Position? position = await getCurrentPosition();
    
    if (position != null) {
      return LatLng(position.latitude, position.longitude);
    } else {
      return defaultLocation;
    }
  }

  // Get address from coordinates
  Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return _formatAddress(place);
      }
      
      return 'Unknown location';
    } catch (e) {
      debugPrint('Error getting address: $e');
      return 'Unknown location';
    }
  }

  // Get coordinates from address
  Future<LatLng?> getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        Location location = locations[0];
        return LatLng(location.latitude, location.longitude);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting coordinates: $e');
      return null;
    }
  }

  // Calculate distance between two points in kilometers
  double calculateDistance(LatLng point1, LatLng point2) {
    // Using the Haversine formula
    const int earthRadius = 6371; // Radius of the earth in km
    
    double latDistance = _degreesToRadians(point2.latitude - point1.latitude);
    double lonDistance = _degreesToRadians(point2.longitude - point1.longitude);
    
    double a = sin(latDistance / 2) * sin(latDistance / 2) +
        cos(_degreesToRadians(point1.latitude)) * 
        cos(_degreesToRadians(point2.latitude)) * 
        sin(lonDistance / 2) * sin(lonDistance / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c; // Distance in km
  }

  // Helper function to convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Search for locations by query
  Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }
      
      // Using geocoding package to search for locations
      List<Location> locations = await locationFromAddress(query);
      List<Map<String, dynamic>> results = [];
      
      for (var location in locations) {
        // Get the address for these coordinates
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          String address = _formatAddress(placemarks[0]);
          results.add({
            'description': address,
            'latitude': location.latitude,
            'longitude': location.longitude,
          });
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Error searching locations: $e');
      return [];
    }
  }

  // Format address from Placemark
  String _formatAddress(Placemark place) {
    List<String> addressParts = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      addressParts.add(place.postalCode!);
    }
    
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }
    
    return addressParts.join(', ');
  }
}
