import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/models/booking_model.dart';
import 'package:rent_mate/models/user_model.dart';
import 'package:rent_mate/models/listing_model.dart';
import 'package:rent_mate/services/booking_service.dart';
import 'package:rent_mate/services/notification_service.dart';
import 'package:rent_mate/services/user_service.dart';
import 'package:rent_mate/services/auth_service.dart';
import 'package:rent_mate/services/message_service.dart';
import 'package:rent_mate/services/listing_service.dart';
import 'package:rent_mate/screens/messages/chat_screen.dart';
import 'package:rent_mate/screens/listings/listing_details_screen.dart';
import 'package:rent_mate/widgets/weather_forecast_widget.dart';

class BookingDetailsScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailsScreen({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _otherParty;
  bool _isOwner = false;
  ListingModel? _listing;
  // Default coordinates for weather forecast (will be updated if listing info is available)
  double _latitude = 37.7749; // Default to San Francisco
  double _longitude = -122.4194;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load additional data needed for this screen
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final listingService = Provider.of<ListingService>(context, listen: false);
      
      // Determine if current user is the owner or renter
      final currentUserId = bookingService.currentUserId;
      _isOwner = widget.booking.ownerUserId == currentUserId;
      
      // Get the ID of the other party (owner or renter)
      final otherPartyId = _isOwner
          ? widget.booking.renterUserId
          : widget.booking.ownerUserId;
      
      // Try to get actual user info from Firebase
      try {
        // Check if user is logged in as a basic demo check
        if (!authService.isLoggedIn) {
          // In demo mode or when not properly authenticated, create a realistic mock user
          final name = _isOwner ? 'Guest User' : 'Property Owner';
          _otherParty = UserModel(
            id: otherPartyId,
            name: name,
            email: '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
            phoneNumber: '555-123-4567',
            createdAt: DateTime.now(),
            favoriteListings: [],
          );
        } else {
          // Try to get actual user data
          final userData = await authService.getUserData(otherPartyId);
          if (userData != null) {
            _otherParty = userData;
          } else {
            // Fallback if user data not found
            final name = _isOwner ? 'Guest User' : 'Property Owner';
            _otherParty = UserModel(
              id: otherPartyId,
              name: name,
              email: '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
              phoneNumber: '555-123-4567',
              createdAt: DateTime.now(),
              favoriteListings: [],
            );
          }
        }
      } catch (e) {
        print('Error getting user data: $e');
        // Create fallback user if getting real data fails
        final name = _isOwner ? 'Guest User' : 'Property Owner';
        _otherParty = UserModel(
          id: otherPartyId,
          name: name,
          email: '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
          phoneNumber: '555-123-4567',
          createdAt: DateTime.now(),
          favoriteListings: [],
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load booking details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    
    // Try to get the listing data for weather forecast
    try {
      final listingService = Provider.of<ListingService>(context, listen: false);
      final listing = await listingService.getListingById(widget.booking.listingId);
      if (listing != null) {
        setState(() {
          _listing = listing;
          // Get coordinates from the listing's GeoPoint location
          _latitude = listing.location.latitude;
          _longitude = listing.location.longitude;
        });
      }
    } catch (e) {
      // Just log the error but don't show to user as this is a non-critical feature
      print('Error getting listing data for weather: $e');
    }
  }

  // Call the other party
  Future<void> _makePhoneCall() async {
    if (_otherParty == null || _otherParty!.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final phoneNumber = _otherParty!.phoneNumber;
    final url = 'tel:$phoneNumber';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not make phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Message the other party - open direct chat with other user
  void _messageOtherParty() {
    if (_otherParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot find other party details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      // Simplified navigation to chat - go directly to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: 'conv-${_otherParty!.id}', // Generate a predictable ID
            otherUserId: _otherParty!.id,
            listingId: widget.booking.listingId,
          ),
        ),
      );
    } catch (e) {
      // Fall back to messages screen navigation if something goes wrong
      Navigator.pushNamed(context, '/messages');
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Cancel a booking as a guest
  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      await bookingService.cancelBooking(
        widget.booking.id,
        notificationService: notificationService,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking canceled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error canceling booking: $e';
      });
    }
  }

  // Accept a booking request as an owner
  Future<void> _acceptBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      await bookingService.updateBookingStatus(
        widget.booking.id,
        BookingStatus.confirmed,
        notificationService: notificationService,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the screen
        _loadData();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error confirming booking: $e';
      });
    }
  }

  // Reject a booking request as an owner
  Future<void> _rejectBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Booking Request'),
        content: const Text('Are you sure you want to decline this booking request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      await bookingService.updateBookingStatus(
        widget.booking.id,
        BookingStatus.canceled,
        notificationService: notificationService,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request declined'),
            backgroundColor: Colors.grey,
          ),
        );
        
        // Refresh the screen
        _loadData();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error declining booking: $e';
      });
    }
  }

  // Mark a booking as complete
  Future<void> _completeBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Booking'),
        content: const Text('Are you sure you want to mark this booking as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      await bookingService.updateBookingStatus(
        widget.booking.id,
        BookingStatus.completed,
        notificationService: notificationService,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the screen
        _loadData();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error completing booking: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booking status card
                      Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: BookingModel.getStatusColor(widget.booking.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: BookingModel.getStatusColor(widget.booking.status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.booking.statusText,
                                    style: TextStyle(
                                      color: BookingModel.getStatusColor(widget.booking.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (widget.booking.status == BookingStatus.pending) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Awaiting ${_isOwner ? 'your' : 'owner'} confirmation',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Contact information card
                      if (_otherParty != null) ...[
                        Card(
                          margin: const EdgeInsets.only(bottom: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isOwner ? 'Guest Information' : 'Owner Information',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.grey[200],
                                      child: Text(
                                        _otherParty!.displayName.isNotEmpty
                                            ? _otherParty!.displayName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _otherParty!.displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (_otherParty!.phoneNumber != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              _otherParty!.phoneNumber!,
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Contact buttons with improved design
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _messageOtherParty,
                                        icon: const Icon(Icons.message, size: 20),
                                        label: const Text(
                                          'Message',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          side: const BorderSide(color: Color(0xFF2C3E50), width: 2),
                                          backgroundColor: Colors.white,
                                          foregroundColor: Color(0xFF2C3E50),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _makePhoneCall,
                                        icon: const Icon(Icons.phone, size: 20),
                                        label: const Text(
                                          'Call',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          backgroundColor: const Color(0xFF27AE60),
                                          foregroundColor: Colors.white,
                                          elevation: 3,
                                          shadowColor: Colors.black26,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      // Property information
                      Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Property Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Property image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: widget.booking.listingImageUrl != null
                                          ? Image.network(
                                              widget.booking.listingImageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image_not_supported),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.home),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Property details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.booking.listingTitle ?? 'Booking #${widget.booking.id.substring(0, 8)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            // Navigate to the listing details screen with the correct ID
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ListingDetailsScreen(
                                                  listingId: widget.booking.listingId,
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: AppTheme.primaryColor,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            side: const BorderSide(color: AppTheme.primaryColor),
                                          ),
                                          child: const Text('View Property'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Booking details
                      Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Booking Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow('Check-in Date', DateFormat('EEEE, MMM d, y').format(widget.booking.startDate)),
                              _buildDetailRow('Check-out Date', DateFormat('EEEE, MMM d, y').format(widget.booking.endDate)),
                              _buildDetailRow('Duration', '${widget.booking.durationInDays} ${widget.booking.durationInDays > 1 ? 'days' : 'day'}'),
                              _buildDetailRow('Booking ID', widget.booking.id),
                              _buildDetailRow('Booked On', DateFormat('MMM d, y').format(widget.booking.bookedAt)),
                              _buildDetailRow(
                                'Total Price',
                                '\$${widget.booking.totalPrice.toStringAsFixed(2)}',
                                valueColor: AppTheme.primaryColor,
                                valueFontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Notes section
                      if (widget.booking.notes != null && widget.booking.notes!.isNotEmpty) ...[
                        Card(
                          margin: const EdgeInsets.only(bottom: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Notes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.booking.notes!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.event_busy,
                                      color: AppTheme.primaryColor,
                                    ),
                                    title: const Text(
                                      'Check-out Date',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      DateFormat('EEE, MMM d, yyyy').format(
                                          widget.booking.endDate),
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      // Weather forecast section - moved outside previous container for better visibility
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Debug information
                            Text('Coordinates: $_latitude, $_longitude', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 8),
                            
                            // Weather forecast widget
                            WeatherForecastWidget(
                              latitude: _latitude,
                              longitude: _longitude,
                              startDate: widget.booking.startDate,
                              endDate: widget.booking.endDate,
                              locationName: _listing?.address ?? 'Booking Location',
                            ),
                          ],
                        ),
                      ),
                      
                      // Action buttons based on user role and booking status
                      const SizedBox(height: 8),
                      if (widget.booking.status == BookingStatus.pending) ...[
                        if (_isOwner) ...[
                          // Owner actions for pending booking
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _rejectBooking,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('Decline Request'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _acceptBooking,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('Accept Request'),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Guest actions for pending booking
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _cancelBooking,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel Request'),
                            ),
                          ),
                        ],
                      ] else if (widget.booking.status == BookingStatus.confirmed) ...[
                        if (_isOwner && widget.booking.endDate.isBefore(DateTime.now())) ...[
                          // Owner action to mark booking as completed
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _completeBooking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Mark as Completed'),
                            ),
                          ),
                        ] else if (!_isOwner && widget.booking.startDate.isAfter(DateTime.now())) ...[
                          // Guest action to cancel confirmed booking
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _cancelBooking,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel Booking'),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  // Helper method to build detail rows
  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight valueFontWeight = FontWeight.normal,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueFontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
