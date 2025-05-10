import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/services/auth_service.dart';
import 'package:rent_mate/services/listing_service.dart';
import 'package:rent_mate/services/notification_service.dart';
import 'package:rent_mate/models/user_model.dart';
import 'package:rent_mate/models/listing_model.dart';
import 'package:rent_mate/screens/profile/edit_profile_screen.dart';
import 'package:rent_mate/screens/listings/listing_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final ListingService _listingService = ListingService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = true;
  UserModel? _userData;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final user = context.read<AuthService>().currentUser;
      
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _editProfile() async {
    if (_userData == null) return;
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: _userData!),
      ),
    );
    
    // If profile was updated successfully, reload user data
    if (result == true) {
      await _loadUserData();
    }
  }
  
  // Toggle listing availability
  Future<void> _toggleAvailability(ListingModel listing) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Create an updated version of the listing
      final originalListing = listing;
      final updatedListing = listing.copyWith(
        isAvailable: !listing.isAvailable,
      );
      
      // Update in Firestore with notification service
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      await _listingService.updateListing(
        updatedListing,
        notificationService: notificationService,
        oldListing: originalListing,
      );
      
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
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating listing: $e'),
            backgroundColor: AppTheme.errorColor,
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
  

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
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
                        onPressed: _loadUserData,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _buildProfile(),
    );
  }
  
  Widget _buildProfile() {
    if (_userData == null) {
      return const Center(
        child: Text('No user data available'),
      );
    }
    
    return Column(
      children: [
        // Profile header
        Container(
          padding: const EdgeInsets.all(24),
          color: AppTheme.primaryColor.withOpacity(0.1),
          child: Column(
            children: [
              // Profile picture
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    backgroundImage: _userData!.profileImageUrl != null
                        ? NetworkImage(_userData!.profileImageUrl!)
                        : null,
                    child: _userData!.profileImageUrl == null
                        ? Text(
                            _userData!.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _editProfile,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // User name
              Text(
                _userData!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              
              // User email
              Text(
                _userData!.email,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              // Edit profile button
              OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
                onPressed: _editProfile,
              ),
            ],
          ),
        ),
        
        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'My Listings'),
            Tab(text: 'Favorites'),
          ],
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // My listings tab
              _buildMyListingsTab(),
              
              // Favorites tab
              _buildFavoritesTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMyListingsTab() {
    if (_userData == null) return const SizedBox.shrink();
    
    return StreamBuilder<List<ListingModel>>(
      stream: _listingService.getListingsByOwner(_userData!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading listings: ${snapshot.error}',
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.home_work_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No listings yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your listings will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Listing'),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/add_listing');
                  },
                ),
              ],
            ),
          );
        }
        
        final listings = snapshot.data!;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: listing.imageUrls.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(listing.imageUrls.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[300],
                  ),
                  child: listing.imageUrls.isEmpty
                      ? const Icon(
                          Icons.image_outlined,
                          color: Colors.grey,
                        )
                      : null,
                ),
                title: Text(
                  listing.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '\$${listing.price.toStringAsFixed(2)} / month',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.isAvailable ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        color: listing.isAvailable ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // Show options (edit, delete, etc.)
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text('Edit Listing'),
                              onTap: () {
                                Navigator.pop(context);
                                // Navigate to edit listing
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.visibility),
                              title: const Text('View Listing'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ListingDetailsScreen(
                                      listingId: listing.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                listing.isAvailable
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              title: Text(
                                listing.isAvailable
                                    ? 'Mark as Unavailable'
                                    : 'Mark as Available',
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                // Toggle availability
                                await _toggleAvailability(listing);
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.delete,
                                color: AppTheme.errorColor,
                              ),
                              title: const Text(
                                'Delete Listing',
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                // Show delete confirmation
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListingDetailsScreen(
                        listingId: listing.id,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildFavoritesTab() {
    if (_userData == null) return const SizedBox.shrink();
    
    if (_userData!.favoriteListings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Saved listings will appear here',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Browse Listings'),
              onPressed: () {
                Navigator.of(context).pushNamed('/home');
              },
            ),
          ],
        ),
      );
    }
    
    return FutureBuilder<List<ListingModel?>>(
      future: Future.wait(
        _userData!.favoriteListings.map((id) => _listingService.getListingById(id)).toList(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading favorites: ${snapshot.error}',
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No favorites found'),
          );
        }
        
        // Filter out null values (deleted listings)
        final favorites = snapshot.data!.where((listing) => listing != null).cast<ListingModel>().toList();
        
        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No favorites available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your favorited listings may have been removed',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final listing = favorites[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: listing.imageUrls.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(listing.imageUrls.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[300],
                  ),
                  child: listing.imageUrls.isEmpty
                      ? const Icon(
                          Icons.image_outlined,
                          color: Colors.grey,
                        )
                      : null,
                ),
                title: Text(
                  listing.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '\$${listing.price.toStringAsFixed(2)} / month',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    // Remove from favorites
                    try {
                      await _listingService.toggleFavorite(
                        _userData!.id,
                        listing.id,
                      );
                      
                      setState(() {
                        // Update local user data
                        _userData = _userData!.copyWith(
                          favoriteListings: List.from(_userData!.favoriteListings)
                            ..remove(listing.id),
                        );
                      });
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Removed from favorites'),
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
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListingDetailsScreen(
                        listingId: listing.id,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
