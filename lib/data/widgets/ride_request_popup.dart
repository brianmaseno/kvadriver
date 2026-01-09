import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/driver_location_service.dart';

/// Global overlay widget to show ride request popup anywhere in the app
class RideRequestPopup extends StatefulWidget {
  final Widget child;

  const RideRequestPopup({super.key, required this.child});

  @override
  State<RideRequestPopup> createState() => _RideRequestPopupState();
}

class _RideRequestPopupState extends State<RideRequestPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDeclineTimer;
  int _remainingSeconds = 30; // 30 seconds to respond

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoDeclineTimer?.cancel();
    super.dispose();
  }

  void _startAutoDeclineTimer(
      DriverLocationService locationService, Map<String, dynamic> request) {
    _autoDeclineTimer?.cancel();
    _remainingSeconds = 30;

    _autoDeclineTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        // Auto decline
        locationService.denyRide(
          request['id'].toString(),
          reason: 'Auto declined - no response',
        );
      }
    });
  }

  void _stopAutoDeclineTimer() {
    _autoDeclineTimer?.cancel();
    _autoDeclineTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverLocationService>(
      builder: (context, locationService, _) {
        final request = locationService.urgentRideRequest;

        if (request != null && locationService.isOnline) {
          // Start animation and timer
          if (!_animationController.isAnimating &&
              _animationController.status != AnimationStatus.completed) {
            _animationController.forward();
            _startAutoDeclineTimer(locationService, request);
          }
        } else {
          // Hide and reset
          if (_animationController.status == AnimationStatus.completed) {
            _animationController.reverse();
            _stopAutoDeclineTimer();
          }
        }

        return Stack(
          children: [
            widget.child,

            // Popup overlay
            if (request != null && locationService.isOnline)
              Positioned.fill(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap through
                    child: Container(
                      color: Colors.black54,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildRideRequestCard(
                              context,
                              locationService,
                              request,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRideRequestCard(
    BuildContext context,
    DriverLocationService locationService,
    Map<String, dynamic> request,
  ) {
    final rider = request['rider'] as Map<String, dynamic>?;
    final fare = request['estimatedFare'] ?? 0;
    final distance = request['distance'] ?? 0;
    final pickupDistance =
        request['pickupDistance'] ?? request['pickupDistanceMeters'] ?? 0;
    final pickupMinutes = request['estimatedPickupMinutes'] ?? 0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with timer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0066CC), Color(0xFF0052A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_car,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'New Ride Request',
                    style: GoogleFonts.geologica(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Timer countdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _remainingSeconds <= 10
                        ? Colors.red
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: _remainingSeconds <= 10
                            ? Colors.white
                            : Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_remainingSeconds}s',
                        style: GoogleFonts.geologica(
                          color: _remainingSeconds <= 10
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Fare and distance highlight
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn(
                  '\$${(fare is num ? fare : double.tryParse(fare.toString()) ?? 0).toStringAsFixed(2)}',
                  'Estimated Fare',
                  Icons.attach_money,
                  Colors.green,
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                _buildInfoColumn(
                  '${(distance is num ? distance : double.tryParse(distance.toString()) ?? 0).toStringAsFixed(1)} km',
                  'Trip Distance',
                  Icons.route,
                  Colors.blue,
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                _buildInfoColumn(
                  '$pickupMinutes min',
                  'To Pickup',
                  Icons.access_time,
                  Colors.orange,
                ),
              ],
            ),
          ),

          // Rider info and locations
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Rider info with contact
                if (rider != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            rider['firstName']
                                    ?.toString()
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                'R',
                            style: GoogleFonts.geologica(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${rider['firstName'] ?? ''} ${rider['lastName'] ?? ''}'
                                    .trim(),
                                style: GoogleFonts.geologica(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.phone,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    rider['phoneNumber'] ?? 'No phone',
                                    style: GoogleFonts.geologica(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Call button
                        if (rider['phoneNumber'] != null)
                          GestureDetector(
                            onTap: () async {
                              final phone = rider['phoneNumber'];
                              final uri = Uri.parse('tel:$phone');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.phone,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Pickup location
                _buildLocationRow(
                  icon: Icons.radio_button_checked,
                  iconColor: Colors.green,
                  title: 'Pickup',
                  address: request['pickupAddress'] ?? 'Pickup Location',
                ),

                // Dotted line
                Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: Column(
                    children: List.generate(
                        3,
                        (index) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              width: 2,
                              height: 4,
                              color: Colors.grey.shade400,
                            )),
                  ),
                ),

                // Dropoff location
                _buildLocationRow(
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  title: 'Dropoff',
                  address: request['dropoffAddress'] ?? 'Dropoff Location',
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Decline button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      _stopAutoDeclineTimer();
                      await locationService.denyRide(
                        request['id'].toString(),
                        reason: 'Driver declined',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'DECLINE',
                      style: GoogleFonts.geologica(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Accept button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      _stopAutoDeclineTimer();
                      final response = await locationService.acceptRide(
                        request['id'].toString(),
                      );

                      if (response['success'] == true && mounted) {
                        // Navigate to ride screen
                        Navigator.pushNamed(
                          context,
                          '/en-route-pickup',
                          arguments: {'rideId': request['id'].toString()},
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      'ACCEPT RIDE',
                      style: GoogleFonts.geologica(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.geologica(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.geologica(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.geologica(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              Text(
                address,
                style: GoogleFonts.geologica(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
