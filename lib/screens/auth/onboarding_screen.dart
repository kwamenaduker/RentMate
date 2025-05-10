import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rent_mate/config/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Find Your Perfect Rental',
      description: 'Browse through a vast collection of rental listings in your local community',
      image: Icons.search,
      color: Colors.blue,
    ),
    OnboardingItem(
      title: 'List Your Property',
      description: 'Easily create and manage your own rental listings with photos and details',
      image: Icons.home,
      color: Colors.green,
    ),
    OnboardingItem(
      title: 'Connect With Owners',
      description: 'Contact property owners directly through calls or messages',
      image: Icons.phone,
      color: Colors.orange,
    ),
    OnboardingItem(
      title: 'Explore Nearby Options',
      description: 'Use the map to discover rentals in your area and find the most convenient location',
      image: Icons.map,
      color: Colors.purple,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markOnboardingComplete() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  void _onNextPressed() {
    if (_currentPage < _onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _markOnboardingComplete();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _onSkipPressed() {
    _markOnboardingComplete();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _onSkipPressed,
                child: const Text('Skip'),
              ),
            ),
            
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingItems.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_onboardingItems[index]);
                },
              ),
            ),
            
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingItems.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _currentPage == _onboardingItems.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with colored background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.image,
              size: 60,
              color: item.color,
            ),
          ),
          const SizedBox(height: 40),
          
          // Title
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            item.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData image;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}
