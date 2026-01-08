import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/providers/app_provider.dart';
import '../data/services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  _navigateToNextScreen() async {
    // Wait for minimum splash time
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if this is first time user
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('driver_first_time_user') ?? true;

    if (isFirstTime) {
      // First time user, show onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    final appProvider = context.read<AppProvider>();

    // Initialize authentication state from stored data
    await appProvider.initializeAuth();

    if (appProvider.isAuthenticated && appProvider.currentUserId != null) {
      // User is authenticated, check if driver registration is complete
      final hasCompletedRegistration =
          await appProvider.hasCompletedDriverRegistration();

      if (hasCompletedRegistration) {
        // Driver registration complete, go to home
        Navigator.pushReplacementNamed(context, '/home');
        return;
      } else {
        // Driver registration not complete, go to vehicle info
        Navigator.pushReplacementNamed(context, '/vehicle-info');
        return;
      }
    }

    // No valid authentication, go to auth screen
    Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0066CC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_taxi,
                size: 60,
                color: Color(0xFF0066CC),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'KVA Driver',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
