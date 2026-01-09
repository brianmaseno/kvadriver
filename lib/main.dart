import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'data/providers/app_provider.dart';
import 'data/providers/ride_provider.dart';
import 'data/services/driver_location_service.dart';
import 'data/services/websocket_chat_service.dart';
import 'data/widgets/ride_request_popup.dart';
import 'screens/app_wrapper.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/driver_signup_signin_screen.dart';
import 'screens/auth/phone_verification_screen.dart';
import 'screens/auth/vehicle_info_screen.dart';
import 'screens/auth/license_photo_screen.dart';
import 'screens/auth/insurance_photo_screen.dart';
import 'screens/auth/driver_registration_flow.dart';
import 'screens/auth/driver_otp_verify_screen.dart';
import 'screens/setup/vehicle_setup_screen.dart';
import 'screens/setup/vehicle_details_screen.dart';
import 'screens/setup/license_upload_screen.dart';
import 'screens/setup/background_check_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/rides/ride_request_screen.dart';
import 'screens/rides/en_route_pickup_screen.dart';
import 'screens/rides/passenger_pickup_screen.dart';
import 'screens/rides/trip_in_progress_screen.dart';
import 'screens/rides/ride_complete_screen.dart';
import 'screens/rides/ride_chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Initialize notification service
    await NotificationService().initialize();
    print('✅ Notifications initialized successfully');
  } catch (e) {
    print('⚠️ Firebase/Notifications initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
        ChangeNotifierProvider(create: (_) => DriverLocationService()),
        ChangeNotifierProvider(create: (_) => WebSocketChatService()),
      ],
      child: MaterialApp(
        title: 'KVA Driver',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          textTheme: GoogleFonts.geologicaTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: AppBarTheme(
            titleTextStyle: GoogleFonts.geologica(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        initialRoute: '/',
        builder: (context, child) {
          // Wrap with RideRequestPopup for global overlay
          return RideRequestPopup(child: child ?? const SizedBox());
        },
        routes: {
          '/': (context) => const AppWrapper(),
          '/splash': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/auth': (context) => const DriverSignUpSignInScreen(),
          '/phone-verification': (context) => const PhoneVerificationScreen(),
          '/vehicle-info': (context) => const VehicleInfoScreen(),
          '/background-check': (context) => const BackgroundCheckScreen(),
          '/license-photo': (context) => const LicensePhotoScreen(),
          '/insurance-photo': (context) => const InsurancePhotoScreen(),
          '/driver-registration': (context) => const DriverRegistrationFlow(),
          '/driver-otp-verify': (context) => const DriverOtpVerifyScreen(),
          '/vehicle-setup': (context) => const VehicleSetupScreen(),
          '/vehicle-details': (context) => const VehicleDetailsScreen(),
          '/license-upload': (context) => const LicenseUploadScreen(),
          '/home': (context) => const HomeScreen(),
          '/ride-request': (context) => const RideRequestScreen(),
          '/en-route-pickup': (context) => const EnRoutePickupScreen(),
          '/passenger-pickup': (context) => const PassengerPickupScreen(),
          '/trip-in-progress': (context) => const TripInProgressScreen(),
          '/ride-complete': (context) => const RideCompleteScreen(),
        },
      ),
    );
  }
}
