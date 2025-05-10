import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/models/booking_model.dart';
import 'package:rent_mate/services/booking_service.dart';
import 'package:rent_mate/services/notification_service.dart';
import 'package:rent_mate/screens/bookings/booking_details_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3.0,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.white),
            insets: EdgeInsets.symmetric(horizontal: 16.0),
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.card_travel, size: 20),
                  SizedBox(width: 8),
                  Text('My Trips'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.home, size: 20),
                  SizedBox(width: 8),
                  Text('Property Bookings'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = false;
                            _errorMessage = null;
                          });
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // My Trips Tab (bookings I've made as a guest)
                    _buildTripsTab(),
                    
                    // Property Bookings Tab (bookings others have made for my properties)
                    _buildPropertyBookingsTab(),
                  ],
                ),
    );
  }

  // Tab for bookings made by the user (as a guest)
  Widget _buildTripsTab() {
    final bookingService = Provider.of<BookingService>(context);
    
    return StreamBuilder<List<BookingModel>>(
      stream: bookingService.getUserBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading bookings: ${snapshot.error}',
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          );
        }
        
        final bookings = snapshot.data ?? [];
        
        if (bookings.isEmpty) {
          return _buildEmptyState(
            icon: Icons.card_travel,
            title: 'No Trips Yet',
            message: 'Your bookings will appear here once you make a reservation.',
            buttonText: 'Browse Listings',
            onPressed: () {
              // Navigate to listings screen
              Navigator.of(context).pushReplacementNamed('/home');
            },
          );
        }
        
        // Group bookings by status
        final upcomingBookings = bookings.where((b) => 
          b.status == BookingStatus.confirmed && 
          b.startDate.isAfter(DateTime.now())
        ).toList();
        
        final pendingBookings = bookings.where((b) => 
          b.status == BookingStatus.pending
        ).toList();
        
        final pastBookings = bookings.where((b) => 
          b.status == BookingStatus.completed || 
          b.status == BookingStatus.canceled ||
          (b.status == BookingStatus.confirmed && b.endDate.isBefore(DateTime.now()))
        ).toList();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending bookings section
              if (pendingBookings.isNotEmpty) ...[
                _buildSectionTitle('Pending Requests (${pendingBookings.length})'),
                const SizedBox(height: 8),
                ...pendingBookings.map((booking) => _buildBookingCard(booking)),
                const SizedBox(height: 24),
              ],
              
              // Upcoming bookings section
              if (upcomingBookings.isNotEmpty) ...[
                _buildSectionTitle('Upcoming Trips (${upcomingBookings.length})'),
                const SizedBox(height: 8),
                ...upcomingBookings.map((booking) => _buildBookingCard(booking)),
                const SizedBox(height: 24),
              ],
              
              // Past bookings section
              if (pastBookings.isNotEmpty) ...[
                _buildSectionTitle('Past Trips (${pastBookings.length})'),
                const SizedBox(height: 8),
                ...pastBookings.map((booking) => _buildBookingCard(booking)),
              ],
            ],
          ),
        );
      },
    );
  }

  // Tab for bookings made to properties owned by the user
  Widget _buildPropertyBookingsTab() {
    final bookingService = Provider.of<BookingService>(context);
    
    return StreamBuilder<List<BookingModel>>(
      stream: bookingService.getOwnerBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading bookings: ${snapshot.error}',
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          );
        }
        
        final bookings = snapshot.data ?? [];
        
        if (bookings.isEmpty) {
          return _buildEmptyState(
            icon: Icons.villa,
            title: 'No Property Bookings',
            message: 'Booking requests for your properties will appear here.',
            buttonText: 'List Your Space',
            onPressed: () {
              // Navigate to add listing screen
              Navigator.of(context).pushNamed('/add_listing');
            },
          );
        }
        
        // Group bookings by status
        final pendingBookings = bookings.where((b) => 
          b.status == BookingStatus.pending
        ).toList();
        
        final upcomingBookings = bookings.where((b) => 
          b.status == BookingStatus.confirmed && 
          b.startDate.isAfter(DateTime.now())
        ).toList();
        
        final pastBookings = bookings.where((b) => 
          b.status == BookingStatus.completed || 
          b.status == BookingStatus.canceled ||
          (b.status == BookingStatus.confirmed && b.endDate.isBefore(DateTime.now()))
        ).toList();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending requests section (most important for property owners)
              if (pendingBookings.isNotEmpty) ...[
                _buildSectionTitle('Pending Approval (${pendingBookings.length})'),
                const SizedBox(height: 8),
                ...pendingBookings.map((booking) => _buildPropertyBookingCard(
                  booking,
                  showActions: true,
                )),
                const SizedBox(height: 24),
              ],
              
              // Upcoming bookings section
              if (upcomingBookings.isNotEmpty) ...[
                _buildSectionTitle('Upcoming Bookings (${upcomingBookings.length})'),
                const SizedBox(height: 8),
                ...upcomingBookings.map((booking) => _buildPropertyBookingCard(booking)),
                const SizedBox(height: 24),
              ],
              
              // Past bookings section
              if (pastBookings.isNotEmpty) ...[
                _buildSectionTitle('Past Bookings (${pastBookings.length})'),
                const SizedBox(height: 8),
                ...pastBookings.map((booking) => _buildPropertyBookingCard(booking)),
              ],
            ],
          ),
        );
      },
    );
  }

  // Section title widget
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Booking card widget for trips tab
  Widget _buildBookingCard(BookingModel booking) {
    final isUpcoming = booking.status == BookingStatus.confirmed && 
                       booking.startDate.isAfter(DateTime.now());
    
    // More distinct colors for different booking statuses
    Color statusBorderColor;
    switch (booking.status) {
      case BookingStatus.pending:
        statusBorderColor = const Color(0xFFFFA000); // Orange/Amber
        break;
      case BookingStatus.confirmed:
        statusBorderColor = const Color(0xFF4CAF50); // Green
        break;
      case BookingStatus.canceled:
        statusBorderColor = const Color(0xFFF44336); // Red
        break;
      case BookingStatus.completed:
        statusBorderColor = const Color(0xFF2196F3); // Blue
        break;
      default:
        statusBorderColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusBorderColor.withOpacity(0.7),
          width: 2.0,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: BookingModel.getStatusColor(booking.status).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: BookingModel.getStatusColor(booking.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.statusText,
                    style: TextStyle(
                      color: BookingModel.getStatusColor(booking.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${booking.durationInDays} ${booking.durationInDays > 1 ? 'days' : 'day'}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            // Booking content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Listing image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: booking.listingImageUrl != null
                          ? Image.network(
                              booking.listingImageUrl!,
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
                  // Booking details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.listingTitle ?? 'Booking #${booking.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('MMM d').format(booking.startDate)} - ${DateFormat('MMM d, y').format(booking.endDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isUpcoming ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${booking.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Booking card widget for property bookings tab
  Widget _buildPropertyBookingCard(BookingModel booking, {bool showActions = false}) {
    // More distinct colors for different booking statuses
    Color statusBorderColor;
    switch (booking.status) {
      case BookingStatus.pending:
        statusBorderColor = const Color(0xFFFFA000); // Orange/Amber
        break;
      case BookingStatus.confirmed:
        statusBorderColor = const Color(0xFF4CAF50); // Green
        break;
      case BookingStatus.canceled:
        statusBorderColor = const Color(0xFFF44336); // Red
        break;
      case BookingStatus.completed:
        statusBorderColor = const Color(0xFF2196F3); // Blue
        break;
      default:
        statusBorderColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusBorderColor.withOpacity(0.7),
          width: 2.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: BookingModel.getStatusColor(booking.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: BookingModel.getStatusColor(booking.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  booking.statusText,
                  style: TextStyle(
                    color: BookingModel.getStatusColor(booking.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${booking.durationInDays} ${booking.durationInDays > 1 ? 'days' : 'day'}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // Booking content
          InkWell(
            onTap: () => _navigateToBookingDetails(booking),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Listing image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: booking.listingImageUrl != null
                          ? Image.network(
                              booking.listingImageUrl!,
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
                  // Booking details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.listingTitle ?? 'Booking #${booking.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('MMM d').format(booking.startDate)} - ${DateFormat('MMM d, y').format(booking.endDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${booking.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Notes (if any)
                        if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                          Text(
                            'Note: ${booking.notes}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action buttons for pending bookings
          if (showActions && booking.status == BookingStatus.pending) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Reject button
                  OutlinedButton(
                    onPressed: () => _rejectBooking(booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 8),
                  // Accept button
                  ElevatedButton(
                    onPressed: () => _acceptBooking(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  // Navigate to booking details screen
  void _navigateToBookingDetails(BookingModel booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(booking: booking),
      ),
    );
  }

  // Accept a booking request
  Future<void> _acceptBooking(BookingModel booking) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      await bookingService.updateBookingStatus(
        booking.id,
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Reject a booking request
  Future<void> _rejectBooking(BookingModel booking) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      await bookingService.updateBookingStatus(
        booking.id,
        BookingStatus.canceled,
        notificationService: notificationService,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking declined'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
