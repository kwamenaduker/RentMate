# Firebase Setup Guide for RentMate

This guide walks you through the steps to set up Firebase for the RentMate app.

## Prerequisites

- A Google account
- Flutter SDK installed
- Firebase CLI installed (optional but recommended)

## Step 1: Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the prompts to create a new project named "RentMate"
3. Enable Google Analytics if desired (recommended)

## Step 2: Register Your App with Firebase

### For Android:

1. In the Firebase Console, click on the Android icon to add an Android app
2. Enter the package name: `com.rentmate.rent_mate`
3. Enter a nickname (optional, e.g., "RentMate Android")
4. Enter the SHA-1 hash of your debug key (needed for Google Sign-In, optional for now)
5. Click "Register app"
6. Download the `google-services.json` file
7. Replace the existing file at `android/app/google-services.json` with the downloaded file

### For iOS (if applicable):

1. In the Firebase Console, click on the iOS icon to add an iOS app
2. Enter the Bundle ID: `com.rentmate.rent_mate`
3. Enter a nickname (optional, e.g., "RentMate iOS")
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Place it in the `ios/Runner` directory of your project

## Step 3: Set Up Firebase Authentication

1. In the Firebase Console, go to "Authentication"
2. Click "Get started"
3. Enable the "Email/Password" sign-in method
4. (Optional) Enable other sign-in methods as needed (Google, Facebook, etc.)

## Step 4: Set Up Firestore Database

1. In the Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose either "Start in production mode" or "Start in test mode" (for development)
4. Select a location for your database that's closest to your target users
5. After the database is created, go to the "Rules" tab
6. Replace the default rules with the contents of `firestore.rules` in your project
7. Click "Publish"

## Step 5: Set Up Firebase Storage

1. In the Firebase Console, go to "Storage"
2. Click "Get started"
3. Choose either "Start in production mode" or "Start in test mode" (for development)
4. Select a location for your storage bucket that's closest to your target users
5. After the storage bucket is created, go to the "Rules" tab
6. Replace the default rules with the contents of `storage.rules` in your project
7. Click "Publish"

## Step 6: Update Firebase Configuration in the App

1. Open `lib/config/firebase_options.dart`
2. Replace the demo values with the actual values from your Firebase project
   - You can get these values from the Firebase Console > Project settings > Your apps

## Step 7: Deploy Rules (Optional, using Firebase CLI)

If you have the Firebase CLI installed, you can deploy your Firestore and Storage rules with the following commands:

```bash
# Login to Firebase
firebase login

# Initialize Firebase in your project (if not already done)
firebase init

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage:rules
```

## Testing Your Firebase Integration

1. Run the app in debug mode
2. Try to register a new user
3. Verify that the user is created in Firebase Authentication
4. Verify that a document for the user is created in Firestore
5. Try to create a listing with images
6. Verify that the listing is stored in Firestore and the images are uploaded to Storage

## Troubleshooting

- If you encounter issues with Firebase initialization, make sure the configuration files are correctly placed and formatted
- For authentication issues, check if the email/password authentication method is enabled in the Firebase Console
- For Firestore and Storage issues, verify that your security rules are not too restrictive for your use case
