import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String? imageUrl;
  final String? targetId;
  final String targetType; // 'listing', 'message', 'user', 'system'
  final DateTime createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.imageUrl,
    this.targetId,
    required this.targetType,
    required this.createdAt,
    this.isRead = false,
  });

  // Create from Firestore document
  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      imageUrl: data['imageUrl'],
      targetId: data['targetId'],
      targetType: data['targetType'] ?? 'system',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'targetId': targetId,
      'targetType': targetType,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  // Create a copy with modified fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? imageUrl,
    String? targetId,
    String? targetType,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  // Get icon based on notification type
  static iconForType(String type) {
    switch (type) {
      case 'listing':
        return 'home';
      case 'message':
        return 'message';
      case 'user':
        return 'person';
      case 'system':
      default:
        return 'notifications';
    }
  }
}
