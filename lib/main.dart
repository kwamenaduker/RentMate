import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/config/firebase_options.dart';
import 'package:rent_mate/screens/auth/login_screen.dart';
import 'package:rent_mate/screens/auth/onboarding_screen.dart';
import 'package:rent_mate/screens/auth/signup_screen.dart';
import 'package:rent_mate/screens/main_screen.dart';
import 'package:rent_mate/screens/splash_screen.dart';
import 'package:rent_mate/screens/listings/add_listing_screen.dart';
import 'package:rent_mate/screens/messages/conversations_screen.dart';
import 'package:rent_mate/screens/notifications/notifications_screen.dart';
import 'package:rent_mate/screens/bookings/bookings_screen.dart';
import 'package:rent_mate/screens/admin/data_generator_screen.dart';
import 'package:rent_mate/services/auth_service.dart';
import 'package:rent_mate/services/listing_service.dart';
import 'package:rent_mate/services/location_service.dart';
import 'package:rent_mate/services/message_service.dart';
import 'package:rent_mate/services/notification_service.dart';
import 'package:rent_mate/services/booking_service.dart';
import 'package:rent_mate/services/user_service.dart';
import 'package:rent_mate/services/weather_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable debug logging for Firebase
  if (kDebugMode) {
    FirebaseFirestore.instance.settings = 
        const Settings(persistenceEnabled: true);
        
    print('Firebase initialized successfully');
    print('Current Firebase auth user: ${FirebaseAuth.instance.currentUser?.uid ?? "Not logged in"}');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        Provider<ListingService>(
          create: (_) => ListingService(),
        ),
        Provider<LocationService>(
          create: (_) => LocationService(),
        ),
        ChangeNotifierProvider<MessageService>(
          create: (_) => MessageService(),
        ),
        ChangeNotifierProvider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        ChangeNotifierProvider<BookingService>(
          create: (_) => BookingService(),
        ),
        ChangeNotifierProvider<UserService>(
          create: (_) => UserService(),
        ),
        Provider<WeatherService>(
          create: (_) => WeatherService(),
        ),
      ],
      child: MaterialApp(
        title: 'RentMate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const MainScreen(),
          '/add_listing': (context) => const AddListingScreen(),
          '/messages': (context) => const ConversationsScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/bookings': (context) => const BookingsScreen(),
          '/admin/data_generator': (context) => const DataGeneratorScreen(),
        },
      ),
    );
  }
}
