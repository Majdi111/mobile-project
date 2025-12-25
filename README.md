# Flutter App

A Flutter application with authentication and role-based dashboards for Clients and Providers.

## Features

- **Splash Screen**: Animated logo and app name
- **Welcome Screen**: Photo carousel with onboarding
- **User Type Selection**: Choose between Client or Provider role
- **Authentication**: Sign In and Sign Up functionality
- **Client Dashboard**: Browse services, manage bookings, view providers
- **Provider Dashboard**: Manage services, view bookings and earnings

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode (for mobile development)
- VS Code or Android Studio (recommended IDEs)

### Installation

1. Clone this repository or navigate to the project directory

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── controllers/
│   └── auth_controller.dart       # Authentication state management
└── pages/
    ├── splash_page.dart           # Splash screen
    ├── welcome_page.dart          # Welcome/onboarding screen
    ├── user_type_page.dart        # User role selection
    ├── sign_in_page.dart          # Sign in form
    ├── sign_up_page.dart          # Sign up form
    ├── client_dashboard.dart      # Client home page
    └── provider_dashboard.dart    # Provider home page
```

## Navigation Flow

1. **Splash Page** → Automatically navigates to Welcome Page after 3 seconds
2. **Welcome Page** → User taps "Get Started"
3. **User Type Page** → User selects Client or Provider
4. **Sign In/Sign Up Pages** → User authenticates
5. **Dashboard** → User is directed to role-specific dashboard

## Development

### Running Tests

```bash
flutter test
```

### Building for Production

#### Android
```bash
flutter build apk
```

#### iOS
```bash
flutter build ios
```

## License

This project is licensed under the MIT License.
