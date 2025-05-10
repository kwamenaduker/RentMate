import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../models/listing_model.dart';
import '../services/notification_service.dart';

class ListingService {
  // Flag to enable demo mode for testing without Firebase
  // Set to false to use real Firebase integration
  final bool _demoMode = false;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Mock listings for demo mode (kept for fallback testing)
  final List<ListingModel> _mockListings = [
    ListingModel(
      id: 'listing-1',
      title: 'Cozy 2 Bedroom Apartment',
      description: 'A beautiful apartment with modern amenities, close to public transport and shopping centers. Perfect for small families or professionals.',
      price: 1200.00,
      ownerId: 'owner-1',
      ownerName: 'John Smith',
      ownerPhoneNumber: '+1234567890',
      imageUrls: [
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688',
        'https://images.unsplash.com/photo-1560448204-603b3fc33ddc',
      ],
      location: const GeoPoint(37.7749, -122.4194), // San Francisco
      address: '123 Main St, San Francisco, CA',
      category: 'Apartment',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      isAvailable: true,
      amenities: ['WiFi', 'Parking', 'Air Conditioning', 'Furnished'],
    ),
    ListingModel(
      id: 'listing-2',
      title: 'Modern Studio Downtown',
      description: 'Beautiful studio in the heart of downtown. Walking distance to restaurants, shops, and public transportation.',
      price: 950.00,
      ownerId: 'owner-2',
      ownerName: 'Sarah Johnson',
      ownerPhoneNumber: '+1987654321',
      imageUrls: [
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
        'https://images.unsplash.com/photo-1560185127-6ed189bf02f4',
      ],
      location: const GeoPoint(37.7833, -122.4167), // San Francisco
      address: '456 Market St, San Francisco, CA',
      category: 'Room',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isAvailable: true,
      amenities: ['WiFi', 'Kitchen', 'Washer', 'Dryer'],
    ),
    ListingModel(
      id: 'listing-3',
      title: 'Luxury House with Pool',
      description: 'Spacious 4-bedroom house with a swimming pool and large backyard. Perfect for families or group of friends.',
      price: 3500.00,
      ownerId: 'owner-3',
      ownerName: 'Michael Brown',
      ownerPhoneNumber: '+1122334455',
      imageUrls: [
        'https://images.unsplash.com/photo-1580587771525-78b9dba3b914',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750',
      ],
      location: const GeoPoint(37.7680, -122.4464), // San Francisco
      address: '789 Oak St, San Francisco, CA',
      category: 'House',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      availableFrom: DateTime.now().add(const Duration(days: 14)),
      isAvailable: true,
      amenities: ['Pool', 'Garden', 'Parking', 'WiFi', 'Furnished'],
    ),
  ];

  // Create a new listing
  Future<String> createListing(ListingModel listing, List<File> images) async {
    try {
      if (_demoMode) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));
        
        // Create mock listing
        final String id = 'listing-${DateTime.now().millisecondsSinceEpoch}';
        final List<String> mockImageUrls = [
          'https://images.unsplash.com/photo-1560185007-5f0bb1866cab',
          'https://images.unsplash.com/photo-1560185127-6ed189bf02f4',
        ];
        
        final mockListing = listing.copyWith(
          id: id,
          imageUrls: mockImageUrls,
          createdAt: DateTime.now(),
        );
        
        _mockListings.add(mockListing);
        
        return id;
      }
      
      // Upload images first and get URLs
      List<String> imageUrls = [];
      
      for (var image in images) {
        String imageUrl = await _uploadImage(image, listing.ownerId);
        imageUrls.add(imageUrl);
      }
      
      // Create a new document reference
      DocumentReference docRef = _firestore.collection('listings').doc();
      
      // Create listing with image URLs and ID
      final newListing = listing.copyWith(
        id: docRef.id,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
      );
      
      // Save to Firestore
      await docRef.set(newListing.toMap());
      
      return docRef.id;
    } catch (e) {
      print('Error creating listing: $e');
      rethrow;
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File image, String userId) async {
    try {
      // Create a unique filename
      String fileName = 'listing_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}.jpg';
      
      // Create a reference to the file location
      Reference ref = _storage.ref().child('listings/$userId/$fileName');
      
      // Upload the file
      UploadTask uploadTask = ref.putFile(image);
      
      // Get download URL once upload completes
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  // Get all listings
  Stream<List<ListingModel>> getAllListings() {
    try {
      if (_demoMode) {
        // Return mock listings as a stream
        return Stream.value(_mockListings);
      }
      
      // Return a stream from Firestore query
      return _firestore
          .collection('listings')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
              .map((doc) => ListingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          });
    } catch (e) {
      print('Error getting all listings: $e');
      return Stream.value([]);
    }
  }

  // Get listings by category
  Stream<List<ListingModel>> getListingsByCategory(String category) {
    try {
      if (_demoMode) {
        // Filter mock listings by category
        final filteredListings = category == 'All'
            ? _mockListings
            : _mockListings.where((listing) => listing.category == category).toList();
        return Stream.value(filteredListings);
      }
      
      // Use Firestore query to get a stream
      Query query = _firestore.collection('listings');
      
      // Only filter by category if it's not 'All'
      if (category != 'All') {
        query = query.where('category', isEqualTo: category);
      }
      
      return query
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => ListingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                .toList();
          });
    } catch (e) {
      print('Error getting listings by category: $e');
      return Stream.value([]);
    }
  }

  // Get listings by owner
  Stream<List<ListingModel>> getListingsByOwner(String ownerId) {
    try {
      if (_demoMode) {
        // Filter mock listings by owner
        final ownerListings = _mockListings.where((listing) => listing.ownerId == ownerId).toList();
        return Stream.value(ownerListings);
      }
      
      // Return a stream from Firestore query
      return _firestore
          .collection('listings')
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => ListingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                .toList();
          });
    } catch (e) {
      print('Error getting listings by owner: $e');
      return Stream.value([]);
    }
  }

  // Get nearby listings
  Future<List<ListingModel>> getNearbyListings(
    double latitude,
    double longitude,
    double radiusInKm,
    int maxResults,
  ) async {
    try {
      if (_demoMode) {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Return all mock listings for demo (limited to maxResults)
        return _mockListings.take(maxResults).toList();
      }
      
      // Get all listings (in a real app, you'd use geohashing or a specialized
      // geospatial query solution like Firestore's GeoPoint queries or Firebase Extensions)
      QuerySnapshot snapshot = await _firestore.collection('listings').get();
      
      List<ListingModel> listings = snapshot.docs
          .map((doc) => ListingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Filter listings by distance
      var nearbyListings = listings.where((listing) {
        // Calculate distance using Haversine formula
        double distance = _calculateDistance(
          latitude,
          longitude,
          listing.location.latitude,
          listing.location.longitude,
        );
        
        return distance <= radiusInKm;
      }).toList();
      
      // Limit to maxResults
      if (nearbyListings.length > maxResults) {
        nearbyListings = nearbyListings.sublist(0, maxResults);
      }
      
      return nearbyListings;
    } catch (e) {
      print('Error getting nearby listings: $e');
      return [];
    }
  }

  // Get a listing by ID
  Future<ListingModel?> getListingById(String id) async {
    try {
      if (_demoMode) {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Find matching listing
        final listing = _mockListings.firstWhere(
          (listing) => listing.id == id,
          orElse: () => throw Exception('Listing not found'),
        );
        
        return listing;
      }
      
      DocumentSnapshot doc = await _firestore.collection('listings').doc(id).get();
      
      if (doc.exists) {
        return ListingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      
      return null;
    } catch (e) {
      print('Error getting listing by ID: $e');
      return null;
    }
  }

  // Update a listing
  Future<void> updateListing(ListingModel listing, {NotificationService? notificationService, ListingModel? oldListing}) async {
    try {
      if (_demoMode) {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Update mock listing
        final index = _mockListings.indexWhere((item) => item.id == listing.id);
        if (index != -1) {
          // Check if availability has changed
          final previousListing = _mockListings[index];
          final availabilityChanged = previousListing.isAvailable != listing.isAvailable;
          
          // Update the listing
          _mockListings[index] = listing;
          
          // Create notification if availability changed
          if (availabilityChanged && notificationService != null) {
            _notifyAvailabilityChange(notificationService, listing);
          }
        }
        
        return;
      }
      
      // For real Firebase mode
      if (oldListing != null && oldListing.isAvailable != listing.isAvailable && notificationService != null) {
        // Availability status has changed, notify users
        _notifyAvailabilityChange(notificationService, listing);
      }
      
      await _firestore.collection('listings').doc(listing.id).update(listing.toMap());
    } catch (e) {
      print('Error updating listing: $e');
      rethrow;
    }
  }
  
  // Helper method to notify users about listing availability changes
  Future<void> _notifyAvailabilityChange(NotificationService notificationService, ListingModel listing) async {
    try {
      // Create notification for the property owner
      await notificationService.createNotification(
        userId: listing.ownerId,
        title: 'Listing Updated',
        message: 'Your listing "${listing.title}" is now marked as ${listing.isAvailable ? 'available' : 'unavailable'}.',
        targetId: listing.id,
        targetType: 'listing',
      );
      
      // Notify users who have favorited this listing
      await notificationService.notifyListingStatus(
        listing.id,
        listing.title,
        listing.ownerId,
        listing.isAvailable,
      );
    } catch (e) {
      print('Error creating availability change notifications: $e');
    }
  }

  // Delete a listing
  Future<void> deleteListing(String id) async {
    try {
      if (_demoMode) {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Remove from mock listings
        _mockListings.removeWhere((listing) => listing.id == id);
        
        return;
      }
      
      // Get the listing to find image URLs
      DocumentSnapshot doc = await _firestore.collection('listings').doc(id).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<String> imageUrls = List<String>.from(data['imageUrls'] as List);
        
        // Delete images from storage
        for (var url in imageUrls) {
          await _deleteImageFromUrl(url);
        }
        
        // Delete listing document
        await _firestore.collection('listings').doc(id).delete();
      }
    } catch (e) {
      print('Error deleting listing: $e');
      rethrow;
    }
  }

  // Delete image from Firebase Storage
  Future<void> _deleteImageFromUrl(String imageUrl) async {
    try {
      // Extract the path from the URL
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // If image doesn't exist, just continue
      print('Error deleting image: $e');
    }
  }
  
  // Public method for uploading listing images
  // This is used by both create and edit screens
  Future<String> uploadListingImage(File image, String userId) async {
    return _uploadImage(image, userId);
  }

  // Add/remove listing from user favorites
  Future<void> toggleFavorite(String userId, String listingId) async {
    try {
      if (_demoMode) {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 500));
        return;
      }
      
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        List<String> favorites = List<String>.from(userData['favoriteListings'] ?? []);
        
        if (favorites.contains(listingId)) {
          // Remove from favorites
          favorites.remove(listingId);
        } else {
          // Add to favorites
          favorites.add(listingId);
        }
        
        // Update user document
        await _firestore.collection('users').doc(userId).update({
          'favoriteListings': favorites,
        });
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Advanced search listings with multiple criteria
  Future<List<ListingModel>> searchListings(String query) async {
    try {
      if (_demoMode) {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Filter mock listings with more comprehensive search
        return _mockListings
            .where((listing) =>
                listing.title.toLowerCase().contains(query.toLowerCase()) ||
                listing.description.toLowerCase().contains(query.toLowerCase()) ||
                listing.address.toLowerCase().contains(query.toLowerCase()) ||
                listing.category.toLowerCase().contains(query.toLowerCase()) ||
                listing.amenities.any((amenity) => amenity.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }
      
      // This is a more comprehensive search across multiple fields
      // In a production app, you might want to use Algolia or Firebase's full-text search capabilities
      QuerySnapshot snapshot = await _firestore
          .collection('listings')
          .orderBy('createdAt', descending: true)
          .get();
      
      List<ListingModel> searchResults = [];
      List<String> queryWords = query.toLowerCase().split(' ');
      
      for (var doc in snapshot.docs) {
        final listing = ListingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        bool matches = false;
        
        // Check each word in the query to increase relevance
        for (String word in queryWords) {
          if (word.length < 2) continue; // Skip very short words
          
          // Check multiple fields for matches
          if (listing.title.toLowerCase().contains(word) ||
              listing.description.toLowerCase().contains(word) ||
              listing.address.toLowerCase().contains(word) ||
              listing.category.toLowerCase().contains(word) ||
              listing.amenities.any((amenity) => 
                  amenity.toLowerCase().contains(word))) {
            matches = true;
            break; // One match is enough
          }
        }
        
        // If any of the query words match, add to results
        if (matches) {
          searchResults.add(listing);
        }
      }
      
      return searchResults;
    } catch (e) {
      print('Error searching listings: $e');
      return [];
    }
  }
  
  // Helper method to calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radius of Earth in kilometers
    
    // Convert degrees to radians
    double lat1Rad = lat1 * (pi / 180);
    double lon1Rad = lon1 * (pi / 180);
    double lat2Rad = lat2 * (pi / 180);
    double lon2Rad = lon2 * (pi / 180);
    
    // Difference in coordinates
    double dLat = lat2Rad - lat1Rad;
    double dLon = lon2Rad - lon1Rad;
    
    // Haversine formula
    double a = sin(dLat / 2) * sin(dLat / 2) +
               cos(lat1Rad) * cos(lat2Rad) *
               sin(dLon / 2) * sin(dLon / 2);
               
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    // Distance in kilometers
    return earthRadius * c;
  }
}
