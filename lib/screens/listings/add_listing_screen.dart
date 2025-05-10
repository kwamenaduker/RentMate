import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/models/listing_model.dart';
import 'package:rent_mate/services/auth_service.dart';
import 'package:rent_mate/services/listing_service.dart';
import 'package:rent_mate/services/location_service.dart';
import 'package:rent_mate/screens/listings/location_picker_screen.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({Key? key}) : super(key: key);

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ListingService _listingService = ListingService();
  final ImagePicker _picker = ImagePicker();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _selectedCategory = 'Apartment';
  bool _isSubmitting = false;
  String? _errorMessage;
  List<File> _selectedImages = [];
  GeoPoint? _location;
  List<String> _selectedAmenities = [];
  DateTime? _availableFrom;
  DateTime? _availableTo;
  bool _isSearchingLocation = false;
  List<Map<String, dynamic>> _searchResults = [];
  
  // TextEditingController for the search field
  final _searchController = TextEditingController();
  
  final List<String> _categoryOptions = [
    'Apartment',
    'House',
    'Room',
    'Office',
    'Land',
    'Other',
  ];
  
  final List<String> _amenityOptions = [
    'Wifi',
    'Kitchen',
    'Parking',
    'Air Conditioning',
    'Heating',
    'TV',
    'Washer',
    'Dryer',
    'Pool',
    'Gym',
    'Elevator',
    'Furnished',
    'Pet Friendly',
    'Smoke Free',
    'Balcony',
    'Security System',
  ];
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((e) => File(e.path)).toList());
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking images: $e';
      });
    }
  }
  
  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      
      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error taking picture: $e';
      });
    }
  }
  
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
  
  Future<void> _getUserLocation() async {
    try {
      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission denied';
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permission permanently denied';
        });
        return;
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition();
      
      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '${place.street}, ${place.locality}, ${place.administrativeArea}';
        
        setState(() {
          _location = GeoPoint(position.latitude, position.longitude);
          _addressController.text = address;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _availableFrom = picked;
          
          // If end date is before start date, reset it
          if (_availableTo != null && _availableTo!.isBefore(_availableFrom!)) {
            _availableTo = null;
          }
        } else {
          _availableTo = picked;
        }
      });
    }
  }
  
  // Search locations by query
  Future<void> _searchLocationsByQuery(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchingLocation = false;
      });
      return;
    }
    
    setState(() {
      _isSearchingLocation = true;
    });
    
    try {
      List<Location> locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        // Get address details for each location
        List<Map<String, dynamic>> results = [];
        
        for (var location in locations) {
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            );
            
            if (placemarks.isNotEmpty) {
              Placemark place = placemarks.first;
              String address = '';
              
              // Build a complete address
              if (place.name != null && place.name!.isNotEmpty) {
                address += place.name!;
              }
              
              if (place.street != null && place.street!.isNotEmpty) {
                if (address.isNotEmpty) address += ', ';
                address += place.street!;
              }
              
              if (place.locality != null && place.locality!.isNotEmpty) {
                if (address.isNotEmpty) address += ', ';
                address += place.locality!;
              }
              
              if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
                if (address.isNotEmpty) address += ', ';
                address += place.administrativeArea!;
              }
              
              if (place.country != null && place.country!.isNotEmpty) {
                if (address.isNotEmpty) address += ', ';
                address += place.country!;
              }
              
              results.add({
                'address': address,
                'latitude': location.latitude,
                'longitude': location.longitude,
              });
            }
          } catch (e) {
            print('Error getting placemark: $e');
          }
        }
        
        setState(() {
          _searchResults = results;
          _isSearchingLocation = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearchingLocation = false;
        });
      }
    } catch (e) {
      print('Error searching locations: $e');
      setState(() {
        _searchResults = [];
        _isSearchingLocation = false;
      });
    }
  }
  
  // Select a location from search results
  void _selectLocation(Map<String, dynamic> location) {
    setState(() {
      _location = GeoPoint(location['latitude'], location['longitude']);
      _addressController.text = location['address'];
      _searchResults = [];
      _searchController.clear();
    });
  }
  
  // Submit the listing
  Future<void> _submitListing() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedImages.isEmpty) {
        setState(() {
          _errorMessage = 'Please add at least one image';
        });
        return;
      }
      
      if (_location == null) {
        setState(() {
          _errorMessage = 'Please set the location';
        });
        return;
      }
      
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      
      try {
        final AuthService authService = context.read<AuthService>();
        
        if (!authService.isLoggedIn) {
          setState(() {
            _errorMessage = 'You must be logged in to create a listing';
            _isSubmitting = false;
          });
          return;
        }
        
        // Get user data for owner details
        final userData = await authService.getCurrentUserData();
        
        if (userData == null) {
          setState(() {
            _errorMessage = 'Error getting user data';
            _isSubmitting = false;
          });
          return;
        }
        
        // Create listing model
        final ListingModel newListing = ListingModel(
          id: '',  // Will be set by Firebase
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          ownerId: userData.id,
          ownerName: userData.name,
          ownerPhoneNumber: userData.phoneNumber,
          imageUrls: [],  // Will be populated after upload
          location: _location!,
          address: _addressController.text,
          category: _selectedCategory,
          createdAt: DateTime.now(),
          isAvailable: true,
          availableFrom: _availableFrom,
          availableTo: _availableTo,
          amenities: _selectedAmenities,
        );
        
        // Show a progress dialog while uploading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Creating Listing'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Uploading ${_selectedImages.length} image${_selectedImages.length > 1 ? 's' : ''}...'),
                  const SizedBox(height: 8),
                  const Text('Please wait, this may take a moment.', 
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        );
        
        // Create listing and upload images
        final listingId = await _listingService.createListing(
          newListing,
          _selectedImages,
        );
        
        // Close the progress dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing created successfully'),
              backgroundColor: AppTheme.primaryColor,
              duration: Duration(seconds: 2),
            ),
          );
          
          Navigator.pop(context, listingId);
        }
      } catch (e) {
        // Close the progress dialog if it's showing
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        setState(() {
          _errorMessage = 'Error creating listing: $e';
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $_errorMessage'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _submitListing,
            ),
          ),
        );
      }
    }
  }
  
  // Open location picker
  Future<void> _openLocationPicker() async {
    LatLng? initialLocation;
    if (_location != null) {
      initialLocation = LatLng(_location!.latitude, _location!.longitude);
    }
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: initialLocation,
        ),
      ),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      final LatLng location = result['location'];
      final String address = result['address'];
      
      setState(() {
        _location = GeoPoint(location.latitude, location.longitude);
        _addressController.text = address;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Listing'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images section
              Text(
                'Add Images',
                style: AppTheme.subheadingStyle,
              ),
              const SizedBox(height: 8),
              const Text(
                'Add up to 10 images of your rental property',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              
              // Image picker
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Add image buttons
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.photo_library),
                            color: AppTheme.primaryColor,
                          ),
                          const Text(
                            'Gallery',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _takePicture,
                            icon: const Icon(Icons.camera_alt),
                            color: AppTheme.primaryColor,
                          ),
                          const Text(
                            'Camera',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    
                    // Image preview list
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(_selectedImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_selectedImages.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text(
                    'Please add at least one image',
                    style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
                  ),
                ),
                
              const SizedBox(height: 24),
              
              // Basic info section
              Text(
                'Basic Information',
                style: AppTheme.subheadingStyle,
              ),
              const SizedBox(height: 16),
              
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter a descriptive title',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                value: _selectedCategory,
                items: _categoryOptions.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Price field
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (per month)',
                  hintText: 'Enter the rental price',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Location input
              const SizedBox(height: 24),
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter property address',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: _openLocationPicker,
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the property address';
                  }
                  return null;
                },
                onTap: _openLocationPicker,
              ),
              
              if (_location != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_location!.latitude, _location!.longitude),
                        zoom: 14,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('property_location'),
                          position: LatLng(_location!.latitude, _location!.longitude),
                        ),
                      },
                      zoomControlsEnabled: false,
                      scrollGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: false,
                      mapToolbarEnabled: false,
                      liteModeEnabled: true,
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Description section
              Text(
                'Description',
                style: AppTheme.subheadingStyle,
              ),
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your property in detail',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 20) {
                    return 'Description should be at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Amenities section
              Text(
                'Amenities',
                style: AppTheme.subheadingStyle,
              ),
              const SizedBox(height: 8),
              const Text(
                'Select available amenities',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              
              // Amenities selection
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _amenityOptions.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Availability section
              Text(
                'Availability',
                style: AppTheme.subheadingStyle,
              ),
              const SizedBox(height: 16),
              
              // Available from date
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _availableFrom != null
                            ? 'From: ${_formatDate(_availableFrom!)}'
                            : 'Available From (Optional)',
                      ),
                      onPressed: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _availableFrom == null
                        ? null
                        : () {
                            setState(() {
                              _availableFrom = null;
                            });
                          },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Available to date
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _availableTo != null
                            ? 'To: ${_formatDate(_availableTo!)}'
                            : 'Available To (Optional)',
                      ),
                      onPressed: () => _selectDate(context, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _availableTo == null
                        ? null
                        : () {
                            setState(() {
                              _availableTo = null;
                            });
                          },
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitListing,
                  child: _isSubmitting
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'Submit Listing',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
