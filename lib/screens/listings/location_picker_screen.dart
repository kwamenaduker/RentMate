import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/services/location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  
  const LocationPickerScreen({
    Key? key,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  LatLng? _selectedLocation;
  String _selectedAddress = 'Loading address...';
  bool _isLoading = false;
  
  Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _updateMarkers();
    
    // If we have an initial location, get its address
    if (_selectedLocation != null) {
      _getAddressFromLocation(_selectedLocation!);
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _updateMarkers() {
    if (_selectedLocation == null) return;
    
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
              _getAddressFromLocation(newPosition);
            });
          },
        ),
      };
    });
  }
  
  Future<void> _getAddressFromLocation(LatLng location) async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final address = await locationService.getAddressFromLatLng(location);
      
      setState(() {
        _selectedAddress = address;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _selectedAddress = 'Unable to get address';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final location = await locationService.getLatLngFromAddress(_searchController.text);
      
      if (location != null) {
        setState(() {
          _selectedLocation = location;
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(location, 15),
          );
          _updateMarkers();
        });
        
        _getAddressFromLocation(location);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching location: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final position = await locationService.getCurrentPosition();
      
      if (position != null) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
          );
          _updateMarkers();
        });
        
        _getAddressFromLocation(_selectedLocation!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get current location')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting current location: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _updateMarkers();
    });
    
    _getAddressFromLocation(position);
  }
  
  @override
  Widget build(BuildContext context) {
    // Default to San Francisco if no location is selected
    final initialCameraPosition = CameraPosition(
      target: _selectedLocation ?? const LatLng(37.7749, -122.4194),
      zoom: 14.0,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop({
                  'location': _selectedLocation,
                  'address': _selectedAddress,
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Search bar and current location button
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for a location',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        suffixIcon: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _searchLocation,
                              ),
                      ),
                      onSubmitted: (_) => _searchLocation(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentLocation,
                  ),
                ],
              ),
            ),
          ),
          
          // Selected location info
          if (_selectedLocation != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Selected Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_selectedAddress),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Coordinates: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                          '${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop({
                            'location': _selectedLocation,
                            'address': _selectedAddress,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
