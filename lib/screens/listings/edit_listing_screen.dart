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

class EditListingScreen extends StatefulWidget {
  final ListingModel listing;
  
  const EditListingScreen({
    Key? key, 
    required this.listing,
  }) : super(key: key);

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ListingService _listingService = ListingService();
  final ImagePicker _picker = ImagePicker();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _addressController;
  
  late String _selectedCategory;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<String> _existingImageUrls = [];
  List<File> _newImages = [];
  GeoPoint? _location;
  late List<String> _selectedAmenities;
  DateTime? _availableFrom;
  DateTime? _availableTo;
  bool _isSearchingLocation = false;
  List<Map<String, dynamic>> _searchResults = [];
  late bool _isAvailable;
  
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
  void initState() {
    super.initState();
    
    // Initialize controllers with existing listing data
    _titleController = TextEditingController(text: widget.listing.title);
    _descriptionController = TextEditingController(text: widget.listing.description);
    _priceController = TextEditingController(text: widget.listing.price.toString());
    _addressController = TextEditingController(text: widget.listing.address);
    
    // Set other values from the listing
    _selectedCategory = widget.listing.category;
    _existingImageUrls = List.from(widget.listing.imageUrls);
    _location = widget.listing.location;
    _selectedAmenities = List.from(widget.listing.amenities);
    _availableFrom = widget.listing.availableFrom;
    _availableTo = widget.listing.availableTo;
    _isAvailable = widget.listing.isAvailable;
  }
  
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
          _newImages.addAll(pickedFiles.map((e) => File(e.path)).toList());
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
          _newImages.add(File(photo.path));
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error taking picture: $e';
      });
    }
  }
  
  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }
  
  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
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
        Placemark place = placemarks[0];
        String address = '';
        
        if (place.street != null && place.street!.isNotEmpty) {
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
        
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          if (address.isNotEmpty) address += ' ';
          address += place.postalCode!;
        }
        
        setState(() {
          _addressController.text = address;
          _location = GeoPoint(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime now = DateTime.now();
    final initialDate = isStartDate ? _availableFrom ?? now : _availableTo ?? now;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    
    if (picked != null && picked != (isStartDate ? _availableFrom : _availableTo)) {
      setState(() {
        if (isStartDate) {
          _availableFrom = picked;
          // If end date is before start date, clear end date
          if (_availableTo != null && _availableTo!.isBefore(picked)) {
            _availableTo = null;
          }
        } else {
          _availableTo = picked;
        }
      });
    }
  }
  
  Future<void> _searchLocationsByQuery(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearchingLocation = false;
        _searchResults = [];
      });
      return;
    }
    
    setState(() {
      _isSearchingLocation = true;
    });
    
    try {
      final locationService = context.read<LocationService>();
      // Use the LocationService method to search for places
      // If searchPlaces doesn't exist, fall back to a simpler implementation
      final results = await locationService.searchLocation(query) ?? [];
      
      setState(() {
        _searchResults = results;
        _isSearchingLocation = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching locations: $e';
        _isSearchingLocation = false;
      });
    }
  }
  
  void _selectLocation(Map<String, dynamic> location) {
    setState(() {
      _addressController.text = location['description'];
      _location = GeoPoint(location['latitude'], location['longitude']);
      _searchResults = [];
      _isSearchingLocation = false;
    });
  }
  
  Future<void> _updateListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least one image';
      });
      return;
    }
    
    if (_location == null) {
      setState(() {
        _errorMessage = 'Please select a location';
      });
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      // First, upload any new images
      List<String> allImageUrls = [..._existingImageUrls];
      
      // Only upload new images if there are any
      if (_newImages.isNotEmpty) {
        // Use the listing service to upload images
        for (var image in _newImages) {
          // Upload image using the public method
          final imageUrl = await _listingService.uploadListingImage(
            image,
            widget.listing.ownerId,
          );
          allImageUrls.add(imageUrl);
        }
      }
      
      // Create updated listing object
      final updatedListing = widget.listing.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        imageUrls: allImageUrls,
        location: _location,
        address: _addressController.text,
        category: _selectedCategory,
        availableFrom: _availableFrom,
        availableTo: _availableTo,
        isAvailable: _isAvailable,
        amenities: _selectedAmenities,
      );
      
      // Update the listing
      await _listingService.updateListing(updatedListing);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error updating listing: $e';
      });
    }
  }
  
  Future<void> _openLocationPicker() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPickerScreen(
            initialLocation: _location != null
                ? LatLng(_location!.latitude, _location!.longitude)
                : null,
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
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking location: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic information section
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
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                maxLines: 5,
                minLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Price field
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (\$/month)',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categoryOptions
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Images section
              Text(
                'Images',
                style: AppTheme.subheadingStyle,
              ),
              const SizedBox(height: 16),
              
              // Display existing images
              if (_existingImageUrls.isNotEmpty) ...[
                const Text('Current Images:'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImageUrls.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(_existingImageUrls[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeExistingImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Display new images
              if (_newImages.isNotEmpty) ...[
                const Text('New Images:'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_newImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeNewImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Add image buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Select Images'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Location section
              Text(
                'Location',
                style: AppTheme.subheadingStyle,
              ),
              const SizedBox(height: 16),
              
              // Location field with search
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.map),
                        onPressed: _openLocationPicker,
                        tooltip: 'Pick on Map',
                      ),
                      IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _getUserLocation,
                        tooltip: 'Use Current Location',
                      ),
                    ],
                  ),
                ),
                onChanged: (value) {
                  _searchLocationsByQuery(value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              
              // Show loading indicator while searching
              if (_isSearchingLocation)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              
              // Show search results
              if (_searchResults.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  margin: const EdgeInsets.only(top: 8),
                  height: 200,
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        title: Text(result['description']),
                        onTap: () => _selectLocation(result),
                      );
                    },
                  ),
                ),
                
              const SizedBox(height: 32),
              
              // Amenities section
              Text(
                'Amenities',
                style: AppTheme.subheadingStyle,
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
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
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
              
              const SizedBox(height: 16),
              
              // Availability switch
              SwitchListTile(
                title: const Text('Available for rent'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
                activeColor: AppTheme.primaryColor,
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
                  onPressed: _isSubmitting ? null : _updateListing,
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
                            'Update Listing',
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
