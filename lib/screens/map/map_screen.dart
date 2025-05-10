import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/models/listing_model.dart';
import 'package:rent_mate/services/listing_service.dart';
import 'package:rent_mate/screens/listings/listing_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ListingService _listingService = ListingService();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _errorMessage;
  double _searchRadius = 5.0; // in km
  List<ListingModel> _nearbyListings = [];

  // Default camera position (will be updated with user's current location)
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 13,
  );

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Get user's current position
  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request location permission using permission_handler
      final status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() {
          _errorMessage = 'Location permission denied. Please enable it in your app settings.';
          _isLoading = false;
        });
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them in your device settings.';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      // Move camera to current position
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 13,
            ),
          ),
        );
      }

      // Load nearby listings
      await _loadNearbyListings();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  // Load listings near the user's current location
  Future<void> _loadNearbyListings() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
      _markers = {};
    });

    try {
      final GeoPoint userLocation = GeoPoint(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      // Get nearby listings
      _nearbyListings = await _listingService.getNearbyListings(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _searchRadius,
        20, // Maximum 20 results
      );

      // Create map markers for each listing
      _createMarkers();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading listings: $e';
        _isLoading = false;
      });
    }
  }

  // Create map markers for listings
  void _createMarkers() {
    Set<Marker> markers = {};

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
          ),
        ),
      );
    }

    // Add listing markers
    for (var listing in _nearbyListings) {
      markers.add(
        Marker(
          markerId: MarkerId(listing.id),
          position: LatLng(
            listing.location.latitude,
            listing.location.longitude,
          ),
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: listing.title,
            snippet: '\$${listing.price.toStringAsFixed(2)} / month',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListingDetailsScreen(listingId: listing.id),
                ),
              );
            },
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  // Handle marker tap
  void _onMarkerTapped(ListingModel listing) {
    // Navigate to listing details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingDetailsScreen(listingId: listing.id),
      ),
    );
  }

  // Update search radius
  void _updateSearchRadius(double radius) {
    setState(() {
      _searchRadius = radius;
    });

    _loadNearbyListings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Rentals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _determinePosition,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _determinePosition,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _currentPosition == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off, color: Colors.grey, size: 48),
                          const SizedBox(height: 12),
                          const Text('Could not determine your location.'),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _determinePosition,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        // Google Map
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            zoom: 13,
                          ),
                          onMapCreated: (controller) {
                            _mapController = controller;

                            // Move to user's location if available
                            if (_currentPosition != null) {
                              controller.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: LatLng(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                    ),
                                    zoom: 13,
                                  ),
                                ),
                              );
                            }
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          markers: _markers,
                        ),

                        // Loading indicator
                        if (_isLoading)
                          const Center(
                            child: Card(
                              color: Colors.white,
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),

                        // Search radius control
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Search Radius: ${_searchRadius.toStringAsFixed(1)} km',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Slider(
                                    value: _searchRadius,
                                    min: 1.0,
                                    max: 20.0,
                                    divisions: 19,
                                    label: '${_searchRadius.toStringAsFixed(1)} km',
                                    onChanged: (value) {
                                      setState(() {
                                        _searchRadius = value;
                                      });
                                    },
                                    onChangeEnd: (value) {
                                      _updateSearchRadius(value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Results count
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Card(
                            color: AppTheme.primaryColor,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Text(
                                '${_nearbyListings.length} listings found',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Current location button - moved to top right instead of bottom
                        Positioned(
                          top: 80, // Below the search radius control
                          right: 16,
                          child: FloatingActionButton(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            mini: true,
                            onPressed: () {
                              if (_currentPosition != null && _mapController != null) {
                                _mapController!.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                      target: LatLng(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                      ),
                                      zoom: 13,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                      ],
                    ),
      // Compact nearby listings chips at the bottom of the screen
      bottomSheet: _nearbyListings.isEmpty || _errorMessage != null
          ? null
          : Container(
              height: 70, // Much smaller height
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 8.0, right: 16.0, bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nearby Properties',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_nearbyListings.length} found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Horizontal list of circle avatars with prices
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: _nearbyListings.length,
                      itemBuilder: (context, index) {
                        final listing = _nearbyListings[index];
                        // Compact chips with price
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListingDetailsScreen(listingId: listing.id),
                                ),
                              );
                            },
                            child: Chip(
                              avatar: CircleAvatar(
                                backgroundImage: listing.imageUrls.isNotEmpty
                                    ? NetworkImage(listing.imageUrls.first)
                                    : null,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                                child: listing.imageUrls.isEmpty
                                    ? const Icon(Icons.home, size: 12, color: AppTheme.primaryColor)
                                    : null,
                              ),
                              label: Text(
                                '\$${listing.price.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey[300]!),
                              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(0),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
