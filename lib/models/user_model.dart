import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final List<String> favoriteListings;
  final String? address;
  
  // Getter for displayName to match usage in code
  String get displayName => name;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    required this.favoriteListings,
    this.address,
  });

  // Create from Map (Firebase)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phoneNumber: map['phoneNumber'] as String,
      profileImageUrl: map['profileImageUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      favoriteListings: List<String>.from(map['favoriteListings'] as List),
      address: map['address'] as String?,
    );
  }

  // Convert to Map (Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'favoriteListings': favoriteListings,
      'address': address,
    };
  }

  // Copy with method for updates
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    List<String>? favoriteListings,
    String? address,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      favoriteListings: favoriteListings ?? this.favoriteListings,
      address: address ?? this.address,
    );
  }
}
