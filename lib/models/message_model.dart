import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? attachment;
  final String? attachmentType;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.attachment,
    this.attachmentType,
  });

  // Create from Firestore document
  factory MessageModel.fromMap(Map<String, dynamic> data, String id) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      attachment: data['attachment'],
      attachmentType: data['attachmentType'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'attachment': attachment,
      'attachmentType': attachmentType,
    };
  }

  // Create a copy with some fields changed
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? attachment,
    String? attachmentType,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      attachment: attachment ?? this.attachment,
      attachmentType: attachmentType ?? this.attachmentType,
    );
  }
}

class ConversationModel {
  final String id;
  final List<String> participants;
  final DateTime lastMessageTime;
  final String lastMessageContent;
  final String? lastMessageSenderId;
  final bool hasUnreadMessages;
  final String? listingId;
  final String? listingTitle;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessageTime,
    required this.lastMessageContent,
    this.lastMessageSenderId,
    required this.hasUnreadMessages,
    this.listingId,
    this.listingTitle,
  });

  // Create from Firestore document
  factory ConversationModel.fromMap(Map<String, dynamic> data, String id) {
    return ConversationModel(
      id: id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      lastMessageContent: data['lastMessageContent'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'],
      hasUnreadMessages: data['hasUnreadMessages'] ?? false,
      listingId: data['listingId'],
      listingTitle: data['listingTitle'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageContent': lastMessageContent,
      'lastMessageSenderId': lastMessageSenderId,
      'hasUnreadMessages': hasUnreadMessages,
      'listingId': listingId,
      'listingTitle': listingTitle,
    };
  }
  
  // Create a copy with some fields changed
  ConversationModel copyWith({
    String? id,
    List<String>? participants,
    DateTime? lastMessageTime,
    String? lastMessageContent,
    String? lastMessageSenderId,
    bool? hasUnreadMessages,
    String? listingId,
    String? listingTitle,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
    );
  }
}
