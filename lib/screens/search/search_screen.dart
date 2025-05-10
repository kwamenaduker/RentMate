import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/models/listing_model.dart';
import 'package:rent_mate/services/listing_service.dart';
import 'package:rent_mate/widgets/listing_card.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  
  const SearchScreen({
    Key? key,
    this.initialQuery,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ListingService _listingService = ListingService();
  
  List<ListingModel> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filter states
  String _selectedCategory = 'All';
  RangeValues _priceRange = const RangeValues(0, 10000);
  List<String> _selectedAmenities = [];
  bool _showOnlyAvailable = true;
  
  // Sorting options
  String _sortOption = 'Newest';
  final List<String> _sortOptions = ['Newest', 'Price: Low to High', 'Price: High to Low'];
  
  final List<String> _categories = [
    'All',
    'Apartment',
    'House',
    'Room',
    'Office',
    'Land',
    'Other',
  ];
  
  final List<String> _amenityOptions = [
    'Wifi',
    'Kitchen',
    'Parking',
    'Air Conditioning',
    'Heating',
    'TV',
    'Washer',
    'Dryer',
    'Pool',
    'Gym',
    'Elevator',
    'Furnished',
    'Pet Friendly',
    'Smoke Free',
    'Balcony',
    'Security System',
  ];

  @override
  void initState() {
    super.initState();
    
    // Set initial query if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty && _selectedCategory == 'All' && _selectedAmenities.isEmpty) {
      // If no specific search criteria, just show all listings
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        final listings = await _listingService.getAllListings().first;
        _applyFiltersAndSort(listings);
      } catch (e) {
        setState(() {
          _errorMessage = 'Error loading listings: $e';
          _searchResults = [];
          _isLoading = false;
        });
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      List<ListingModel> results;
      
      if (query.isNotEmpty) {
        // Text-based search
        results = await _listingService.searchListings(query);
      } else if (_selectedCategory != 'All') {
        // Category-based search
        results = await _listingService.getListingsByCategory(_selectedCategory).first;
      } else {
        // Get all listings if no specific query
        results = await _listingService.getAllListings().first;
      }
      
      _applyFiltersAndSort(results);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching: $e';
        _searchResults = [];
        _isLoading = false;
      });
    }
  }
  
  void _applyFiltersAndSort(List<ListingModel> listings) {
    // Apply category filter if selected and not applied at query level
    if (_selectedCategory != 'All' && _searchController.text.isNotEmpty) {
      listings = listings.where((listing) => 
        listing.category == _selectedCategory).toList();
    }
    
    // Apply price filter
    listings = listings.where((listing) => 
      listing.price >= _priceRange.start && 
      listing.price <= _priceRange.end).toList();
    
    // Apply amenities filter
    if (_selectedAmenities.isNotEmpty) {
      listings = listings.where((listing) => 
        _selectedAmenities.every((amenity) => 
          listing.amenities.contains(amenity))).toList();
    }
    
    // Apply availability filter
    if (_showOnlyAvailable) {
      listings = listings.where((listing) => listing.isAvailable).toList();
    }
    
    // Apply sorting
    switch (_sortOption) {
      case 'Newest':
        listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Price: Low to High':
        listings.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        listings.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    
    setState(() {
      _searchResults = listings;
      _isLoading = false;
    });
  }
  
  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _priceRange = const RangeValues(0, 10000);
      _selectedAmenities = [];
      _showOnlyAvailable = true;
      _sortOption = 'Newest';
    });
    
    _performSearch();
  }
  
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Listings',
                      style: AppTheme.headingStyle.copyWith(fontSize: 18),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedCategory = 'All';
                          _priceRange = const RangeValues(0, 10000);
                          _selectedAmenities = [];
                          _showOnlyAvailable = true;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const Divider(),
                
                // Filter options in a scrollable area
                Expanded(
                  child: ListView(
                    children: [
                      // Categories
                      Text(
                        'Categories',
                        style: AppTheme.subheadingStyle,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((category) {
                          final isSelected = category == _selectedCategory;
                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  _selectedCategory = category;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Price Range
                      Text(
                        'Price Range (\$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()})',
                        style: AppTheme.subheadingStyle,
                      ),
                      const SizedBox(height: 8),
                      RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 10000,
                        divisions: 100,
                        labels: RangeLabels(
                          '\$${_priceRange.start.toInt()}',
                          '\$${_priceRange.end.toInt()}',
                        ),
                        onChanged: (values) {
                          setModalState(() {
                            _priceRange = values;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Amenities
                      Text(
                        'Amenities',
                        style: AppTheme.subheadingStyle,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _amenityOptions.map((amenity) {
                          final isSelected = _selectedAmenities.contains(amenity);
                          return FilterChip(
                            label: Text(amenity),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _selectedAmenities.add(amenity);
                                } else {
                                  _selectedAmenities.remove(amenity);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Availability
                      SwitchListTile(
                        title: const Text('Show only available listings'),
                        value: _showOnlyAvailable,
                        onChanged: (value) {
                          setModalState(() {
                            _showOnlyAvailable = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _performSearch();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Apply Filters'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: AppTheme.headingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ...List.generate(_sortOptions.length, (index) {
              final option = _sortOptions[index];
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() {
                    _sortOption = value!;
                  });
                  Navigator.pop(context);
                  _applyFiltersAndSort(_searchResults);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortBottomSheet,
            tooltip: 'Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search rentals...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _performSearch(),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterBottomSheet,
                  tooltip: 'Filter',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Active filters display
          if (_selectedCategory != 'All' || 
              _selectedAmenities.isNotEmpty || 
              _priceRange.start > 0 || 
              _priceRange.end < 10000 ||
              !_showOnlyAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Active Filters:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_selectedCategory != 'All')
                        Chip(
                          label: Text(_selectedCategory),
                          onDeleted: () {
                            setState(() {
                              _selectedCategory = 'All';
                            });
                            _performSearch();
                          },
                        ),
                      if (_priceRange.start > 0 || _priceRange.end < 10000)
                        Chip(
                          label: Text('\$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()}'),
                          onDeleted: () {
                            setState(() {
                              _priceRange = const RangeValues(0, 10000);
                            });
                            _performSearch();
                          },
                        ),
                      ..._selectedAmenities.map((amenity) => Chip(
                        label: Text(amenity),
                        onDeleted: () {
                          setState(() {
                            _selectedAmenities.remove(amenity);
                          });
                          _performSearch();
                        },
                      )).toList(),
                      if (!_showOnlyAvailable)
                        Chip(
                          label: const Text('Include Unavailable'),
                          onDeleted: () {
                            setState(() {
                              _showOnlyAvailable = true;
                            });
                            _performSearch();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: AppTheme.subheadingStyle.copyWith(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Try adjusting your search or filters',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final listing = _searchResults[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: ListingCard(listing: listing),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
