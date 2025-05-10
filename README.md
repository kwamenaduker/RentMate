# RentMate: A Mobile Platform for Community-Based Rental Management

RentMate is a cross-platform mobile application built with Flutter that enables users to list, search, and manage rental properties in a localized community setting. The app streamlines the informal rental ecosystem by supporting CRUD operations on rental listings, offering a comprehensive booking system, and integrating multiple native device features and external APIs.

## Features

- **User Authentication**: Secure email/password login and registration
- **Listing Management**: Create, read, update, and delete rental listings
- **Booking System**: Complete booking lifecycle management (request, confirm, cancel, complete)
- **Messaging System**: In-app messaging between property owners and renters
- **Weather Forecasting**: Integration with WeatherAPI.com to show weather forecasts for booking dates
- **Image Handling**: Upload and view multiple images for each listing
- **Location Services**: Geolocation for finding nearby properties
- **Communication**: Direct call integration for contacting property owners
- **Offline Access**: Browse cached listings without internet connection
- **User Profiles**: Manage personal information and track listings

## Device & API Features

- **Camera**: Upload pictures of rental properties or items
- **GPS/Geolocation**: Show nearby listings and location-based search
- **Phone Call**: Call listing owners directly from the app
- **Push Notifications**: Receive alerts for booking updates and messages
- **Offline Storage**: Cache listings for offline browsing
- **External API Integration**: WeatherAPI.com for booking date weather forecasts

## Project Structure

```
lib/
├── config/        # App configuration and theme
├── models/        # Data models
├── screens/       # UI screens
│   ├── auth/      # Authentication screens
│   ├── home/      # Home and dashboard
│   ├── listings/  # Listing management
│   ├── bookings/  # Booking management
│   ├── messages/  # Messaging system
│   ├── profile/   # User profile
│   └── map/       # Map views
├── services/      # Backend services
│   ├── auth_service.dart      # Authentication logic
│   ├── listing_service.dart   # Listing management
│   ├── booking_service.dart   # Booking operations
│   ├── message_service.dart   # Messaging functionality
│   ├── user_service.dart      # User data management
│   ├── weather_service.dart   # Weather API integration
│   └── notification_service.dart # Push notifications
├── utils/         # Utility functions
└── widgets/       # Reusable UI components
```

## Setup Instructions

### Prerequisites

- Flutter SDK (^3.7.0)
- Dart SDK (^3.0.0)
- Firebase account
- WeatherAPI.com API key (for weather forecast functionality)

### Getting Started

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/rent_mate.git
   ```

2. Navigate to the project directory:
   ```
   cd rent_mate
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Set up Firebase:
   - Create a new Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and replace the Firebase configuration files

5. Update the `firebase_options.dart` file with your Firebase credentials

6. Run the app:
   ```
   flutter run
   ```

## External Services Setup

### Firebase Setup

RentMate uses Firebase for:
- Authentication
- Cloud Firestore (database)
- Firebase Storage (image storage)
- Cloud Messaging (for notifications)

Follow these steps to connect your app with Firebase:

1. Create a Firebase project at [firebase.google.com](https://firebase.google.com)
2. Add Android and iOS apps to your project
3. Download the configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
4. Place these files in the appropriate directories
5. Update `firebase_options.dart` with your project credentials

### WeatherAPI Setup

The weather forecast feature requires a WeatherAPI.com account:

1. Create an account at [weatherapi.com](https://www.weatherapi.com)
2. Generate an API key
3. Replace the placeholder API key in `lib/services/weather_service.dart` with your key

## Documentation

The `/documentation` directory contains detailed information about the project:

- `case_scenario.md`: Project background and requirements
- `architecture_design.md`: Application architecture and design details
- `implementation.md`: Implementation details and technology choices
- `video_demo_script.md`: Script for the demonstration video

## Submission Materials

This project is submitted as part of a mobile application development assignment with the following components:

1. **Source Code**: The full RentMate application codebase
2. **Documentation**: Comprehensive documentation in the `/documentation` directory
3. **APK**: Android application package for installation
4. **Demo Video**: YouTube video demonstrating all features (link in submission report)

## Acknowledgements

- Flutter team for the amazing framework
- Firebase for backend services
- WeatherAPI.com for weather forecast data
- All contributors who have helped improve this project
