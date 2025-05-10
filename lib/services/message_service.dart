import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class MessageService extends ChangeNotifier {
  // Flag to enable demo mode for testing without Firebase
  final bool _demoMode = false; // Using real Firebase for production
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Mock data for demo mode
  final List<ConversationModel> _mockConversations = [];
  final Map<String, List<MessageModel>> _mockMessages = {};
  
  // Constructor to initialize demo data
  MessageService() {
    if (_demoMode) {
      _initializeDemoData();
    }
    
    // Listen for auth state changes to refresh demo data
    _auth.authStateChanges().listen((User? user) {
      if (_demoMode && user != null) {
        print('User authenticated, refreshing demo data for: ${user.uid}');
        _initializeDemoData(); // Refresh demo data with new user ID
        notifyListeners();
      }
    });
  }
  
  // Initialize demo data for testing
  void _initializeDemoData() {
    print('Initializing demo message data');
    // Clear previous data if any
    _mockConversations.clear();
    _mockMessages.clear();
    
    // Get real user ID if available, otherwise use demo ID
    String? realUserId = _auth.currentUser?.uid;
    final currentDemoUserId = realUserId ?? 'demo-user-id';
    print('Using demo mode with user ID: $currentDemoUserId');
    
    // Create multiple property owner profiles for demo
    final demoOwners = [
      {'id': 'demo-owner-1', 'name': 'John Smith', 'property': 'Cozy 2BR Apartment'},
      {'id': 'demo-owner-2', 'name': 'Sarah Johnson', 'property': 'Downtown Studio'},
      {'id': 'demo-owner-3', 'name': 'Michael Lee', 'property': 'Suburban House'}
    ];
    
    // Create conversations with each owner
    for (var owner in demoOwners) {
      final ownerId = owner['id'] as String;
      final propertyName = owner['property'] as String;
      
      // Generate conversation ID
      final convoId = generateConversationId(currentDemoUserId, ownerId);
      
      // Add conversation
      _mockConversations.add(ConversationModel(
        id: convoId,
        participants: [currentDemoUserId, ownerId],
        lastMessageTime: DateTime.now().subtract(Duration(days: demoOwners.indexOf(owner) + 1)),
        lastMessageContent: 'Is $propertyName still available?',
        lastMessageSenderId: currentDemoUserId,
        hasUnreadMessages: demoOwners.indexOf(owner) == 0, // Only first conversation has unread
        listingId: 'demo-listing-${demoOwners.indexOf(owner) + 1}',
        listingTitle: propertyName,
      ));
      
      // Add messages to this conversation
      _mockMessages[convoId] = [
        MessageModel(
          id: '${convoId}-msg1',
          senderId: currentDemoUserId,
          receiverId: ownerId,
          content: 'Is $propertyName still available?',
          timestamp: DateTime.now().subtract(Duration(days: demoOwners.indexOf(owner) + 1, hours: 2)),
          isRead: true,
        ),
        MessageModel(
          id: '${convoId}-msg2',
          senderId: ownerId,
          receiverId: currentDemoUserId,
          content: 'Yes, it is! When would you like to view it?',
          timestamp: DateTime.now().subtract(Duration(days: demoOwners.indexOf(owner) + 1, hours: 1)),
          isRead: demoOwners.indexOf(owner) != 0, // Only first conversation has unread
        ),
      ];
    }
    
    print('Demo data initialized with ${_mockConversations.length} conversations');
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
  
  // Get all conversations for the current user
  Stream<List<ConversationModel>> getConversations() {
    if (_demoMode) {
      // Return mock conversations
      return Stream.value(_mockConversations);
    }
    
    if (currentUserId == null) {
      return Stream.value([]);
    }
    
    // Temporary solution to avoid index requirement
    // Only filter by participants - no sorting (which requires the index)
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final conversations = snapshot.docs
              .map((doc) => ConversationModel.fromMap(doc.data(), doc.id))
              .toList();
              
          // Sort in memory instead of in the query
          conversations.sort((a, b) => 
              b.lastMessageTime.compareTo(a.lastMessageTime));
              
          return conversations;
        });
  }
  
  // Get messages for a specific conversation
  Stream<List<MessageModel>> getMessages(String conversationId) {
    if (_demoMode) {
      // Return mock messages
      return Stream.value(_mockMessages[conversationId] ?? []);
    }
    
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }
  
  // Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String? attachment,
    String? attachmentType,
    String? listingId,
    String? listingTitle,
    NotificationService? notificationService,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Get sender name for notification
    String senderName = 'Someone';
    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        senderName = userData['name'] ?? 'Someone';
      }
    } catch (e) {
      print('Error getting sender name: $e');
    }
    
    if (_demoMode) {
      // Add to mock messages
      final mockMessage = MessageModel(
        id: 'mock-message-${DateTime.now().millisecondsSinceEpoch}',
        senderId: currentUserId!,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        attachment: attachment,
        attachmentType: attachmentType,
      );
      
      if (_mockMessages.containsKey(conversationId)) {
        _mockMessages[conversationId]!.add(mockMessage);
      } else {
        _mockMessages[conversationId] = [mockMessage];
      }
      
      // Create notification in demo mode
      if (notificationService != null) {
        try {
          String notificationTitle = 'New Message';
          String notificationMessage = '$senderName sent you a message';
          
          if (listingTitle != null && listingTitle.isNotEmpty) {
            notificationMessage += ' about $listingTitle';
          }
          
          notificationService.createNotification(
            userId: receiverId,
            title: notificationTitle,
            message: notificationMessage,
            targetId: conversationId,
            targetType: 'message',
          );
        } catch (e) {
          print('Error creating notification: $e');
        }
      }
      
      // Update conversation or create new one
      final existingConversationIndex = _mockConversations.indexWhere((c) => c.id == conversationId);
      
      if (existingConversationIndex >= 0) {
        _mockConversations[existingConversationIndex] = ConversationModel(
          id: conversationId,
          participants: [currentUserId!, receiverId],
          lastMessageTime: DateTime.now(),
          lastMessageContent: content,
          lastMessageSenderId: currentUserId,
          hasUnreadMessages: true,
          listingId: listingId,
          listingTitle: listingTitle,
        );
      } else {
        _mockConversations.add(ConversationModel(
          id: conversationId,
          participants: [currentUserId!, receiverId],
          lastMessageTime: DateTime.now(),
          lastMessageContent: content,
          lastMessageSenderId: currentUserId,
          hasUnreadMessages: true,
          listingId: listingId,
          listingTitle: listingTitle,
        ));
      }
      
      return;
    }
    
    // Create a message document
    final messageData = MessageModel(
      id: '', // Firestore will generate ID
      senderId: currentUserId!,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
      attachment: attachment,
      attachmentType: attachmentType,
    ).toMap();
    
    // Check if conversation exists
    DocumentSnapshot convoDoc = await _firestore.collection('conversations').doc(conversationId).get();
    
    if (convoDoc.exists) {
      // Add message to existing conversation
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(messageData);
      
      // Update conversation metadata
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessageTime': Timestamp.now(),
        'lastMessageContent': content,
        'lastMessageSenderId': currentUserId,
        'hasUnreadMessages': true,
      });
      
      // Create a notification for the receiver
      if (notificationService != null) {
        try {
          String notificationTitle = 'New Message';
          String notificationMessage = '$senderName sent you a message';
          
          if (listingTitle != null && listingTitle.isNotEmpty) {
            notificationMessage += ' about $listingTitle';
          }
          
          notificationService.createNotification(
            userId: receiverId,
            title: notificationTitle,
            message: notificationMessage,
            targetId: conversationId,
            targetType: 'message',
          );
        } catch (e) {
          print('Error creating notification: $e');
        }
      }
    } else {
      // Create new conversation
      final convoData = ConversationModel(
        id: conversationId,
        participants: [currentUserId!, receiverId],
        lastMessageTime: DateTime.now(),
        lastMessageContent: content,
        lastMessageSenderId: currentUserId,
        hasUnreadMessages: true,
        listingId: listingId,
        listingTitle: listingTitle,
      ).toMap();
      
      // Create conversation and add first message
      await _firestore.collection('conversations').doc(conversationId).set(convoData);
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(messageData);
    }
  }
  
  // Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    if (currentUserId == null) {
      return;
    }
    
    if (_demoMode) {
      // Update mock messages
      if (_mockMessages.containsKey(conversationId)) {
        _mockMessages[conversationId] = _mockMessages[conversationId]!.map((message) {
          if (message.receiverId == currentUserId && !message.isRead) {
            return message.copyWith(isRead: true);
          }
          return message;
        }).toList();
      }
      
      // Update conversation
      final index = _mockConversations.indexWhere((c) => c.id == conversationId);
      if (index >= 0) {
        _mockConversations[index] = _mockConversations[index].copyWith(hasUnreadMessages: false);
      }
      
      return;
    }
    
    // Get all unread messages where current user is receiver
    final querySnapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();
    
    // Create batch to update all messages
    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    // Update conversation metadata
    batch.update(
      _firestore.collection('conversations').doc(conversationId),
      {'hasUnreadMessages': false},
    );
    
    // Commit batch
    await batch.commit();
  }
  
  // Generate a unique conversation ID from two user IDs
  String generateConversationId(String userId1, String userId2) {
    // Sort IDs to ensure consistent conversation ID
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
  
  // Get number of unread messages
  Future<int> getUnreadMessageCount() async {
    if (currentUserId == null) {
      return 0;
    }
    
    if (_demoMode) {
      // Count unread messages in mock conversations
      int count = 0;
      for (var convo in _mockConversations) {
        if (convo.hasUnreadMessages) {
          final messages = _mockMessages[convo.id] ?? [];
          count += messages.where((m) => m.receiverId == currentUserId && !m.isRead).length;
        }
      }
      return count;
    }
    
    // Get all conversations with unread messages
    final querySnapshot = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .where('hasUnreadMessages', isEqualTo: true)
        .get();
    
    int count = 0;
    
    // For each conversation, count unread messages sent to current user
    for (var doc in querySnapshot.docs) {
      final messagesSnapshot = await _firestore
          .collection('conversations')
          .doc(doc.id)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();
      
      count += messagesSnapshot.docs.length;
    }
    
    return count;
  }
  
  // Check if a conversation exists
  Future<bool> checkIfConversationExists(String conversationId) async {
    if (_demoMode) {
      return _mockConversations.any((c) => c.id == conversationId);
    }
    
    try {
      print('Checking if conversation exists: $conversationId');
      
      // Verify Firebase Auth user is available
      if (_auth.currentUser == null && !_demoMode) {
        print('WARNING: Firebase user is null, but not in demo mode!');
      }
      
      final docSnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
      
      print('Conversation exists: ${docSnapshot.exists}');
      return docSnapshot.exists;
    } catch (e) {
      print('Error checking if conversation exists: $e');
      print('Stack trace: ${StackTrace.current}');
      // Return false instead of throwing
      return false;
    }
  }
  
  // Create a new conversation
  Future<void> createNewConversation({
    required String conversationId,
    required List<String> participants,
    String? listingId,
    String? listingTitle,
  }) async {
    print('Creating new conversation with ID: $conversationId');
    print('Participants: $participants');
    print('Listing info: $listingId, $listingTitle');
    
    // Check if we have a valid user ID
    String? userId = currentUserId;
    if (userId == null || userId.isEmpty) {
      print('ERROR: No valid user ID available for creating conversation');
      if (!_demoMode) {
        // Only throw in real Firebase mode
        throw Exception('User not authenticated');
      } else {
        // In demo mode, use a placeholder
        userId = 'demo-user-id';
      }
    }
    
    if (_demoMode) {
      // Create mock conversation
      _mockConversations.add(ConversationModel(
        id: conversationId,
        participants: participants,
        lastMessageTime: DateTime.now(),
        lastMessageContent: '', // No messages yet
        lastMessageSenderId: userId,
        hasUnreadMessages: false,
        listingId: listingId,
        listingTitle: listingTitle,
      ));
      print('Created mock conversation successfully');
      return;
    }
    
    try {
      // Make sure we're not adding empty participants
      final List<String> validParticipants = participants
          .where((id) => id.isNotEmpty)
          .toList();
          
      if (validParticipants.isEmpty) {
        print('ERROR: No valid participants for conversation');
        throw Exception('No valid participants for conversation');
      }
      
      // Create conversation document in Firestore
      await _firestore.collection('conversations').doc(conversationId).set({
        'participants': validParticipants,
        'lastMessageTime': Timestamp.now(),
        'lastMessageContent': '', // No messages yet
        'lastMessageSenderId': userId,
        'hasUnreadMessages': false,
        'listingId': listingId,
        'listingTitle': listingTitle,
      });
      
      print('Created Firebase conversation successfully');
    } catch (e) {
      print('ERROR creating conversation: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow; // Rethrow to allow proper error handling upstream
    }
  }

  // Delete a conversation (both metadata and messages)
  Future<void> deleteConversation(String conversationId) async {
    if (_demoMode) {
      // Remove from mock data
      _mockConversations.removeWhere((c) => c.id == conversationId);
      _mockMessages.remove(conversationId);
      return;
    }
    
    // Get all messages in the conversation
    final messagesSnapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .get();
    
    // Create batch to delete all messages and conversation
    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete conversation document
    batch.delete(_firestore.collection('conversations').doc(conversationId));
    
    // Commit batch
    await batch.commit();
  }
}
