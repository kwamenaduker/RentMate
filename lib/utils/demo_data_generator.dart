import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rent_mate/models/listing_model.dart';
import 'package:rent_mate/models/user_model.dart';

/// Utility class to generate demo data for RentMate
class DemoDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// List of high-quality property images from Unsplash
  final List<String> _propertyImages = [
    'https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
    'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1392&q=80',
    'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
    'https://images.unsplash.com/photo-1600585154526-990dced4db0d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
    'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
    'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1074&q=80',
  ];
  
  /// List of interior images for property details
  final List<String> _interiorImages = [
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
    'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
    'https://images.unsplash.com/photo-1600566753051-f0b89df2dd90?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1074&q=80',
    'https://images.unsplash.com/photo-1600210491892-03d54c0aaf87?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1074&q=80',
    'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1158&q=80',
    'https://images.unsplash.com/photo-1594611342073-4bb78e4f7cc5?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1974&q=80',
  ];
  
  /// List of demo property listings data
  final List<Map<String, dynamic>> _listingsData = [
    {
      'title': 'Modern Luxury Apartment with City View',
      'description': 'Beautiful modern apartment with an amazing view of the city skyline. This spacious 2-bedroom, 2-bathroom unit features high-end finishes, an open-concept living area, a gourmet kitchen with stainless steel appliances, and a private balcony. Amenities include a fitness center, swimming pool, and 24/7 security.',
      'price': 2500,
      'location': '123 Downtown Avenue, New York, NY',
      'bedrooms': 2,
      'bathrooms': 2,
      'area': 1200,
      'propertyType': 'Apartment',
      'available': true,
      'featured': true,
      'coordinates': {'latitude': 40.7128, 'longitude': -74.0060},
      'amenities': ['Gym', 'Pool', 'Parking', 'Elevator', 'Air Conditioning', 'Balcony'],
    },
    {
      'title': 'Cozy Studio in Historic District',
      'description': 'Charming studio apartment in the heart of the historic district. This newly renovated unit features modern fixtures, hardwood floors, a full kitchen, and plenty of natural light. Perfect for young professionals or students, with easy access to public transportation, restaurants, and shopping.',
      'price': 1200,
      'location': '456 Heritage Street, Boston, MA',
      'bedrooms': 0,
      'bathrooms': 1,
      'area': 500,
      'propertyType': 'Studio',
      'available': true,
      'featured': false,
      'coordinates': {'latitude': 42.3601, 'longitude': -71.0589},
      'amenities': ['Laundry', 'Heating', 'Air Conditioning', 'Internet'],
    },
    {
      'title': 'Family-Friendly Suburban House',
      'description': 'Spacious family home in a quiet suburban neighborhood. This 4-bedroom, 3-bathroom house features a large living room, a modern kitchen with an island, a dining area, a finished basement, and a fenced backyard with a patio. Close to schools, parks, and shopping centers.',
      'price': 3200,
      'location': '789 Maple Drive, Chicago, IL',
      'bedrooms': 4,
      'bathrooms': 3,
      'area': 2400,
      'propertyType': 'House',
      'available': true,
      'featured': true,
      'coordinates': {'latitude': 41.8781, 'longitude': -87.6298},
      'amenities': ['Garage', 'Garden', 'Fireplace', 'Basement', 'Dishwasher', 'Washer/Dryer'],
    },
    {
      'title': 'Waterfront Luxury Condo',
      'description': 'Elegant waterfront condo with breathtaking views. This premium 3-bedroom, 2.5-bathroom unit features floor-to-ceiling windows, a gourmet kitchen with marble countertops, hardwood floors, and a spacious balcony overlooking the water. Building amenities include a fitness center, swimming pool, concierge service, and secure parking.',
      'price': 4500,
      'location': '101 Harbor View, Miami, FL',
      'bedrooms': 3,
      'bathrooms': 2.5,
      'area': 1800,
      'propertyType': 'Condo',
      'available': true,
      'featured': true,
      'coordinates': {'latitude': 25.7617, 'longitude': -80.1918},
      'amenities': ['Gym', 'Pool', 'Elevator', 'Security', 'Balcony', 'Waterfront'],
    },
    {
      'title': 'Trendy Loft in Arts District',
      'description': 'Stylish loft in the vibrant Arts District. This unique 1-bedroom, 1-bathroom space features high ceilings, exposed brick walls, large windows, an open floor plan, and modern fixtures. Located near galleries, restaurants, and nightlife. Perfect for creative professionals.',
      'price': 1900,
      'location': '222 Artist Way, Los Angeles, CA',
      'bedrooms': 1,
      'bathrooms': 1,
      'area': 900,
      'propertyType': 'Loft',
      'available': true,
      'featured': false,
      'coordinates': {'latitude': 34.0522, 'longitude': -118.2437},
      'amenities': ['Laundry', 'Internet', 'Air Conditioning', 'High Ceilings'],
    },
    {
      'title': 'Mountain View Cabin',
      'description': 'Cozy cabin with stunning mountain views. This 2-bedroom, 1-bathroom retreat features a rustic interior with modern amenities, a wood-burning fireplace, a fully equipped kitchen, and a spacious deck. Perfect for weekend getaways or as a vacation rental. Surrounded by nature with hiking trails nearby.',
      'price': 1800,
      'location': '333 Pine Ridge, Denver, CO',
      'bedrooms': 2,
      'bathrooms': 1,
      'area': 1000,
      'propertyType': 'Cabin',
      'available': true,
      'featured': false,
      'coordinates': {'latitude': 39.7392, 'longitude': -104.9903},
      'amenities': ['Fireplace', 'Deck', 'Parking', 'Mountain View', 'Heating'],
    },
    {
      'title': 'Contemporary Townhouse Near University',
      'description': 'Modern townhouse conveniently located near the university. This 3-bedroom, 2.5-bathroom home features an open floor plan, a sleek kitchen with stainless steel appliances, a private backyard, and a two-car garage. Perfect for faculty members or families with students. Close to campus, shopping, and dining.',
      'price': 2800,
      'location': '444 College Blvd, Austin, TX',
      'bedrooms': 3,
      'bathrooms': 2.5,
      'area': 1600,
      'propertyType': 'Townhouse',
      'available': true,
      'featured': true,
      'coordinates': {'latitude': 30.2672, 'longitude': -97.7431},
      'amenities': ['Garage', 'Garden', 'Dishwasher', 'Washer/Dryer', 'Air Conditioning'],
    },
    {
      'title': 'Upscale Penthouse with Rooftop Terrace',
      'description': 'Luxurious penthouse apartment with a private rooftop terrace. This exclusive 3-bedroom, 3-bathroom unit features premium finishes, an open-concept living space, a chef\'s kitchen with top-of-the-line appliances, floor-to-ceiling windows, and panoramic city views. Building amenities include concierge service, a fitness center, and secure parking.',
      'price': 5500,
      'location': '555 Skyline Drive, San Francisco, CA',
      'bedrooms': 3,
      'bathrooms': 3,
      'area': 2200,
      'propertyType': 'Penthouse',
      'available': true,
      'featured': true,
      'coordinates': {'latitude': 37.7749, 'longitude': -122.4194},
      'amenities': ['Rooftop Terrace', 'Elevator', 'Security', 'Gym', 'Parking', 'City View'],
    },
  ];

  /// Generate demo data and add it to Firestore
  Future<void> generateDemoData() async {
    try {
      await _generateListings();
      
      return;
    } catch (e) {
      debugPrint('Error generating demo data: $e');
      rethrow;
    }
  }
  
  /// Generate property listings
  Future<void> _generateListings() async {
    final batch = _firestore.batch();
    final currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      throw Exception('No user is currently logged in');
    }
    
    // Get current user data
    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    if (!userDoc.exists) {
      throw Exception('User data not found');
    }
    
    final userData = userDoc.data() as Map<String, dynamic>;
    final ownerName = userData['name'] as String;
    final ownerPhone = userData['phoneNumber'] as String;
    
    // Create listings
    for (int i = 0; i < _listingsData.length; i++) {
      final listingData = _listingsData[i];
      
      // Add main image
      final mainImageIndex = i % _propertyImages.length;
      
      // Add additional images (3-5 interior images)
      final List<String> additionalImages = [];
      final int numAdditionalImages = 3 + (i % 3); // 3-5 images
      
      for (int j = 0; j < numAdditionalImages; j++) {
        final interiorImageIndex = (i + j) % _interiorImages.length;
        additionalImages.add(_interiorImages[interiorImageIndex]);
      }
      
      // Create the listing document
      final listingDoc = _firestore.collection('listings').doc();
      
      // Create mock GeoPoint location from coordinates
      final geoPoint = GeoPoint(
        listingData['coordinates']['latitude'],
        listingData['coordinates']['longitude']
      );
      
      // Create image URLs list
      final List<String> imageUrls = [
        _propertyImages[mainImageIndex],
        ...additionalImages
      ];
      
      // Convert property type to category
      final String category = listingData['propertyType'];
      
      final listing = ListingModel(
        id: listingDoc.id,
        ownerId: currentUser.uid,
        ownerName: ownerName,
        ownerPhoneNumber: ownerPhone,
        title: listingData['title'],
        description: listingData['description'],
        price: listingData['price'].toDouble(),
        location: geoPoint,
        address: listingData['location'],
        category: category,
        imageUrls: imageUrls,
        amenities: List<String>.from(listingData['amenities']),
        isAvailable: listingData['available'],
        createdAt: DateTime.now(),
      );
      
      batch.set(listingDoc, listing.toMap());
    }
    
    // Commit batch
    await batch.commit();
  }
}
