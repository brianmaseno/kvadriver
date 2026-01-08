import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/providers/ride_provider.dart';
import '../../data/models/models.dart';
import '../../data/services/chat_call_service.dart';

class PassengerPickupScreen extends StatefulWidget {
  const PassengerPickupScreen({super.key});

  @override
  State<PassengerPickupScreen> createState() => _PassengerPickupScreenState();
}

class _PassengerPickupScreenState extends State<PassengerPickupScreen> {
  String? _rideId;
  Ride? _ride;

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
    setState(() => _ride = rideProvider.currentRide);
  }

  Future<void> _startTrip() async {
    if (_rideId == null) return;
    Navigator.pushReplacementNamed(context, '/trip-in-progress', arguments: {'rideId': _rideId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(center: LatLng(_ride?.pickupLat ?? -1.2864, _ride?.pickupLng ?? 36.8172), zoom: 16.0),
            children: [
              TileLayer(urlTemplate: 'https://tiles.locationiq.com/v3/streets/r/{z}/{x}/{y}.png?key=pk.48e2dedac41ff32af8621c2414ee25e8', userAgentPackageName: 'com.kva.driver'),
              MarkerLayer(markers: [
                if (_ride?.pickupLat != null && _ride?.pickupLng != null)
                  Marker(point: LatLng(_ride!.pickupLat!, _ride!.pickupLng!), child: const Icon(Icons.location_on, color: Colors.green, size: 40)),
              ]),
            ],
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
              ),
            ),
          ),

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(20)), child: Text('Arrived at pickup', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600))),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const CircleAvatar(radius: 30, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white, size: 30)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_ride?.rider?.fullName ?? 'Passenger', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text('Passenger', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async => _rideId != null ? await ChatCallService.initiateCall(context: context, rideId: int.parse(_rideId!)) : null,
                            icon: const Icon(Icons.phone, color: Color(0xFF0066CC)),
                          ),
                          IconButton(
                            onPressed: () async => _rideId != null ? await ChatCallService.openChat(context: context, rideId: int.parse(_rideId!), passengerName: _ride?.rider?.fullName ?? "Passenger") : null,
                            icon: const Icon(Icons.message, color: Color(0xFF0066CC)),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      Row(children: [const Icon(Icons.radio_button_checked, color: Colors.green, size: 16), const SizedBox(width: 8), Expanded(child: Text(_ride?.pickupAddress ?? 'Pickup Location', style: const TextStyle(fontWeight: FontWeight.w500)))]),
                      const SizedBox(height: 12),
                      Row(children: [const Icon(Icons.location_on, color: Colors.red, size: 16), const SizedBox(width: 8), Expanded(child: Text(_ride?.dropoffAddress ?? 'Dropoff Location', style: const TextStyle(fontWeight: FontWeight.w500)))]),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => _showWaitingDialog(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Wait (2 min free)'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(onPressed: _startTrip, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066CC), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Start Trip', style: TextStyle(color: Colors.white)))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWaitingDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Waiting for passenger'), content: const Text('You can wait up to 2 minutes for free. After that, waiting charges may apply.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  }
}