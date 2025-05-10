import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum BookingStatus {
  pending,
  confirmed,
  canceled,
  completed
}

class BookingModel {
  final String id;
  final String listingId;
  final String renterUserId;
  final String ownerUserId;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime bookedAt;
  final double totalPrice;
  final BookingStatus status;
  final String? notes;
  final String? listingTitle;
  final String? listingImageUrl;

  BookingModel({
    required this.id,
    required this.listingId,
    required this.renterUserId,
    required this.ownerUserId,
    required this.startDate,
    required this.endDate,
    required this.bookedAt,
    required this.totalPrice,
    required this.status,
    this.notes,
    this.listingTitle,
    this.listingImageUrl,
  });

  // Factory constructor to create a BookingModel from a Map (for Firestore)
  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      listingId: map['listingId'] as String,
      renterUserId: map['renterUserId'] as String,
      ownerUserId: map['ownerUserId'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      bookedAt: (map['bookedAt'] as Timestamp).toDate(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.${map['status']}',
        orElse: () => BookingStatus.pending,
      ),
      notes: map['notes'] as String?,
      listingTitle: map['listingTitle'] as String?,
      listingImageUrl: map['listingImageUrl'] as String?,
    );
  }

  // Convert BookingModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'renterUserId': renterUserId,
      'ownerUserId': ownerUserId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'bookedAt': Timestamp.fromDate(bookedAt),
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'notes': notes,
      'listingTitle': listingTitle,
      'listingImageUrl': listingImageUrl,
    };
  }

  // Create a copy of the booking with updated fields
  BookingModel copyWith({
    String? id,
    String? listingId,
    String? renterUserId,
    String? ownerUserId,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? bookedAt,
    double? totalPrice,
    BookingStatus? status,
    String? notes,
    String? listingTitle,
    String? listingImageUrl,
  }) {
    return BookingModel(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      renterUserId: renterUserId ?? this.renterUserId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      bookedAt: bookedAt ?? this.bookedAt,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      listingTitle: listingTitle ?? this.listingTitle,
      listingImageUrl: listingImageUrl ?? this.listingImageUrl,
    );
  }

  // Helper method to get the booking duration in days
  int get durationInDays {
    return endDate.difference(startDate).inDays + 1; // +1 to include the end date
  }

  // Helper method to check if a booking is active (confirmed and current)
  bool get isActive {
    final now = DateTime.now();
    return status == BookingStatus.confirmed &&
        now.isAfter(startDate) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  // Helper method to check if a booking is upcoming (confirmed but not started yet)
  bool get isUpcoming {
    final now = DateTime.now();
    return status == BookingStatus.confirmed && now.isBefore(startDate);
  }

  // Helper method to get a human-readable status
  String get statusText {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.canceled:
        return 'Canceled';
      case BookingStatus.completed:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  // Helper method to get a color for the status
  static getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFFFFA000); // Amber
      case BookingStatus.confirmed:
        return const Color(0xFF4CAF50); // Green
      case BookingStatus.canceled:
        return const Color(0xFFF44336); // Red
      case BookingStatus.completed:
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}
