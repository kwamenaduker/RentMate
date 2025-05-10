# RentMate: Architecture & Design

## Application Overview

RentMate is a Flutter-based mobile application that provides a platform for property rental management. The application follows a client-server architecture, with a Flutter mobile client and Firebase as the backend service. The app enables property owners to list their properties and renters to find and book accommodations, with a robust messaging system for communication between parties.

## High-Level Architecture

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Flutter Mobile App                          │
│                                                                     │
│  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐       │
│  │    UI Layer   │    │  Service Layer│    │  Model Layer  │       │
│  │               │    │               │    │               │       │
│  │ - Screens     │    │ - Auth        │    │ - User        │       │
│  │ - Widgets     │◄──►│ - Listing     │◄──►│ - Listing     │       │
│  │ - Navigation  │    │ - Booking     │    │ - Booking     │       │
│  │ - Themes      │    │ - Message     │    │ - Message     │       │
│  │               │    │ - Weather     │    │ - Conversation│       │
│  └───────────────┘    └───────────────┘    └───────────────┘       │
│                              ▲                                      │
└──────────────────────────────│──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        External Services                            │
│                                                                     │
│  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐       │
│  │   Firebase    │    │  WeatherAPI   │    │ Device APIs   │       │
│  │               │    │               │    │               │       │
│  │ - Auth        │    │ - Current     │    │ - Camera      │       │
│  │ - Firestore   │    │   Weather     │    │ - Location    │       │
│  │ - Storage     │    │ - Forecast    │    │ - Phone       │       │
│  │ - Messaging   │    │               │    │ - Storage     │       │
│  └───────────────┘    └───────────────┘    └───────────────┘       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Modules & Layers

#### UI Layer
- **Screens**: All application screens organized by feature (auth, listings, bookings, messages)
- **Widgets**: Reusable components like cards, buttons, forms
- **Navigation**: App routing and navigation management
- **Themes**: App-wide styling and theming

#### Service Layer
- **AuthService**: User authentication and account management
- **ListingService**: Property listing CRUD operations
- **BookingService**: Booking creation and management
- **MessageService**: Messaging system operations
- **UserService**: User data and profile management
- **WeatherService**: Integration with external weather API

#### Model Layer
- **UserModel**: User data representation
- **ListingModel**: Property listing data representation
- **BookingModel**: Booking data representation
- **MessageModel**: Message data representation
- **ConversationModel**: Conversation thread representation

#### External Services
- **Firebase**: Backend services for authentication, database, and storage
- **WeatherAPI.com**: External API for weather forecasts
- **Device APIs**: Native device features (camera, location, phone)

## Communication Flow

1. **User Authentication Flow**:
   ```
   User → UI → AuthService → Firebase Auth → UserService → Firestore → App State → UI
   ```

2. **Property Listing Flow**:
   ```
   Owner → UI → ListingService → Firestore/Storage → App State → UI
   ```

3. **Booking Flow**:
   ```
   Renter → UI → BookingService → Firestore → NotificationService → App State → UI
   ```

4. **Messaging Flow**:
   ```
   User A → UI → MessageService → Firestore → NotificationService → User B
   ```

5. **Weather API Flow**:
   ```
   UI → WeatherService → WeatherAPI.com → Data Processing → UI
   ```

## User Identification & Use Cases

### User Types
1. **Property Owners**: Users who list properties for rent
2. **Renters**: Users who search for and book properties
3. **Administrators**: System administrators (future implementation)

### Use Case Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                         RentMate System                        │
│                                                                │
│  ┌──────────────┐                       ┌──────────────┐       │
│  │              │                       │              │       │
│  │   Property   │                       │    Renter    │       │
│  │    Owner     │                       │              │       │
│  │              │                       │              │       │
│  └──────┬───────┘                       └──────┬───────┘       │
│         │                                      │               │
│         │    ┌───────────────────────┐         │               │
│         └───►│  Manage Account       │◄────────┘               │
│              └───────────────────────┘                         │
│                                                                │
│         ┌────►┌───────────────────────┐                        │
│         │     │  Manage Listings      │                        │
│         │     └───────────────────────┘                        │
│         │                                                      │
│         │     ┌───────────────────────┐         ┌─────────┐    │
│         ├────►│  Manage Bookings      │◄────────┤         │    │
│         │     └───────────────────────┘         │         │    │
│  ┌──────┴───┐                                   │         │    │
│  │          │  ┌───────────────────────┐        │         │    │
│  │ Property │  │  Search Properties    │◄────────┘         │    │
│  │  Owner   │  └───────────────────────┘                   │    │
│  │          │                                              │    │
│  │          │  ┌───────────────────────┐                   │    │
│  │          ├─►│  Message Users        │◄──────────────────┤    │
│  └──────────┘  └───────────────────────┘                   │    │
│                                                            │    │
│                ┌───────────────────────┐                   │    │
│                │  Make Phone Calls     │◄──────────────────┤    │
│                └───────────────────────┘                   │    │
│                                                            │    │
│                ┌───────────────────────┐                   │    │
│                │  Check Weather        │◄──────────────────┘    │
│                └───────────────────────┘                        │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Key Use Cases

### Property Owner
1. **Create Listing**: Add new property with photos, details, pricing
2. **Manage Bookings**: Accept, reject, or cancel booking requests
3. **Message Renters**: Communicate with potential or current renters
4. **View Booking Calendar**: See all bookings for properties
5. **Update Listing Availability**: Mark dates as available/unavailable

### Renter
1. **Search Properties**: Find properties by location, price, amenities
2. **View Property Details**: See photos, descriptions, amenities, reviews
3. **Request Booking**: Submit booking requests for desired dates
4. **Message Owners**: Communicate with property owners
5. **View Booking History**: Track current and past bookings
6. **Check Weather Forecast**: View weather predictions for booking dates

## Database Schema

### Entity Relationship Diagram

```
┌───────────────┐      ┌────────────────┐       ┌───────────────┐
│     User      │      │    Listing     │       │    Booking    │
├───────────────┤      ├────────────────┤       ├───────────────┤
│ id            │◄─┐   │ id             │    ┌─►│ id            │
│ name          │  │   │ title          │    │  │ listingId     │
│ email         │  │   │ description    │    │  │ ownerUserId   │
│ phoneNumber   │  ├───┤ ownerId        │    │  │ renterUserId  │
│ createdAt     │  │   │ ownerName      │    │  │ startDate     │
│ photoUrl      │  │   │ price          │    │  │ endDate       │
│ favoriteList..│  │   │ location       │    │  │ totalPrice    │
└───────────────┘  │   │ address        │◄───┘  │ status        │
                   │   │ imageUrls      │       │ createdAt     │
                   │   │ amenities      │       └───────────────┘
                   │   │ category       │               ▲
                   │   │ isAvailable    │               │
                   │   └────────────────┘               │
                   │                                    │
┌───────────────┐  │   ┌────────────────┐               │
│ Conversation  │  │   │    Message     │               │
├───────────────┤  │   ├────────────────┤               │
│ id            │  │   │ id             │               │
│ participants  │◄─┘   │ conversationId │               │
│ lastMessage   │      │ senderId       │               │
│ lastMessageT..│      │ content        │               │
│ createdAt     │      │ timestamp      │               │
│ listingId     │◄─────┤ listingId      │               │
│ bookingId     │◄─────┤ bookingId      │───────────────┘
└───────────────┘      └────────────────┘
```

## UI Prototype

The RentMate application follows Material Design principles with a clean, intuitive interface. Key screens include:

1. **Authentication Screens**: Login, signup, and password recovery
2. **Home Screen**: Property discovery with search and filtering
3. **Listing Details**: Detailed property information with booking option
4. **Booking Screens**: Booking creation, management, and history
5. **Messaging**: Conversation list and chat interface
6. **Profile Management**: User profile and account settings

The application uses a consistent color scheme based on green as the primary color, representing growth and community, with blue accents for interactive elements. Typography is clean and readable across all screens.

The actual application implementation closely follows the prototype design, with adjustments made for optimal user experience based on testing feedback.

## Technology Choices

### Frontend
- **Framework**: Flutter for cross-platform development
- **State Management**: Provider pattern for reactive state management
- **UI Components**: Material Design with custom styling
- **Navigation**: Named routes with arguments passing

### Backend
- **Authentication**: Firebase Authentication
- **Database**: Cloud Firestore for NoSQL document storage
- **Storage**: Firebase Storage for media files
- **Push Notifications**: Firebase Cloud Messaging

### External APIs
- **Weather**: WeatherAPI.com for forecast data
- **Maps**: Google Maps for location services
- **Phone**: URL Launcher for phone call integration

These architecture and design decisions ensure a scalable, maintainable application that can evolve with changing business requirements while providing a seamless user experience across devices.
