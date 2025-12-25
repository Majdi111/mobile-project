# Firebase Setup Guide for Glow App

## ✅ Completed Actions

### 1. **Updated `pubspec.yaml`**
- Added Firebase dependencies:
  - `firebase_core: ^2.24.2`
  - `firebase_auth: ^4.15.3`
  - `cloud_firestore: ^4.13.6`
- ✅ Ran `flutter pub get` successfully

### 2. **Fixed `user_type_page.dart`**
- Changed arguments from String to Map format
- Now passes `{'userType': 'client'}` or `{'userType': 'provider'}`

### 3. **Updated Android Gradle Files**
- Added Google Services plugin to `android/app/build.gradle`
- Added Google Services classpath to `android/build.gradle`

### 4. **Updated Dashboard Files**
- `client_dashboard.dart` - Now fetches user data from Firestore 'clients' collection
- `provider_dashboard.dart` - Now fetches user data from Firestore 'providers' collection
- Added loading states and proper sign-out functionality

### 5. **Created Firebase Configuration Files** (Placeholder)
- `android/app/google-services.json` (⚠️ Uses placeholder data)
- `ios/Runner/GoogleService-Info.plist` (⚠️ Uses placeholder data)

---

## 🔴 CRITICAL: Replace Placeholder Firebase Configuration

The app currently has **placeholder Firebase credentials**. You MUST replace them with your actual Firebase project credentials.

### Steps to Get Real Firebase Configuration:

#### For Android (`google-services.json`):

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Click on the **Android icon** to add an Android app
4. Enter package name: `com.example.flutter_app`
5. Download `google-services.json`
6. Replace the file at: `android/app/google-services.json`

#### For iOS (`GoogleService-Info.plist`):

1. In Firebase Console, click on the **iOS icon** to add an iOS app
2. Enter bundle ID: `com.example.flutter_app`
3. Download `GoogleService-Info.plist`
4. Replace the file at: `ios/Runner/GoogleService-Info.plist`

#### Update `firebase_options.dart`:

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Configure Firebase for your project:
   ```bash
   flutterfire configure
   ```

3. This will automatically update `lib/firebase_options.dart` with real credentials

---

## 📱 Firebase Firestore Database Structure

Your app uses the following Firestore collections:

### **Collection: `clients`**
```
clients/
  ├── {userId}/
      ├── email: string
      ├── full_name: string
      ├── phone_number: string
      ├── gender: string
      ├── date_birth: timestamp
      ├── location: geopoint
      ├── profileImage: string
      └── createdAt: timestamp
```

### **Collection: `providers`**
```
providers/
  ├── {userId}/
      ├── email: string
      ├── full_name: string
      ├── phone_number: string
      ├── gender: string
      ├── date_birth: timestamp
      ├── location: geopoint
      ├── profileImage: string
      ├── bio: string
      ├── rating: number
      ├── totalReviews: number
      ├── isAvailable: boolean
      └── createdAt: timestamp
```

### Firebase Console Setup:

1. Go to **Firebase Console → Firestore Database**
2. Click **Create Database**
3. Choose **Start in test mode** (for development)
4. Set rules temporarily to:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

---

## 🔐 Firebase Authentication Setup

1. Go to **Firebase Console → Authentication**
2. Click **Get Started**
3. Enable **Email/Password** sign-in method
4. (Optional) Enable other sign-in methods as needed

---

## 🚀 Running the App

### 1. Install Dependencies:
```bash
flutter pub get
```

### 2. Run on Android:
```bash
flutter run
```

### 3. Run on iOS:
```bash
cd ios
pod install
cd ..
flutter run
```

### 4. Build for Release:

**Android APK:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

---

## 🧪 Testing the App

### Test Flow:
1. Launch app → Splash screen (3 seconds)
2. Welcome screen → Tap "Get Started"
3. User Type → Select "Client" or "Provider"
4. Sign Up → Enter details and create account
5. Dashboard → User data loads from Firestore

### Test Accounts:
Create test accounts for both user types:
- **Client:** client@test.com / password123
- **Provider:** provider@test.com / password123

---

## ⚠️ Common Issues & Solutions

### Issue: "No Firebase App '[DEFAULT]' has been created"
**Solution:** Make sure `Firebase.initializeApp()` is called in `main.dart` (already done)

### Issue: "google-services.json not found"
**Solution:** Download the actual file from Firebase Console and place it in `android/app/`

### Issue: Build fails on iOS
**Solution:**
```bash
cd ios
pod install --repo-update
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: "User not found in collection"
**Solution:** Make sure the user is signing in with the correct user type (client vs provider)

---

## 📚 Next Steps

1. **Replace placeholder Firebase config files** with real credentials
2. **Test authentication** with both client and provider accounts
3. **Set up proper Firestore security rules** for production
4. **Add additional features:**
   - Profile editing
   - Service listings (providers)
   - Booking system
   - Reviews and ratings
   - Real-time notifications
   - Image upload (Firebase Storage)

---

## 📞 Support

If you encounter issues:
1. Check Firebase Console for errors
2. Review Flutter logs: `flutter logs`
3. Verify Firestore rules allow authenticated access
4. Ensure network connectivity

---

**Last Updated:** December 1, 2025
**Flutter Version:** SDK >= 3.0.0
**Firebase Version:** Core 2.24.2, Auth 4.15.3, Firestore 4.13.6
