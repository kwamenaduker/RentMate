import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/models/listing_model.dart';
import 'package:rent_mate/services/auth_service.dart';
import 'package:rent_mate/services/listing_service.dart';
import 'package:rent_mate/widgets/listing_card.dart';
import 'package:rent_mate/screens/search/search_screen.dart';
import 'package:rent_mate/screens/notifications/notifications_screen.dart';
import 'package:rent_mate/widgets/notification_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ListingService _listingService = ListingService();
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  
  final List<String> _categories = [
    'All',
    'Apartment',
    'House',
    'Room',
    'Office',
    'Land',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RentMate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to search screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          NotificationBadge(
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // Navigate to notifications screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              tooltip: 'Notifications',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Listings
          Expanded(
            child: _buildListings(),
          ),
        ],
      ),
    );
  }

  Widget _buildListings() {
    if (_selectedCategory == 'All') {
      return StreamBuilder<List<ListingModel>>(
        stream: _listingService.getAllListings(),
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
                  Text(
                    'No listings available',
                    style: AppTheme.subheadingStyle.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Be the first to add a rental listing',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          final listings = snapshot.data!;
          
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ListingCard(listing: listing),
                );
              },
            ),
          );
        },
      );
    } else {
      return StreamBuilder<List<ListingModel>>(
        stream: _listingService.getListingsByCategory(_selectedCategory),
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
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No $_selectedCategory listings found',
                    style: AppTheme.subheadingStyle.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try a different category or add a new listing',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          final listings = snapshot.data!;
          
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ListingCard(listing: listing),
                );
              },
            ),
          );
        },
      );
    }
  }
}
