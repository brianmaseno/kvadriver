import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/providers/app_provider.dart';
import 'splash_screen.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final appProvider = context.read<AppProvider>();
    await appProvider.initializeAuth();

    if (!mounted) return;

    // Check if user has completed onboarding before
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('driver_first_time_user') == false;

    if (appProvider.isAuthenticated && appProvider.currentUserId != null) {
      final hasCompletedRegistration =
          await appProvider.hasCompletedDriverRegistration();
      final route = hasCompletedRegistration ? '/home' : '/vehicle-info';
      Navigator.pushReplacementNamed(context, route);
    } else if (!hasSeenOnboarding) {
      // First time user - show onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      // Returning user but not authenticated - go to auth screen
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
