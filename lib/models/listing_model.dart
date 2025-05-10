import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String ownerId;
  final String ownerName;
  final String ownerPhoneNumber;
  final List<String> imageUrls;
  final GeoPoint location;
  final String address;
  final String category;
  final DateTime createdAt;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final bool isAvailable;
  final List<String> amenities;
  
  ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhoneNumber,
    required this.imageUrls,
    required this.location,
    required this.address,
    required this.category,
    required this.createdAt,
    this.availableFrom,
    this.availableTo,
    required this.isAvailable,
    required this.amenities,
  });

  // Create from Map (Firebase)
  factory ListingModel.fromMap(Map<String, dynamic> map, String id) {
    return ListingModel(
      id: id,
      title: map['title'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      ownerId: map['ownerId'] as String,
      ownerName: map['ownerName'] as String,
      ownerPhoneNumber: map['ownerPhoneNumber'] as String,
      imageUrls: List<String>.from(map['imageUrls'] as List),
      location: map['location'] as GeoPoint,
      address: map['address'] as String,
      category: map['category'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      availableFrom: map['availableFrom'] != null
          ? (map['availableFrom'] as Timestamp).toDate()
          : null,
      availableTo: map['availableTo'] != null
          ? (map['availableTo'] as Timestamp).toDate()
          : null,
      isAvailable: map['isAvailable'] as bool,
      amenities: List<String>.from(map['amenities'] as List),
    );
  }

  // Convert to Map (Firebase)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhoneNumber': ownerPhoneNumber,
      'imageUrls': imageUrls,
      'location': location,
      'address': address,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'availableFrom':
          availableFrom != null ? Timestamp.fromDate(availableFrom!) : null,
      'availableTo':
          availableTo != null ? Timestamp.fromDate(availableTo!) : null,
      'isAvailable': isAvailable,
      'amenities': amenities,
    };
  }

  // Copy with method for updates
  ListingModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? ownerId,
    String? ownerName,
    String? ownerPhoneNumber,
    List<String>? imageUrls,
    GeoPoint? location,
    String? address,
    String? category,
    DateTime? createdAt,
    DateTime? availableFrom,
    DateTime? availableTo,
    bool? isAvailable,
    List<String>? amenities,
  }) {
    return ListingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhoneNumber: ownerPhoneNumber ?? this.ownerPhoneNumber,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      address: address ?? this.address,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      isAvailable: isAvailable ?? this.isAvailable,
      amenities: amenities ?? this.amenities,
    );
  }
}
