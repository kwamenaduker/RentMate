import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/models/notification_model.dart';
import 'package:rent_mate/services/notification_service.dart';
import 'package:rent_mate/screens/listings/listing_details_screen.dart';
import 'package:rent_mate/screens/messages/chat_screen.dart';
import 'package:rent_mate/services/listing_service.dart';
import 'package:rent_mate/services/message_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final ListingService _listingService = ListingService();
  final MessageService _messageService = MessageService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Mark all as read button
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllAsRead(),
            tooltip: 'Mark all as read',
          ),
          // Clear all button
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showClearAllDialog(),
            tooltip: 'Clear all notifications',
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error loading notifications', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (error.contains('requires an index'))
                    Column(
                      children: [
                        const Text(
                          'This feature requires a Firestore index to be created.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please use the link in the error message or check the console output to create the required index.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Technical details: ${error.substring(0, error.indexOf("https"))}...',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    Text(error),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }
          
          final notifications = snapshot.data!;
          
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationTile(notification);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildNotificationTile(NotificationModel notification) {
    // Get the icon based on notification type
    final IconData iconData;
    switch (notification.targetType) {
      case 'listing':
        iconData = Icons.home;
        break;
      case 'message':
        iconData = Icons.message;
        break;
      case 'user':
        iconData = Icons.person;
        break;
      case 'system':
      default:
        iconData = Icons.notifications;
    }
    
    // Format the time
    final String timeAgo = _getTimeAgo(notification.createdAt);
    
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification removed'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.isRead
              ? Colors.grey.withOpacity(0.2)
              : AppTheme.primaryColor.withOpacity(0.2),
          child: Icon(
            iconData,
            color: notification.isRead
                ? Colors.grey
                : AppTheme.primaryColor,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: notification.isRead
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          _handleNotificationTap(notification);
        },
      ),
    );
  }
  
  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
    }
    
    // Navigate based on type
    if (!mounted) return;
    
    switch (notification.targetType) {
      case 'listing':
        if (notification.targetId != null) {
          _navigateToListing(notification.targetId!);
        }
        break;
      case 'message':
        if (notification.targetId != null) {
          _navigateToChat(notification.targetId!);
        }
        break;
      case 'user':
        // Navigate to user profile
        break;
      case 'system':
      default:
        // Just mark as read, no navigation
        break;
    }
  }
  
  Future<void> _navigateToListing(String listingId) async {
    try {
      final listing = await _listingService.getListingById(listingId);
      if (listing != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingDetailsScreen(listingId: listingId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open listing: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  Future<void> _navigateToChat(String conversationId) async {
    try {
      bool exists = await _messageService.checkIfConversationExists(conversationId);
      if (exists && mounted) {
        // Get the other participant ID - properly await the Future first
        final conversations = await _messageService.getConversations().first;
        
        // Check if the conversation exists in the list
        if (conversations.any((conv) => conv.id == conversationId)) {
          final conversation = conversations.firstWhere((conv) => conv.id == conversationId);
          
          final otherParticipantId = conversation.participants
              .firstWhere(
                (id) => id != _notificationService.currentUserId,
                orElse: () => conversation.participants.isNotEmpty
                  ? conversation.participants.first
                  : '',
              );
          
          if (otherParticipantId.isNotEmpty && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  conversationId: conversationId,
                  otherUserId: otherParticipantId,
                  listingId: conversation.listingId,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open conversation: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
  
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to remove all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllNotifications();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteAllNotifications() async {
    try {
      await _notificationService.deleteAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: AppTheme.subheadingStyle.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'re all caught up!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
