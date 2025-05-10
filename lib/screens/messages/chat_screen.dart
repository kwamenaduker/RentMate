import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/models/message_model.dart';
import 'package:rent_mate/models/user_model.dart';
import 'package:rent_mate/models/listing_model.dart';
import 'package:rent_mate/services/auth_service.dart';
import 'package:rent_mate/services/listing_service.dart';
import 'package:rent_mate/services/message_service.dart';
import 'package:rent_mate/services/notification_service.dart';
import 'package:rent_mate/screens/listings/listing_details_screen.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String? listingId;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.otherUserId,
    this.listingId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthService _authService = AuthService();
  final ListingService _listingService = ListingService();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  
  UserModel? _otherUser;
  ListingModel? _listing;
  bool _isLoading = true;
  bool _isSending = false;
  String? _attachment;
  String? _attachmentType;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final messageService = Provider.of<MessageService>(context, listen: false);
      final bool isDemoMode = messageService.isDemoMode;
      
      // In demo mode, use placeholder data for the other user
      UserModel? otherUser;
      if (isDemoMode) {
        print('Using demo mode data for user: ${widget.otherUserId}');
        
        // Use different owner names based on ID
        String ownerName = 'Property Owner';
        if (widget.otherUserId.contains('demo-owner-1')) {
          ownerName = 'John Smith';
        } else if (widget.otherUserId.contains('demo-owner-2')) {
          ownerName = 'Sarah Johnson';
        } else if (widget.otherUserId.contains('demo-owner-3')) {
          ownerName = 'Michael Lee';
        }
        
        // Create a mock user for demo mode
        otherUser = UserModel(
          id: widget.otherUserId,
          name: ownerName,
          email: '$ownerName@example.com'.toLowerCase().replaceAll(' ', '.'),
          phoneNumber: '555-123-4567',
          profileImageUrl: 'https://ui-avatars.com/api/?name=${ownerName.replaceAll(' ', '+')}',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          favoriteListings: [],
          address: '123 Main St, New York, NY 10001'
        );
      } else {
        // Load real user data from service
        otherUser = await _authService.getUserData(widget.otherUserId);
      }
      
      // Load listing data if available
      ListingModel? listing;
      if (widget.listingId != null) {
        listing = await _listingService.getListingById(widget.listingId!);
      }
      
      if (mounted) {
        try {
          // Verify authentication first
          final String? currentUserId = messageService.currentUserId;
          print('Current user ID before creating conversation: $currentUserId');
          
          // If no authentication in real mode, switch to demo temporarily
          if ((currentUserId == null || currentUserId.isEmpty) && !isDemoMode) {
            print('WARNING: No authentication in real mode - using fallback');
            // Let the user know what's happening 
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Using demo mode since you are not logged in. Please sign in for full functionality.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          
          // For both demo and real mode, ensure the conversation exists
          bool conversationExists = await messageService.checkIfConversationExists(widget.conversationId);
          print('Conversation exists: $conversationExists');
          
          if (!conversationExists) {
            print('Creating new conversation: ${widget.conversationId}');
            // Create conversation with proper participants
            final currentId = currentUserId ?? 'demo-user-id'; // Fallback for not logged in
            final participants = [currentId, widget.otherUserId];
            print('Participants for new conversation: $participants');
            
            // Create conversation if it doesn't exist
            await messageService.createNewConversation(
              conversationId: widget.conversationId,
              participants: participants,
              listingId: widget.listingId,
              listingTitle: listing?.title
            );
          }
          
          // Mark conversation as read
          await messageService.markAsRead(widget.conversationId);
          
          setState(() {
            _otherUser = otherUser;
            _listing = listing;
            _isLoading = false;
          });
        } catch (innerError) {
          print('Inner error: $innerError');
          print('Stack trace: ${StackTrace.current}');
          // Even if there was an error marking as read, we can still show the conversation
          setState(() {
            _otherUser = otherUser;
            _listing = listing;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Main error: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          // Show detailed error for debugging
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _sendMessage() async {
    final String content = _messageController.text.trim();
    
    // Don't send empty messages
    if (content.isEmpty && _attachment == null) {
      return;
    }
    
    setState(() {
      _isSending = true;
    });
    
    try {
      final messageService = Provider.of<MessageService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      await messageService.sendMessage(
        conversationId: widget.conversationId,
        receiverId: widget.otherUserId,
        content: content,
        attachment: _attachment,
        attachmentType: _attachmentType,
        listingId: widget.listingId,
        listingTitle: _listing?.title,
        notificationService: notificationService,
      );
      
      // Clear the input field and attachment
      _messageController.clear();
      setState(() {
        _attachment = null;
        _attachmentType = null;
      });
      
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (image != null) {
        // In a real app, you would upload the image to storage
        // and get the URL here
        
        // For now, just set a placeholder
        setState(() {
          _attachment = image.path;
          _attachmentType = 'image';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final messageService = Provider.of<MessageService>(context);
    final bool isUserLoggedIn = messageService.currentUserId != null && messageService.currentUserId!.isNotEmpty;
    
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        titleSpacing: 0,
        title: _isLoading
            ? const Text('Loading...')
            : Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    backgroundImage: _otherUser?.profileImageUrl != null
                        ? NetworkImage(_otherUser!.profileImageUrl!)
                        : null,
                    child: _otherUser?.profileImageUrl == null
                        ? const Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _otherUser?.name ?? 'Unknown User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_listing != null)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListingDetailsScreen(
                                    listingId: _listing!.id,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Re: ${_listing!.title}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          // Add login button if not logged in
          if (!messageService.isDemoMode && !isUserLoggedIn)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () => Navigator.pushNamed(context, '/login'),
              tooltip: 'Log in to use messaging',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Conversation'),
                  ],
                ),
              ),
            ],
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
                        onPressed: _loadData,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Messages
                    Expanded(
                      child: StreamBuilder<List<MessageModel>>(
                        stream: messageService.getMessages(widget.conversationId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading messages: ${snapshot.error}',
                                style: const TextStyle(color: AppTheme.errorColor),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          
                          final messages = snapshot.data ?? [];
                          
                          if (messages.isEmpty) {
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
                                      Icons.chat_bubble_outline,
                                      size: 40,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No messages yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Start the conversation!',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isFromMe = message.senderId == messageService.currentUserId;
                              final previousMessage = index < messages.length - 1 ? messages[index + 1] : null;
                              final showDateSeparator = previousMessage == null ||
                                  !_isSameDay(message.timestamp, previousMessage.timestamp);
                              
                              return Column(
                                children: [
                                  if (showDateSeparator)
                                    _buildDateSeparator(message.timestamp),
                                  _buildMessageBubble(message, isFromMe),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    
                    // Attachment preview
                    if (_attachment != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.grey[200],
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.image,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Image attachment',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _attachment = null;
                                  _attachmentType = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    
                    // Message input
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.photo),
                              color: AppTheme.primaryColor,
                              onPressed: _pickImage,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                minLines: 1,
                                maxLines: 5,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            IconButton(
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                              color: AppTheme.primaryColor,
                              onPressed: _isSending ? null : _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildMessageBubble(MessageModel message, bool isFromMe) {
    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isFromMe ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.attachment != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(message.attachment!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: isFromMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isFromMe ? Colors.white70 : Colors.black54,
                  ),
                ),
                if (isFromMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: Colors.grey),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
  
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final messageService = Provider.of<MessageService>(context, listen: false);
                await messageService.deleteConversation(widget.conversationId);
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conversation deleted'),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting conversation: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
