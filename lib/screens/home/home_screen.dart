import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/providers/app_provider.dart';
import '../../data/providers/ride_provider.dart';
import 'map_view.dart';
import 'earnings_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Check for active rides on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForActiveRides();
    });
  }

  Future<void> _checkForActiveRides() async {
    final rideProvider = context.read<RideProvider>();
    // Check if there's an ongoing ride
    await rideProvider.getUserRides(status: 'accepted');

    final activeRides = rideProvider.userRides
        .where((ride) =>
            ride.status == 'accepted' ||
            ride.status == 'driver_arrived' ||
            ride.status == 'in_progress')
        .toList();

    if (activeRides.isNotEmpty && mounted) {
      final activeRide = activeRides.first;
      // Navigate to appropriate screen based on ride status
      if (activeRide.status == 'accepted') {
        Navigator.pushNamed(context, '/en-route-pickup',
            arguments: {'rideId': activeRide.id});
      } else if (activeRide.status == 'driver_arrived') {
        Navigator.pushNamed(context, '/passenger-pickup',
            arguments: {'rideId': activeRide.id});
      } else if (activeRide.status == 'in_progress') {
        Navigator.pushNamed(context, '/trip-in-progress',
            arguments: {'rideId': activeRide.id});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const Home(),
      const HistoryScreen(),
      const EarningsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF0066CC),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          selectedLabelStyle: GoogleFonts.geologica(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.geologica(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
