import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/screens/home/home_screen.dart';
import 'package:rent_mate/screens/map/map_screen.dart';
import 'package:rent_mate/screens/profile/profile_screen.dart';
import 'package:rent_mate/screens/messages/conversations_screen.dart';
import 'package:rent_mate/screens/bookings/bookings_screen.dart';
import 'package:rent_mate/screens/listings/add_listing_screen.dart';
import 'package:rent_mate/screens/auth/login_screen.dart';
import 'package:rent_mate/services/auth_service.dart';
import 'package:rent_mate/services/message_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  // Navigate to add listing screen
  void _navigateToAddListing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddListingScreen()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get auth service to check if user is logged in for profile tab
    final authService = Provider.of<AuthService>(context);
    
    // List of screens to display - recreated here to ensure we have access to context
    final List<Widget> _screens = [
      const HomeScreen(),
      const MapScreen(),
      authService.isLoggedIn 
        ? const ConversationsScreen() 
        : _buildLoginPrompt(context),
      authService.isLoggedIn 
        ? const BookingsScreen() 
        : _buildLoginPrompt(context),
      authService.isLoggedIn 
        ? const ProfileScreen() 
        : _buildLoginPrompt(context),
    ];
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: (_selectedIndex != 2 && _selectedIndex != 3 && _selectedIndex != 4) // Don't show in messages, bookings or profile screen
          ? FloatingActionButton(
              onPressed: _navigateToAddListing,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if ((index == 2 || index == 3) && !authService.isLoggedIn) {
            // Handle not logged in case
          } else {
            _onItemTapped(index);
          }
        },
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
  
  // Create a login prompt widget for the profile tab when not logged in
  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_circle,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'You need to be logged in to view your profile',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                // Use demo login credentials
                final authService = Provider.of<AuthService>(context, listen: false);
                try {
                  await authService.signInWithEmailAndPassword(
                    email: 'demo@example.com',
                    password: 'password123',
                  );
                  // Note: No need to navigate as the IndexedStack will update
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Use Demo Account'),
            ),
          ],
        ),
      ),
    );
  }
}
