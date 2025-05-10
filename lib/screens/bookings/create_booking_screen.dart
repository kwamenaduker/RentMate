import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/models/booking_model.dart';
import 'package:rent_mate/models/listing_model.dart';
import 'package:rent_mate/services/booking_service.dart';
import 'package:rent_mate/services/notification_service.dart';

class CreateBookingScreen extends StatefulWidget {
  final ListingModel listing;

  const CreateBookingScreen({
    Key? key,
    required this.listing,
  }) : super(key: key);

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _errorMessage;
  double _totalPrice = 0;
  
  @override
  void initState() {
    super.initState();
    // Set default start date (tomorrow)
    _startDate = DateTime.now().add(const Duration(days: 1));
    
    // Set default end date (1 week from tomorrow)
    _endDate = DateTime.now().add(const Duration(days: 8));
    
    // Calculate initial total price
    _calculateTotalPrice();
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  // Calculate the total price based on the selected dates
  void _calculateTotalPrice() {
    if (_startDate != null && _endDate != null) {
      // Calculate number of days
      final difference = _endDate!.difference(_startDate!).inDays + 1; // Include both start and end dates
      
      // Calculate total price
      final totalPrice = widget.listing.price * difference;
      
      setState(() {
        _totalPrice = totalPrice;
      });
    }
  }
  
  // Select start date using date picker
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
        
        // If end date is before or equal to start date, adjust it
        if (_endDate == null || _endDate!.isBefore(_startDate!) || _endDate!.isAtSameMomentAs(_startDate!)) {
          _endDate = _startDate!.add(const Duration(days: 1));
        }
        
        _calculateTotalPrice();
      });
    }
  }
  
  // Select end date using date picker
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 2))),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _calculateTotalPrice();
      });
    }
  }
  
  // Create a booking request
  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_startDate == null || _endDate == null) {
      setState(() {
        _errorMessage = 'Please select both start and end dates';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      // Check if the listing is available for the selected dates
      final isAvailable = await bookingService.isListingAvailable(
        widget.listing.id,
        _startDate!,
        _endDate!,
      );
      
      if (!isAvailable) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'This listing is not available for the selected dates';
        });
        return;
      }
      
      // Create the booking
      final bookingId = await bookingService.createBooking(
        listingId: widget.listing.id,
        ownerUserId: widget.listing.ownerId,
        startDate: _startDate!,
        endDate: _endDate!,
        totalPrice: _totalPrice,
        notes: _notesController.text.trim(),
        listingTitle: widget.listing.title,
        listingImageUrl: widget.listing.imageUrls.isNotEmpty ? widget.listing.imageUrls.first : null,
        notificationService: notificationService,
      );
      
      if (mounted) {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to booking details
        Navigator.pop(context, bookingId);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error creating booking: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Booking'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Listing info card
                    Card(
                      margin: const EdgeInsets.only(bottom: 24),
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
                                child: widget.listing.imageUrls.isNotEmpty
                                    ? Image.network(
                                        widget.listing.imageUrls.first,
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
                            // Listing info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.listing.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.listing.address,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${widget.listing.price.toStringAsFixed(2)} / night',
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
                    ),
                    
                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Date selection
                    const Text(
                      'Select Dates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Start date picker
                    InkWell(
                      onTap: _selectStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Check-in Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _startDate != null
                              ? DateFormat('EEEE, MMM d, y').format(_startDate!)
                              : 'Select start date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // End date picker
                    InkWell(
                      onTap: _selectEndDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Check-out Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _endDate != null
                              ? DateFormat('EEEE, MMM d, y').format(_endDate!)
                              : 'Select end date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Duration and price summary
                    if (_startDate != null && _endDate != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Duration:'),
                                Text(
                                  '${_endDate!.difference(_startDate!).inDays + 1} days',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Price per night:'),
                                Text(
                                  '\$${widget.listing.price.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '\$${_totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Additional notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createBooking,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Request Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'You won\'t be charged until the owner accepts your request',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
