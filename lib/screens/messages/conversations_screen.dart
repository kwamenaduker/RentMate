import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/models/message_model.dart';
import 'package:rent_mate/models/user_model.dart';
import 'package:rent_mate/services/auth_service.dart';
import 'package:rent_mate/services/message_service.dart';
import 'package:rent_mate/screens/messages/chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageService = Provider.of<MessageService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Will implement search functionality later
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.errorColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : StreamBuilder<List<ConversationModel>>(
                  stream: messageService.getConversations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading conversations: ${snapshot.error}',
                          style: const TextStyle(color: AppTheme.errorColor),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    
                    final conversations = snapshot.data ?? [];
                    
                    if (conversations.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_outlined,
                                size: 64,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No conversations yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Start chatting with property owners\nor interested renters',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/home');
                              },
                              icon: const Icon(Icons.message_outlined),
                              label: const Text('Start a Conversation'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        
                        // Get the other participant's ID with a safe fallback
                        final otherParticipantId = conversation.participants
                            .firstWhere(
                              (id) => id != messageService.currentUserId,
                              orElse: () => conversation.participants.isNotEmpty
                                ? conversation.participants.first
                                : 'unknown-user',
                            );
                        
                        // In demo mode, directly create user objects for demo owners
                        if (messageService.isDemoMode) {
                          // Generate demo user based on ID
                          UserModel? otherUser;
                          String ownerName = 'Property Owner';
                          
                          if (otherParticipantId.contains('demo-owner-1')) {
                            ownerName = 'John Smith';
                          } else if (otherParticipantId.contains('demo-owner-2')) {
                            ownerName = 'Sarah Johnson';
                          } else if (otherParticipantId.contains('demo-owner-3')) {
                            ownerName = 'Michael Lee';
                          }
                          
                          otherUser = UserModel(
                            id: otherParticipantId,
                            name: ownerName,
                            email: '$ownerName@example.com'.toLowerCase().replaceAll(' ', '.'),
                            phoneNumber: '555-123-4567',
                            profileImageUrl: 'https://ui-avatars.com/api/?name=${ownerName.replaceAll(' ', '+')}',
                            createdAt: DateTime.now().subtract(const Duration(days: 30)),
                            favoriteListings: [],
                          );
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                              backgroundImage: NetworkImage(otherUser.profileImageUrl!),
                            ),
                            title: Text(
                              ownerName,
                              style: TextStyle(
                                fontWeight: conversation.hasUnreadMessages
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              ),
                            ),
                            subtitle: buildConversationSubtitle(conversation, messageService),
                            trailing: buildTimeAndUnreadIndicator(conversation),
                            onTap: () => openChatScreen(context, conversation, otherParticipantId),
                          );
                        }
                        
                        // For non-demo mode, use the regular AuthService
                        return FutureBuilder<UserModel?>(
                          future: _authService.getUserData(otherParticipantId),
                          builder: (context, userSnapshot) {
                            final otherUser = userSnapshot.data;
                            final isLoadingUser = userSnapshot.connectionState == ConnectionState.waiting;
                            final hasUserError = userSnapshot.hasError;
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isLoadingUser
                                    ? Colors.grey[300]
                                    : AppTheme.primaryColor.withOpacity(0.2),
                                backgroundImage: otherUser?.profileImageUrl != null
                                    ? NetworkImage(otherUser!.profileImageUrl!)
                                    : null,
                                child: isLoadingUser
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : otherUser?.profileImageUrl == null
                                        ? const Icon(
                                            Icons.person,
                                            color: AppTheme.primaryColor,
                                          )
                                        : null,
                              ),
                              title: Text(
                                isLoadingUser
                                    ? 'Loading...'
                                    : hasUserError
                                        ? 'Unknown User'
                                        : otherUser?.name ?? 'Unknown User',
                                style: TextStyle(
                                  fontWeight: conversation.hasUnreadMessages
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Show a prefix if the message is from the current user
                                  Text(
                                    conversation.lastMessageSenderId == messageService.currentUserId
                                        ? 'You: ${conversation.lastMessageContent}'
                                        : conversation.lastMessageContent,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: conversation.hasUnreadMessages
                                          ? Colors.black87
                                          : Colors.grey,
                                      fontWeight: conversation.hasUnreadMessages
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (conversation.listingTitle != null)
                                    Text(
                                      'Re: ${conversation.listingTitle}',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatTime(conversation.lastMessageTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: conversation.hasUnreadMessages
                                          ? AppTheme.primaryColor
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (conversation.hasUnreadMessages)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Text(
                                        '',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      conversationId: conversation.id,
                                      otherUserId: otherParticipantId,
                                      listingId: conversation.listingId,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
    );
  }
  
  // Helper methods for conversation list items
  Widget buildConversationSubtitle(ConversationModel conversation, MessageService messageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show a prefix if the message is from the current user
        Text(
          conversation.lastMessageSenderId == messageService.currentUserId
              ? 'You: ${conversation.lastMessageContent}'
              : conversation.lastMessageContent,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: conversation.hasUnreadMessages
                ? Colors.black87
                : Colors.grey,
            fontWeight: conversation.hasUnreadMessages
                ? FontWeight.w500
                : FontWeight.normal,
          ),
        ),
        if (conversation.listingTitle != null)
          Text(
            'Re: ${conversation.listingTitle}',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget buildTimeAndUnreadIndicator(ConversationModel conversation) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatTime(conversation.lastMessageTime),
          style: TextStyle(
            fontSize: 12,
            color: conversation.hasUnreadMessages
                ? AppTheme.primaryColor
                : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        if (conversation.hasUnreadMessages)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
              ),
            ),
          ),
      ],
    );
  }

  void openChatScreen(BuildContext context, ConversationModel conversation, String otherParticipantId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversation.id,
          otherUserId: otherParticipantId,
          listingId: conversation.listingId,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      if (difference.inDays < 7) {
        // For messages within the last week, show day of week
        return DateFormat('E').format(time);
      } else {
        // For older messages, show date
        return DateFormat('M/d').format(time);
      }
    } else {
      // For today's messages, show time
      return DateFormat('h:mm a').format(time);
    }
  }
}
