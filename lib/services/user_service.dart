import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rent_mate/models/user_model.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Flag to enable demo mode for testing without Firebase
  final bool _demoMode = false; // Match with other services
  
  // Get the currently logged-in user ID or null if not logged in
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Mock user cache for demo mode
  final Map<String, UserModel> _mockUsers = {};
  
  // Constructor to initialize demo data
  UserService() {
    if (_demoMode) {
      _initializeDemoData();
    }
  }
  
  // Initialize demo data
  void _initializeDemoData() {
    _mockUsers.clear();
    
    // Default demo owner
    _mockUsers['demo-owner-1'] = UserModel(
      id: 'demo-owner-1',
      email: 'owner@example.com',
      name: 'John Owner',
      phoneNumber: '555-123-4567',
      createdAt: DateTime.now(),
      favoriteListings: [],
    );
    
    // Default demo renter
    _mockUsers['demo-user-id'] = UserModel(
      id: 'demo-user-id',
      email: 'user@example.com',
      name: 'Jane Renter',
      phoneNumber: '555-987-6543',
      createdAt: DateTime.now(),
      favoriteListings: [],
    );
    
    // Current user if available
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _mockUsers[currentUser.uid] = UserModel(
        id: currentUser.uid,
        email: currentUser.email ?? 'user@example.com',
        name: currentUser.displayName ?? 'Current User',
        phoneNumber: '555-000-0000',
        createdAt: DateTime.now(),
        favoriteListings: [],
      );
    }
  }
  
  // Get a user by ID
  Future<UserModel?> getUserById(String userId) async {
    if (_demoMode) {
      // Return from mock data if available, or create a new mock user
      if (_mockUsers.containsKey(userId)) {
        return _mockUsers[userId];
      }
      
      // Create a new mock user if not found
      final newUser = UserModel(
        id: userId,
        email: 'user_$userId@example.com',
        name: 'User $userId',
        phoneNumber: '555-${userId.hashCode.toString().substring(0, 3)}-${userId.hashCode.toString().substring(3, 7)}',
        createdAt: DateTime.now(),
        favoriteListings: [],
      );
      
      _mockUsers[userId] = newUser;
      return newUser;
    }
    
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      
      if (docSnapshot.exists) {
        final userData = docSnapshot.data()!;
        // Add id to the map before creating UserModel
        userData['id'] = docSnapshot.id;
        return UserModel.fromMap(userData);
      } else {
        if (kDebugMode) {
          print('User with ID $userId not found');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user: $e');
      }
      return null;
    }
  }
  
  // Get current user
  Future<UserModel?> getCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    return getUserById(userId);
  }
  
  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    if (_demoMode) {
      if (_mockUsers.containsKey(userId)) {
        final currentUser = _mockUsers[userId]!;
        _mockUsers[userId] = UserModel(
          id: userId,
          email: currentUser.email,
          name: name ?? currentUser.name,
          phoneNumber: phoneNumber ?? currentUser.phoneNumber,
          profileImageUrl: profileImageUrl ?? currentUser.profileImageUrl,
          createdAt: currentUser.createdAt,
          favoriteListings: currentUser.favoriteListings,
        );
      }
      return;
    }
    
    try {
      final updateData = <String, dynamic>{};
      
      if (name != null) {
        updateData['name'] = name;
      }
      
      if (phoneNumber != null) {
        updateData['phoneNumber'] = phoneNumber;
      }
      
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }
      
      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updateData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      rethrow;
    }
  }
}
