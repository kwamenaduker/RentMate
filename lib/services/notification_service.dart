import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  // Flag to enable demo mode for testing without Firebase
  final bool _demoMode = false; // Match with other services
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Mock data for demo mode
  final List<NotificationModel> _mockNotifications = [];
  
  // Constructor to initialize demo data
  NotificationService() {
    if (_demoMode) {
      _initializeDemoData();
    }
    
    // Listen for auth state changes to refresh demo data
    _auth.authStateChanges().listen((User? user) {
      if (_demoMode && user != null) {
        print('User authenticated, refreshing notification data for: ${user.uid}');
        _initializeDemoData(); // Refresh demo data with new user ID
        notifyListeners();
      }
    });
  }
  
  // Initialize demo data for testing
  void _initializeDemoData() {
    print('Initializing demo notifications data');
    // Clear previous data
    _mockNotifications.clear();
    
    // Get real user ID if available, otherwise use demo ID
    String? realUserId = _auth.currentUser?.uid;
    final currentUserId = realUserId ?? 'demo-user-id';
    
    // Create various notification types for demo mode
    _mockNotifications.addAll([
      NotificationModel(
        id: 'notification-1',
        userId: currentUserId,
        title: 'New Message',
        message: 'John Smith sent you a message about Cozy 2BR Apartment',
        targetType: 'message',
        targetId: 'conversation-1',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      NotificationModel(
        id: 'notification-2',
        userId: currentUserId,
        title: 'Listing Updated',
        message: 'Modern Studio Downtown price has been reduced',
        targetType: 'listing',
        targetId: 'listing-2',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
      ),
      NotificationModel(
        id: 'notification-3',
        userId: currentUserId,
        title: 'Favorite Listing Rented',
        message: 'A listing in your favorites is no longer available',
        targetType: 'listing',
        targetId: 'listing-3',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      ),
      NotificationModel(
        id: 'notification-4',
        userId: currentUserId,
        title: 'Welcome to RentMate!',
        message: 'Thanks for joining. Start exploring rentals near you.',
        targetType: 'system',
        targetId: null,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        isRead: true,
      ),
    ]);
    
    print('Demo notifications initialized with ${_mockNotifications.length} notifications');
  }
  
  // Access demo mode status
  bool get isDemoMode => _demoMode;
  
  // Get current user ID
  String? get currentUserId {
    if (_demoMode) {
      return 'demo-user-id';
    }
    return _auth.currentUser?.uid;
  }
  
  // Get all notifications for the current user
  Stream<List<NotificationModel>> getNotifications() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }
    
    if (_demoMode) {
      // Filter mock notifications for the current user
      final userNotifications = _mockNotifications
          .where((notification) => notification.userId == userId)
          .toList();
      
      // Sort by date (newest first)
      userNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return Stream.value(userNotifications);
    }
    
    // Try to use the indexed query first
    try {
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
                .toList();
          })
          .handleError((error) {
            // If there's an index error, fall back to a simpler query
            if (error.toString().contains('requires an index')) {
              print('Firestore index error detected: $error');
              print('Falling back to non-ordered query');
              return _getFallbackNotifications(userId);
            }
            throw error; // rethrow any other errors
          });
    } catch (e) {
      print('Error in notifications query: $e');
      return _getFallbackNotifications(userId);
    }
  }
  
  // Fallback method to get notifications without ordering
  Stream<List<NotificationModel>> _getFallbackNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();
          
          // Sort in memory instead of in the query
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }
  
  // Get count of unread notifications
  Stream<int> getUnreadCount() {
    return getNotifications().map(
      (notifications) => notifications
          .where((notification) => !notification.isRead)
          .length,
    );
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    if (_demoMode) {
      final index = _mockNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _mockNotifications[index] = _mockNotifications[index].copyWith(isRead: true);
        notifyListeners();
      }
      return;
    }
    
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    if (_demoMode) {
      for (int i = 0; i < _mockNotifications.length; i++) {
        if (_mockNotifications[i].userId == userId) {
          _mockNotifications[i] = _mockNotifications[i].copyWith(isRead: true);
        }
      }
      notifyListeners();
      return;
    }
    
    try {
      // Get all unread notifications for the user
      QuerySnapshot unreadSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      // Create a batch to update all documents
      WriteBatch batch = _firestore.batch();
      for (var doc in unreadSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }
  
  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String? imageUrl,
    String? targetId,
    required String targetType,
  }) async {
    if (_demoMode) {
      final notification = NotificationModel(
        id: 'notification-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: title,
        message: message,
        imageUrl: imageUrl,
        targetId: targetId,
        targetType: targetType,
        createdAt: DateTime.now(),
        isRead: false,
      );
      
      _mockNotifications.add(notification);
      notifyListeners();
      return;
    }
    
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'imageUrl': imageUrl,
        'targetId': targetId,
        'targetType': targetType,
        'createdAt': Timestamp.now(),
        'isRead': false,
      });
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }
  
  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    if (_demoMode) {
      _mockNotifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      return;
    }
    
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }
  
  // Delete all notifications for the current user
  Future<void> deleteAllNotifications() async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    if (_demoMode) {
      _mockNotifications.removeWhere((n) => n.userId == userId);
      notifyListeners();
      return;
    }
    
    try {
      // Get all notifications for the user
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      
      // Create a batch to delete all documents
      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
      rethrow;
    }
  }

  // Generate appropriate event-based notifications
  Future<void> notifyListingStatus(String listingId, String title, String ownerId, bool isAvailable) async {
    if (currentUserId == null) return;
    
    try {
      // Get users who have favorited this listing
      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('favoriteListings', arrayContains: listingId)
          .get();
      
      // Create notifications for each relevant user
      for (var userDoc in userSnapshot.docs) {
        final userId = userDoc.id;
        if (userId != ownerId) { // Don't notify the owner
          await createNotification(
            userId: userId,
            title: 'Listing Update',
            message: '$title is now ${isAvailable ? 'available' : 'unavailable'}',
            targetId: listingId,
            targetType: 'listing',
          );
        }
      }
    } catch (e) {
      print('Error creating listing status notifications: $e');
    }
  }
  
  Future<void> notifyNewMessage(String conversationId, String senderId, String receiverId, String senderName) async {
    if (senderId == receiverId) return; // Don't notify self
    
    try {
      await createNotification(
        userId: receiverId,
        title: 'New Message',
        message: '$senderName sent you a message',
        targetId: conversationId,
        targetType: 'message',
      );
    } catch (e) {
      print('Error creating message notification: $e');
    }
  }
}
