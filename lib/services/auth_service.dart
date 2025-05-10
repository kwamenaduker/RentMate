import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../utils/validators.dart';
import 'dart:async';

class AuthService extends ChangeNotifier {
  // Flag to enable demo mode for testing without Firebase
  // Set to false to use real Firebase integration
  final bool _demoMode = false;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Mock data for demo mode (kept for fallback testing)
  bool _isLoggedIn = false;
  String? _mockUserId;
  UserModel? _mockUserModel;
  
  // Track failed login attempts
  static int _failedLoginAttempts = 0;
  static DateTime? _lastFailedLogin;

  // Auth state changes stream
  Stream<User?> get authStateChanges {
    if (_demoMode) {
      // For demo mode, just return null (not authenticated)
      // The app will check _isLoggedIn separately
      return Stream.value(null);
    }
    return _auth.authStateChanges();
  }

  // Get current user
  User? get currentUser {
    if (_demoMode) {
      // For demo mode, return null but handle login state separately
      return null;
    }
    return _auth.currentUser;
  }
  
  // Check if user is logged in (for demo mode)
  bool get isLoggedIn => _demoMode ? _isLoggedIn : currentUser != null;

  // Register with email and password with enhanced security
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      // Validate inputs first
      final emailError = Validators.validateEmail(email);
      if (emailError != null) throw Exception(emailError);
      
      final passwordError = Validators.validatePassword(password);
      if (passwordError != null) throw Exception(passwordError);
      
      final nameError = Validators.validateName(name);
      if (nameError != null) throw Exception(nameError);
      
      final phoneError = Validators.validatePhone(phoneNumber);
      if (phoneError != null) throw Exception(phoneError);
      
      // Sanitize inputs
      final sanitizedName = Validators.sanitizeInput(name);
      final sanitizedEmail = email.trim().toLowerCase();
      final sanitizedPhone = phoneNumber.trim();
      
      if (_demoMode) {
        // Create mock user data for testing
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        
        _mockUserId = 'demo-user-${DateTime.now().millisecondsSinceEpoch}';
        _mockUserModel = UserModel(
          id: _mockUserId!,
          name: sanitizedName,
          email: sanitizedEmail,
          phoneNumber: sanitizedPhone,
          createdAt: DateTime.now(),
          favoriteListings: [],
        );
        
        _isLoggedIn = true;
        
        // Return null for demo mode, but mark as logged in
        return null;
      }
      
      // Regular Firebase authentication with enhanced security
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: sanitizedEmail,
        password: password, // Don't sanitize password as it might alter security requirements
      );

      // Send email verification
      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
        
        // Create user model in Firestore
        await _createUserInFirestore(
          userCredential.user!.uid,
          sanitizedName,
          sanitizedEmail,
          sanitizedPhone,
        );
      }

      return userCredential;
    } catch (e) {
      // Enhanced error handling
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception('The email address is already in use by another account.');
          case 'invalid-email':
            throw Exception('The email address is not valid.');
          case 'operation-not-allowed':
            throw Exception('Email/password accounts are not enabled.');
          case 'weak-password':
            throw Exception('The password is too weak. Please use a stronger password.');
          default:
            throw Exception('Registration failed: ${e.message}');
        }
      } else {
        throw Exception('Registration failed: $e');
      }
    }
  }

  // Sign in with email and password with enhanced security
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      final emailError = Validators.validateEmail(email);
      if (emailError != null) throw Exception(emailError);
      
      // Sanitize email
      final sanitizedEmail = email.trim().toLowerCase();
      
      // Check for too many failed attempts
      if (_failedLoginAttempts >= 5) {
        // Check if enough time has passed since last failed attempt
        if (_lastFailedLogin != null) {
          final timeSinceLastAttempt = DateTime.now().difference(_lastFailedLogin!);
          if (timeSinceLastAttempt.inMinutes < 15) {
            throw Exception('Too many failed login attempts. Please try again later or reset your password.');
          } else {
            // Reset counter after 15 minutes
            _failedLoginAttempts = 0;
          }
        }
      }
      
      if (_demoMode) {
        // Create mock user model for testing if not already existing
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        
        _mockUserId = 'demo-user-${DateTime.now().millisecondsSinceEpoch}';
        _mockUserModel = UserModel(
          id: _mockUserId!,
          name: 'Demo User',
          email: sanitizedEmail,
          phoneNumber: '+1234567890',
          createdAt: DateTime.now(),
          favoriteListings: [],
        );
        
        _isLoggedIn = true;
        
        // Return null for demo mode, but mark as logged in
        return null;
      }
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: sanitizedEmail,
        password: password,
      );
      
      // Check if email is verified
      if (credential.user != null && !credential.user!.emailVerified) {
        // Allow login but notify about verification
        notifyListeners();
      }
      
      // Reset failed attempts counter on successful login
      _failedLoginAttempts = 0;
      
      return credential;
    } catch (e) {
      // Increment failed attempts counter
      _failedLoginAttempts++;
      _lastFailedLogin = DateTime.now();
      
      // Enhanced error handling
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw Exception('No user found with this email address.');
          case 'wrong-password':
            throw Exception('Incorrect password. Please try again.');
          case 'user-disabled':
            throw Exception('This account has been disabled. Please contact support.');
          case 'too-many-requests':
            throw Exception('Too many failed login attempts. Please try again later or reset your password.');
          case 'invalid-credential':
            throw Exception('The credentials provided are invalid. Please check your email and password.');
          default:
            throw Exception('Login failed: ${e.message}');
        }
      } else {
        throw Exception('Login failed: $e');
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      _isLoggedIn = false;
      _mockUserId = null;
      _mockUserModel = null;
      return;
    }
    
    await _auth.signOut();
  }

  // Create user in Firestore with enhanced security
  Future<void> _createUserInFirestore(
    String uid,
    String name,
    String email,
    String phoneNumber,
  ) async {
    final UserModel newUser = UserModel(
      id: uid,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      createdAt: DateTime.now(),
      favoriteListings: [],
    );
    
    // Set custom claims for role-based access control (in a full implementation)
    // This would typically be done in a secure Cloud Function
    
    await _firestore.collection('users').doc(uid).set(newUser.toMap());
  }

  // Get current user data (helper method for demo mode)
  Future<UserModel?> getCurrentUserData() async {
    if (_demoMode) {
      return _mockUserModel;
    }
    
    if (_auth.currentUser == null) {
      return null;
    }
    
    return getUserData(_auth.currentUser!.uid);
  }
  
  // Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      if (_demoMode && _mockUserModel != null) {
        return _mockUserModel;
      }
      
      final DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }
  
  // Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      if (_demoMode) {
        return true; // Demo mode always returns verified
      }
      
      final user = _auth.currentUser;
      if (user != null) {
        // Force refresh token to get the latest verification status
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }
  
  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      if (_demoMode) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        return;
      }
      
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      } else if (user == null) {
        throw Exception('No user is currently signed in.');
      }
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      throw Exception('Failed to send verification email: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    String? address,
  }) async {
    try {
      if (_demoMode) {
        // Update mock user data
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
        
        if (_mockUserModel != null) {
          _mockUserModel = _mockUserModel!.copyWith(
            name: name ?? _mockUserModel!.name,
            phoneNumber: phoneNumber ?? _mockUserModel!.phoneNumber,
            profileImageUrl: profileImageUrl ?? _mockUserModel!.profileImageUrl,
            address: address ?? _mockUserModel!.address,
          );
        }
        
        return;
      }
      
      final Map<String, dynamic> updateData = {};
      
      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
      if (address != null) updateData['address'] = address;
      
      await _firestore.collection('users').doc(uid).update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  // Reset password with enhanced security
  Future<void> resetPassword(String email) async {
    try {
      // Validate email
      final emailError = Validators.validateEmail(email);
      if (emailError != null) throw Exception(emailError);
      
      // Sanitize email
      final sanitizedEmail = email.trim().toLowerCase();
      
      if (_demoMode) {
        // Simulate password reset
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        return;
      }
      
      await _auth.sendPasswordResetEmail(email: sanitizedEmail);
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            // For security reasons, don't reveal if the email exists or not
            // Just return without error to prevent user enumeration attacks
            return;
          default:
            throw Exception('Password reset failed: ${e.message}');
        }
      } else {
        throw Exception('Password reset failed: $e');
      }
    }
  }
  
  // Toggle favorite listing
  Future<void> toggleFavorite(String userId, String listingId) async {
    try {
      if (_demoMode) {
        // Update mock user data for favorites
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
        
        if (_mockUserModel != null) {
          List<String> updatedFavorites = List.from(_mockUserModel!.favoriteListings);
          
          if (updatedFavorites.contains(listingId)) {
            updatedFavorites.remove(listingId);
          } else {
            updatedFavorites.add(listingId);
          }
          
          _mockUserModel = _mockUserModel!.copyWith(
            favoriteListings: updatedFavorites,
          );
        }
        
        return;
      }
      
      // Get current user data
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        List<String> favorites = List<String>.from(userData['favoriteListings'] ?? []);
        
        // Toggle favorite
        if (favorites.contains(listingId)) {
          favorites.remove(listingId);
        } else {
          favorites.add(listingId);
        }
        
        // Update user data
        await _firestore.collection('users').doc(userId).update({
          'favoriteListings': favorites,
        });
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Check if a listing is favorited by the current user
  Future<bool> isListingFavorited(String listingId) async {
    try {
      if (_demoMode) {
        await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
        return _mockUserModel?.favoriteListings.contains(listingId) ?? false;
      }
      
      if (_auth.currentUser == null) return false;
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      
      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        List<String> favorites = List<String>.from(userData['favoriteListings'] ?? []);
        return favorites.contains(listingId);
      }
      
      return false;
    } catch (e) {
      print('Error checking if listing is favorited: $e');
      return false;
    }
  }
  
  // Get favorited listings for the current user
  Future<List<String>> getFavoritedListings() async {
    try {
      if (_demoMode) {
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
        return _mockUserModel?.favoriteListings ?? [];
      }
      
      if (_auth.currentUser == null) return [];
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      
      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        return List<String>.from(userData['favoriteListings'] ?? []);
      }
      
      return [];
    } catch (e) {
      print('Error getting favorited listings: $e');
      return [];
    }
  }
}
