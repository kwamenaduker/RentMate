import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rent_mate/models/booking_model.dart';
import 'package:rent_mate/models/listing_model.dart';
import 'package:rent_mate/services/notification_service.dart';

class BookingService extends ChangeNotifier {
  // Flag to enable demo mode for testing without Firebase
  final bool _demoMode = false; // Match with other services
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Mock data for demo mode
  final List<BookingModel> _mockBookings = [];
  
  // Constructor to initialize demo data
  BookingService() {
    if (_demoMode) {
      _initializeDemoData();
    }
  }
  
  // Get the currently logged-in user ID or null if not logged in
  String? get currentUserId => _auth.currentUser?.uid;
  
  bool get isDemoMode => _demoMode;
  
  // Initialize demo data for testing
  void _initializeDemoData() {
    // Clear any existing mock data
    _mockBookings.clear();
    
    // Get real user ID if available, otherwise use demo ID
    String? userId = _auth.currentUser?.uid;
    final currentUserId = userId ?? 'demo-user-id';
    
    // Add some sample bookings
    _mockBookings.addAll([
      BookingModel(
        id: 'booking-1',
        listingId: 'listing-1',
        renterUserId: currentUserId,
        ownerUserId: 'demo-owner-1',
        startDate: DateTime.now().add(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 10)),
        bookedAt: DateTime.now().subtract(const Duration(days: 2)),
        totalPrice: 500.0,
        status: BookingStatus.confirmed,
        listingTitle: 'Modern Studio Apartment',
        listingImageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
        notes: 'Please have the keys ready for me at 2 PM.',
      ),
      BookingModel(
        id: 'booking-2',
        listingId: 'listing-2',
        renterUserId: currentUserId,
        ownerUserId: 'demo-owner-2',
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().subtract(const Duration(days: 10)),
        bookedAt: DateTime.now().subtract(const Duration(days: 20)),
        totalPrice: 750.0,
        status: BookingStatus.completed,
        listingTitle: 'Luxury Beach House',
        listingImageUrl: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6',
      ),
      BookingModel(
        id: 'booking-3',
        listingId: 'listing-3',
        renterUserId: 'demo-user-2',
        ownerUserId: currentUserId,
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 8)),
        bookedAt: DateTime.now().subtract(const Duration(days: 3)),
        totalPrice: 600.0,
        status: BookingStatus.pending,
        listingTitle: 'Cozy 2BR Apartment',
        listingImageUrl: 'https://images.unsplash.com/photo-1522156373667-4c7234bbd804',
        notes: 'I will arrive around 4 PM.',
      ),
    ]);
    
    if (kDebugMode) {
      print('Demo booking data initialized with ${_mockBookings.length} bookings');
    }
  }
  
  // Create a new booking
  Future<String> createBooking({
    required String listingId,
    required String ownerUserId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
    String? notes,
    String? listingTitle,
    String? listingImageUrl,
    NotificationService? notificationService,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    if (_demoMode) {
      // Create a booking in demo mode
      final booking = BookingModel(
        id: 'booking-${DateTime.now().millisecondsSinceEpoch}',
        listingId: listingId,
        renterUserId: userId,
        ownerUserId: ownerUserId,
        startDate: startDate,
        endDate: endDate,
        bookedAt: DateTime.now(),
        totalPrice: totalPrice,
        status: BookingStatus.pending,
        notes: notes,
        listingTitle: listingTitle,
        listingImageUrl: listingImageUrl,
      );
      
      _mockBookings.add(booking);
      
      // Create notification for the owner in demo mode
      if (notificationService != null) {
        await notificationService.createNotification(
          userId: ownerUserId,
          title: 'New Booking Request',
          message: 'You have a new booking request for "$listingTitle"',
          targetId: booking.id,
          targetType: 'booking',
        );
      }
      
      notifyListeners();
      return booking.id;
    }
    
    // Create a booking in Firebase
    try {
      final bookingData = {
        'listingId': listingId,
        'renterUserId': userId,
        'ownerUserId': ownerUserId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'bookedAt': Timestamp.fromDate(DateTime.now()),
        'totalPrice': totalPrice,
        'status': BookingStatus.pending.toString().split('.').last,
        'notes': notes,
        'listingTitle': listingTitle,
        'listingImageUrl': listingImageUrl,
      };
      
      final docRef = await _firestore.collection('bookings').add(bookingData);
      
      // Create notification for the owner
      if (notificationService != null) {
        await notificationService.createNotification(
          userId: ownerUserId,
          title: 'New Booking Request',
          message: 'You have a new booking request for "$listingTitle"',
          targetId: docRef.id,
          targetType: 'booking',
        );
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating booking: $e');
      }
      rethrow;
    }
  }
  
  // Get all bookings for a user (as renter)
  Stream<List<BookingModel>> getUserBookings() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }
    
    if (_demoMode) {
      // Filter bookings for the current user as a renter
      final userBookings = _mockBookings
          .where((booking) => booking.renterUserId == userId)
          .toList();
      
      // Sort by start date (upcoming first)
      userBookings.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      return Stream.value(userBookings);
    }
    
    try {
      // Try with ordering (requires index)
      return _firestore
          .collection('bookings')
          .where('renterUserId', isEqualTo: userId)
          .orderBy('startDate')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
                .toList();
          })
          .handleError((error) {
            // If index error occurs, fall back to unordered query
            if (error.toString().contains('index')) {
              if (kDebugMode) {
                print('Index error, falling back to unordered query: $error');
              }
              // Fallback without ordering
              return _firestore
                .collection('bookings')
                .where('renterUserId', isEqualTo: userId)
                .snapshots()
                .map((snapshot) {
                  final bookings = snapshot.docs
                      .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
                      .toList();
                  // Sort manually in code
                  bookings.sort((a, b) => a.startDate.compareTo(b.startDate));
                  return bookings;
                });
            } else {
              // Rethrow if it's another type of error
              throw error;
            }
          });
    } catch (e) {
      if (kDebugMode) {
        print('Error in getUserBookings: $e - Using fallback');
      }
      // Fallback without ordering if initial setup fails
      return _firestore
          .collection('bookings')
          .where('renterUserId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final bookings = snapshot.docs
                .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
                .toList();
            // Sort manually in code
            bookings.sort((a, b) => a.startDate.compareTo(b.startDate));
            return bookings;
          });
    }
  }
  
  // Get all bookings for a user (as owner)
  Stream<List<BookingModel>> getOwnerBookings() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }
    
    if (_demoMode) {
      // Filter bookings for the current user as an owner
      final ownerBookings = _mockBookings
          .where((booking) => booking.ownerUserId == userId)
          .toList();
      
      // Sort by status (pending first) then by start date
      ownerBookings.sort((a, b) {
        // Sort pending requests first
        if (a.status == BookingStatus.pending && b.status != BookingStatus.pending) {
          return -1;
        }
        if (a.status != BookingStatus.pending && b.status == BookingStatus.pending) {
          return 1;
        }
        // Then sort by start date
        return a.startDate.compareTo(b.startDate);
      });
      
      return Stream.value(ownerBookings);
    }
    
    try {
      return _firestore
          .collection('bookings')
          .where('ownerUserId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final bookings = snapshot.docs
                .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
                .toList();
            
            // Sort by status (pending first) then by start date
            bookings.sort((a, b) {
              // Sort pending requests first
              if (a.status == BookingStatus.pending && b.status != BookingStatus.pending) {
                return -1;
              }
              if (a.status != BookingStatus.pending && b.status == BookingStatus.pending) {
                return 1;
              }
              // Then sort by start date
              return a.startDate.compareTo(b.startDate);
            });
            
            return bookings;
          })
          .handleError((error) {
            if (kDebugMode) {
              print('Error in getOwnerBookings: $error');
            }
            // Return empty list in case of any errors to avoid crashes
            return <BookingModel>[];
          });
    } catch (e) {
      if (kDebugMode) {
        print('Exception in getOwnerBookings: $e');
      }
      // In case of exception, return empty stream
      return Stream.value([]);
    }
  }
  
  // Get a specific booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    if (_demoMode) {
      try {
        return _mockBookings.firstWhere((booking) => booking.id == bookingId);
      } catch (e) {
        return null;
      }
    }
    
    try {
      final docSnapshot = await _firestore.collection('bookings').doc(bookingId).get();
      
      if (docSnapshot.exists) {
        return BookingModel.fromMap(docSnapshot.data()!, docSnapshot.id);
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting booking: $e');
      }
      rethrow;
    }
  }
  
  // Get all bookings for a listing
  Future<List<BookingModel>> getListingBookings(String listingId) async {
    if (_demoMode) {
      return _mockBookings
          .where((booking) => booking.listingId == listingId)
          .toList();
    }
    
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('listingId', isEqualTo: listingId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting listing bookings: $e');
      }
      rethrow;
    }
  }
  
  // Update booking status
  Future<void> updateBookingStatus(
    String bookingId, 
    BookingStatus newStatus,
    {NotificationService? notificationService}
  ) async {
    if (_demoMode) {
      final index = _mockBookings.indexWhere((booking) => booking.id == bookingId);
      if (index != -1) {
        final oldBooking = _mockBookings[index];
        final updatedBooking = oldBooking.copyWith(status: newStatus);
        _mockBookings[index] = updatedBooking;
        
        // Create notification in demo mode
        if (notificationService != null) {
          String title = 'Booking Update';
          String message = 'Your booking for "${oldBooking.listingTitle}" has been ';
          
          switch (newStatus) {
            case BookingStatus.confirmed:
              message += 'confirmed';
              break;
            case BookingStatus.canceled:
              message += 'canceled';
              break;
            case BookingStatus.completed:
              message += 'marked as completed';
              break;
            default:
              message += 'updated';
          }
          
          await notificationService.createNotification(
            userId: oldBooking.renterUserId,
            title: title,
            message: message,
            targetId: bookingId,
            targetType: 'booking',
          );
        }
        
        notifyListeners();
        return;
      }
      throw Exception('Booking not found');
    }
    
    try {
      // Get the booking before updating
      final docSnapshot = await _firestore.collection('bookings').doc(bookingId).get();
      
      if (!docSnapshot.exists) {
        throw Exception('Booking not found');
      }
      
      final oldBooking = BookingModel.fromMap(docSnapshot.data()!, docSnapshot.id);
      
      // Update the booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus.toString().split('.').last,
      });
      
      // Create notification
      if (notificationService != null) {
        String title = 'Booking Update';
        String message = 'Your booking for "${oldBooking.listingTitle}" has been ';
        
        switch (newStatus) {
          case BookingStatus.confirmed:
            message += 'confirmed';
            break;
          case BookingStatus.canceled:
            message += 'canceled';
            break;
          case BookingStatus.completed:
            message += 'marked as completed';
            break;
          default:
            message += 'updated';
        }
        
        await notificationService.createNotification(
          userId: oldBooking.renterUserId,
          title: title,
          message: message,
          targetId: bookingId,
          targetType: 'booking',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating booking status: $e');
      }
      rethrow;
    }
  }
  
  // Cancel a booking (can be done by either the renter or owner)
  Future<void> cancelBooking(
    String bookingId, 
    {NotificationService? notificationService}
  ) async {
    return updateBookingStatus(
      bookingId, 
      BookingStatus.canceled,
      notificationService: notificationService
    );
  }
  
  // Check if a listing is available for the specified dates
  Future<bool> isListingAvailable(
    String listingId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    // First check if the listing itself is available
    try {
      final ListingModel? listing = await _getListing(listingId);
      if (listing == null || !listing.isAvailable) {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking listing availability: $e');
      }
      return false;
    }
    
    // Then check for any conflicting bookings
    final bookings = await getListingBookings(listingId);
    
    // Only confirmed bookings can block availability
    final confirmedBookings = bookings.where(
      (booking) => booking.status == BookingStatus.confirmed
    ).toList();
    
    // Check for overlap with any confirmed bookings
    for (final booking in confirmedBookings) {
      // Check if the requested dates overlap with this booking
      if (!(endDate.isBefore(booking.startDate) || 
            startDate.isAfter(booking.endDate))) {
        return false;  // There is an overlap
      }
    }
    
    return true;  // No conflicts found
  }
  
  // Helper method to get a listing
  Future<ListingModel?> _getListing(String listingId) async {
    if (_demoMode) {
      // Demo implementation would go here
      // For now, just return a mock listing that's available
      return ListingModel(
        id: listingId,
        ownerId: 'demo-owner-1',
        title: 'Mock Listing',
        description: 'A mock listing for testing',
        price: 100.0,
        imageUrls: [],
        category: 'Apartment',
        address: '123 Mock St, Demo City, DC',
        location: const GeoPoint(0, 0),
        amenities: [],
        isAvailable: true,
        availableFrom: null,
        availableTo: null,
        createdAt: DateTime.now(),
        ownerName: 'Demo Owner',
        ownerPhoneNumber: '1234567890',
      );
    }
    
    try {
      final docSnapshot = await _firestore.collection('listings').doc(listingId).get();
      
      if (docSnapshot.exists) {
        return ListingModel.fromMap(docSnapshot.data()!, docSnapshot.id);
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting listing: $e');
      }
      rethrow;
    }
  }
}
