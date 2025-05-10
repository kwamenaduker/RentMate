import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/screens/listings/edit_listing_screen.dart';
import 'package:rent_mate/services/notification_service.dart';
import 'package:rent_mate/models/listing_model.dart';
import 'package:rent_mate/services/listing_service.dart';
import 'package:rent_mate/services/auth_service.dart';
import 'package:rent_mate/services/location_service.dart';
import 'package:rent_mate/services/message_service.dart';
import 'package:rent_mate/screens/messages/chat_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rent_mate/screens/bookings/create_booking_screen.dart';

class ListingDetailsScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailsScreen({
    Key? key,
    required this.listingId,
  }) : super(key: key);

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  final ListingService _listingService = ListingService();
  final AuthService _authService = AuthService();
  
  ListingModel? _listing;
  List<ListingModel> _nearbyListings = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;
  bool _isToggling = false;
  bool _loadingNearby = false;
  
  late CarouselController _carouselController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _carouselController = CarouselController();
    _loadListingDetails();
  }

  Future<void> _loadListingDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final listing = await _listingService.getListingById(widget.listingId);

      if (listing != null) {
        setState(() {
          _listing = listing;
          _isLoading = false;
        });

        // Check if this listing is in user's favorites
        final authService = context.read<AuthService>();
        if (authService.isLoggedIn) {
          try {
            final isFavorited = await authService.isListingFavorited(widget.listingId);
            setState(() {
              _isFavorite = isFavorited;
            });
          } catch (e) {
            print('Error checking favorite status: $e');
          }
        }
        
        // Load nearby listings
        _loadNearbyListings();
      } else {
        setState(() {
          _errorMessage = 'Listing not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading listing: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadNearbyListings() async {
    if (_listing == null) return;
    
    setState(() {
      _loadingNearby = true;
    });
    
    try {
      // Get listings within 5 km radius
      final nearby = await _listingService.getNearbyListings(
        _listing!.location.latitude,
        _listing!.location.longitude,
        5.0, // 5 kilometers radius
        5, // max 5 results
      );
      
      // Filter out the current listing
      final filteredNearby = nearby.where((item) => item.id != widget.listingId).toList();
      
      setState(() {
        _nearbyListings = filteredNearby;
        _loadingNearby = false;
      });
    } catch (e) {
      print('Error loading nearby listings: $e');
      setState(() {
        _loadingNearby = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final authService = context.read<AuthService>();

    if (authService.isLoggedIn) {
      try {
        String userId;
        
        // Get the user ID (either from Firebase or demo mode)
        if (authService.currentUser != null) {
          userId = authService.currentUser!.uid;
          print('Using Firebase user ID: $userId');
        } else {
          // We're in demo mode - get the mock user data
          final userData = await authService.getCurrentUserData();
          if (userData == null) {
            throw Exception('Could not get user data');
          }
          userId = userData.id;
          print('Using mock user ID: $userId');
        }
        
        // Toggle the favorite status
        await authService.toggleFavorite(userId, widget.listingId);

        // Update the UI
        setState(() {
          _isFavorite = !_isFavorite;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isFavorite
                  ? 'Added to favorites'
                  : 'Removed from favorites'),
              backgroundColor: _isFavorite
                  ? Colors.green
                  : Colors.grey[700],
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        print('Error toggling favorite: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating favorites: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } else {
      // User is not logged in - prompt to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to save favorites'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall() async {
    if (_listing == null) return;

    try {
      final status = await Permission.phone.request();
      if (status.isGranted) {
        final phoneNumber = _listing!.ownerPhoneNumber;
        final url = 'tel:$phoneNumber';

        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone dialer'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone call permission denied'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error making phone call: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Start an in-app conversation with the property owner
  Future<void> _startConversation() async {
    if (_listing == null) return;
    
    final authService = context.read<AuthService>();
    final messageService = context.read<MessageService>();

    // Check if user is logged in
    if (!authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to send messages'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Get the current user's ID
      String? currentUserId = messageService.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Generate a conversation ID using the two user IDs
      final conversationId = messageService.generateConversationId(
        currentUserId,
        _listing!.ownerId,
      );

      // Check if the conversation already exists, if not create it
      bool exists = await messageService.checkIfConversationExists(conversationId);
      
      if (!exists) {
        // Create a new conversation document
        await messageService.createNewConversation(
          conversationId: conversationId, 
          participants: [currentUserId, _listing!.ownerId],
          listingId: _listing!.id,
          listingTitle: _listing!.title
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to the chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              otherUserId: _listing!.ownerId,
              listingId: _listing!.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting conversation: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Send an SMS to the property owner
  Future<void> _sendSMS() async {
    if (_listing == null) return;

    try {
      final status = await Permission.sms.request();
      if (status.isGranted) {
        final phoneNumber = _listing!.ownerPhoneNumber;
        final url = 'sms:$phoneNumber?body=I am interested in your listing "${_listing!.title}" on RentMate.';

        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch SMS app'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS permission denied'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending SMS: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Method to show owner-specific options
  void _showOwnerOptions() {
    if (_listing == null) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != _listing!.ownerId) {
      // Not the owner, don't show options
      return;
    }
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Listing'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _editListing();
                },
              ),
              ListTile(
                leading: Icon(
                  _listing!.isAvailable ? Icons.visibility_off : Icons.visibility,
                  color: _listing!.isAvailable ? Colors.red : Colors.green,
                ),
                title: Text(_listing!.isAvailable ? 'Mark as Unavailable' : 'Mark as Available'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _toggleAvailability();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Listing', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _confirmDeletion();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigate to the edit listing screen
  void _editListing() {
    if (_listing == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditListingScreen(listing: _listing!),
      ),
    ).then((_) => _loadListingDetails()); // Reload after editing
  }

  // Toggle listing availability
  Future<void> _toggleAvailability() async {
    if (_listing == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Store the original listing for comparison
      final originalListing = _listing!;
      
      // Create an updated version of the listing
      final updatedListing = _listing!.copyWith(
        isAvailable: !_listing!.isAvailable,
      );
      
      // Update in Firestore with notification service
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      await _listingService.updateListing(
        updatedListing,
        notificationService: notificationService,
        oldListing: originalListing,
      );
      
      // Reload listing details
      await _loadListingDetails();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Listing marked as ${updatedListing.isAvailable ? 'available' : 'unavailable'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error updating listing: $e';
      });
    }
  }

  // Confirm deletion with a dialog
  void _confirmDeletion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteListing();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Delete the listing
  Future<void> _deleteListing() async {
    if (_listing == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _listingService.deleteListing(_listing!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to the previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error deleting listing: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              if (_listing != null) {
                Share.share(
                  'Check out this listing: ${_listing!.title} - ${_listing!.address}',
                );
              }
            },
          ),
          // Add this menu button for listing owners
          if (_listing != null && FirebaseAuth.instance.currentUser?.uid == _listing!.ownerId)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showOwnerOptions,
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
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : _buildListingDetails(),
      // Add a persistent bottom bar with contact options (only if not the owner)
      bottomNavigationBar: _listing != null && FirebaseAuth.instance.currentUser?.uid != _listing!.ownerId
          ? _buildContactBar()
          : null,
    );
  }

  Widget _buildListingDetails() {
    if (_listing == null) return const SizedBox.shrink();

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // App bar with image carousel
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Image carousel
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 300,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: _listing!.imageUrls.length > 1,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                      ),
                      items: _listing!.imageUrls.map((imageUrl) {
                        return Builder(
                          builder: (BuildContext context) {
                            return CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),

                    // Image indicators
                    if (_listing!.imageUrls.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _listing!.imageUrls.asMap().entries.map((entry) {
                            return Container(
                              width: 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == entry.key
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // Darkened gradient for better visibility of app bar icons
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // Favorite button
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ],
            ),

            // Listing content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Availability indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _listing!.isAvailable ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _listing!.isAvailable ? 'Available' : 'Unavailable',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                      
                    // Title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _listing!.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _listing!.isAvailable
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _listing!.isAvailable ? 'Available' : 'Unavailable',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Address
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _listing!.address,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Owner info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _listing!.ownerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Owner',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.call,
                                  color: AppTheme.primaryColor,
                                ),
                                onPressed: _makePhoneCall,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.message,
                                  color: AppTheme.primaryColor,
                                ),
                                onPressed: _startConversation,
                                tooltip: 'Message in app',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _listing!.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Amenities
                    const Text(
                      'Amenities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _listing!.amenities.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(amenity),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Availability dates
                    if (_listing!.availableFrom != null || _listing!.availableTo != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Availability',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _listing!.availableFrom != null
                                    ? 'From: ${_formatDate(_listing!.availableFrom!)}'
                                    : 'Available now',
                              ),
                              if (_listing!.availableTo != null) ...[
                                const SizedBox(width: 8),
                                Text('To: ${_formatDate(_listing!.availableTo!)}'),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),

                    // Map view with the property location
                    const Text(
                      'Location on Map',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildMapView(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () {
                          if (_listing != null) {
                            _openInMapsApp(
                              _listing!.location.latitude,
                              _listing!.location.longitude,
                              _listing!.address,
                            );
                          }
                        },
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Get Directions'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    
                    // Nearby listings section
                    if (_nearbyListings.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          const Text(
                            'Nearby Properties',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _nearbyListings.length,
                              itemBuilder: (context, index) {
                                final nearby = _nearbyListings[index];
                                return _buildNearbyListingCard(nearby);
                              },
                            ),
                          ),
                        ],
                      )
                    else if (_loadingNearby)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SizedBox(height: 24),
                          Text(
                            'Nearby Properties',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 24),
                          Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    
                    const SizedBox(height: 80), // Space for bottom buttons
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildNearbyListingCard(ListingModel listing) {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final distance = _listing != null ? locationService.calculateDistance(
      LatLng(_listing!.location.latitude, _listing!.location.longitude),
      LatLng(listing.location.latitude, listing.location.longitude),
    ) : 0.0;
    
    return GestureDetector(
      onTap: () {
        // Navigate to listing details
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ListingDetailsScreen(
              listingId: listing.id,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: CachedNetworkImage(
                imageUrl: listing.imageUrls.isNotEmpty
                    ? listing.imageUrls.first
                    : 'https://via.placeholder.com/160x100',
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            
            // Property details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${listing.price.toStringAsFixed(0)}/day',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${distance.toStringAsFixed(1)} km away',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
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

  // Build the map view
  Widget _buildMapView() {
    if (_listing == null) return const SizedBox.shrink();

    // Check if the listing has location data
    final lat = _listing!.location.latitude;
    final lng = _listing!.location.longitude;

    if (lat == 0 && lng == 0) {
      // No valid location data
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.location_off,
                size: 40,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                'Location not available',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Create a marker for the listing location
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('listing_location'),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: _listing!.title,
          snippet: _listing!.address,
        ),
      ),
    };
    
    // Add markers for nearby listings
    for (var nearby in _nearbyListings) {
      // Skip if this is the current listing
      if (nearby.id == widget.listingId) continue;
      
      markers.add(
        Marker(
          markerId: MarkerId('nearby_${nearby.id}'),
          position: LatLng(nearby.location.latitude, nearby.location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: nearby.title,
            snippet: '\$${nearby.price.toStringAsFixed(0)}/day',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ListingDetailsScreen(
                    listingId: nearby.id,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Return the map view
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(lat, lng),
        zoom: 14,
      ),
      markers: markers,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      onTap: (_) {
        _openInMapsApp(lat, lng, _listing!.address);
      },
    );
  }

  Future<void> _openInMapsApp(double lat, double lng, String label) async {
    final uri = Uri.parse('geo:$lat,$lng?q=${Uri.encodeComponent(label)}');
    final mapUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=${Uri.encodeComponent(label)}';
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (await canLaunchUrl(Uri.parse(mapUrl))) {
        await launchUrl(Uri.parse(mapUrl));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps application'),
          ),
        );
      }
    } catch (e) {
      print('Error opening maps: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open maps application'),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
  
  // Navigate to booking creation screen
  void _navigateToBooking() {
    if (_listing == null) return;
    
    // Ensure user is logged in
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to book this property'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Check if listing is available
    if (!_listing!.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This property is not available for booking at this time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBookingScreen(listing: _listing!),
      ),
    );
  }

  // Build the bottom contact bar with Book Now, Message and Call buttons
  Widget _buildContactBar() {
    // If _listing is null or the current user is the owner, don't show contact bar
    if (_listing == null) return const SizedBox.shrink();
    if (FirebaseAuth.instance.currentUser?.uid == _listing!.ownerId) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Book Now button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToBooking,
              icon: const Icon(Icons.calendar_today, size: 24),
              label: const Text(
                'Book Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Message and Call buttons row
          Row(
            children: [
              // Message button (in-app messaging)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startConversation,
                  icon: const Icon(Icons.message, size: 24),
                  label: const Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50), // Darker color for better contrast
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Call button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _makePhoneCall,
                  icon: const Icon(Icons.call, size: 24),
                  label: const Text(
                    'Call',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60), // Darker green for better contrast
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 3,
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
    );
  }
}
