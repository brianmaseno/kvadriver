import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/ride_provider.dart';
import '../../data/models/models.dart';
import '../../widgets/rating_popup.dart';

class RideCompleteScreen extends StatefulWidget {
  const RideCompleteScreen({super.key});

  @override
  State<RideCompleteScreen> createState() => _RideCompleteScreenState();
}

class _RideCompleteScreenState extends State<RideCompleteScreen> {
  String? _rideId;
  Ride? _ride;
  bool _hasRated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['rideId'] != null) {
        _rideId = args['rideId'];
        _loadRideDetails();
      }
    });
  }

  Future<void> _loadRideDetails() async {
    if (_rideId == null) return;
    final rideProvider = context.read<RideProvider>();
    await rideProvider.getRideById(_rideId!);
    setState(() {
      _ride = rideProvider.currentRide;
    });
  }

  Future<void> _ratePassenger() async {
    if (_rideId == null) return;

    final rated = await RatingPopup.show(
      context,
      rideId: int.parse(_rideId!),
      partnerName: _ride?.rider?.fullName ?? 'Passenger',
      isDriver: true,
    );

    if (rated == true) {
      setState(() => _hasRated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 60,
                  color: Colors.green,
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Trip Completed!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'You have successfully completed the trip.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Trip summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Trip Fare'),
                        Text(
                          '\$${_ride?.finalFare?.toStringAsFixed(2) ?? _ride?.fare?.toStringAsFixed(2) ?? '24.50'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Distance'),
                        Text('${_ride?.distance ?? '12.5'} km'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duration'),
                        const Text('25 min'), // TODO: Calculate actual duration
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Earnings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${(_ride?.finalFare ?? _ride?.fare ?? 24.50) * 0.8}', // Assuming 80% goes to driver
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066CC),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Rate Passenger button
              if (!_hasRated)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _ratePassenger,
                    icon: const Icon(Icons.star_outline, color: Color(0xFF0066CC)),
                    label: const Text(
                      'Rate Passenger',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0066CC),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0066CC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              
              if (!_hasRated) const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue Driving',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}