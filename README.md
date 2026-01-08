# KVA Driver App

A Flutter-based mobile application for KVA ride-sharing drivers.

## Features

- **Authentication Flow**: Login, registration, and phone verification
- **Driver Onboarding**: Vehicle setup, document upload, and background check
- **Home Dashboard**: Map view with online/offline toggle
- **Earnings Tracking**: Daily, weekly, and monthly earnings overview
- **Trip History**: Complete ride history with details
- **Profile Management**: Driver profile and account settings
- **Support System**: Help center and customer support

## Project Structure

```
kva_driver_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── data/
│   │   ├── models/
│   │   │   └── models.dart         # Data models (Driver, Vehicle, Ride)
│   │   └── providers/
│   │       └── app_provider.dart   # State management
│   └── screens/
│       ├── splash_screen.dart      # App splash screen
│       ├── onboarding/
│       │   └── onboarding_screen.dart
│       ├── auth/                   # Authentication screens
│       │   ├── login_screen.dart
│       │   ├── register_screen.dart
│       │   └── phone_verification_screen.dart
│       ├── setup/                  # Driver setup screens
│       │   ├── vehicle_setup_screen.dart
│       │   ├── vehicle_details_screen.dart
│       │   ├── license_upload_screen.dart
│       │   └── background_check_screen.dart
│       ├── home/                   # Main app screens
│       │   ├── home_screen.dart
│       │   ├── map_view.dart
│       │   ├── earnings_screen.dart
│       │   ├── history_screen.dart
│       │   └── profile_screen.dart
│       ├── rides/                  # Ride-related screens
│       │   ├── ride_details_screen.dart
│       │   ├── ride_complete_screen.dart
│       │   └── pickup_navigation_screen.dart
│       ├── profile/
│       │   └── account_screen.dart
│       └── support/
│           └── get_help_screen.dart
├── pubspec.yaml
└── README.md
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Android Studio or VS Code
- Android/iOS device or emulator

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd KVA-Frontend-System/kva_driver_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Dependencies

- **flutter**: Flutter SDK
- **provider**: State management
- **cupertino_icons**: iOS-style icons

## App Flow

1. **Splash Screen** → **Onboarding** → **Authentication**
2. **Login/Register** → **Phone Verification** → **Driver Setup**
3. **Vehicle Setup** → **Document Upload** → **Background Check**
4. **Home Dashboard** with bottom navigation:
   - Map View (online/offline toggle)
   - Earnings (daily/weekly/monthly stats)
   - History (trip history)
   - Profile (account settings)

## Key Features

### Authentication
- Email/phone login
- Registration with personal details
- OTP verification with custom keypad

### Driver Onboarding
- Vehicle information setup
- License and insurance upload
- Background check process

### Main Dashboard
- Interactive map view
- Online/offline status toggle
- Real-time ride requests
- Navigation to pickup/destination

### Earnings & History
- Detailed earnings breakdown
- Trip history with filters
- Performance metrics

### Profile & Support
- Account management
- Vehicle information
- Help center and support

## Development

### Code Structure
- **Models**: Data structures for Driver, Vehicle, and Ride
- **Providers**: State management using Provider pattern
- **Screens**: UI components organized by feature
- **Navigation**: Named routes for screen transitions

### State Management
The app uses Provider for state management with `AppProvider` handling:
- User authentication state
- Driver online/offline status
- Ride history and earnings data

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is part of the KVA ride-sharing platform.