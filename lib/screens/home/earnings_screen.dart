import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/providers/app_provider.dart';
import '../../data/providers/ride_provider.dart';
import '../../data/services/api_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  bool _isLoading = true;
  double _todayEarnings = 0;
  double _weekEarnings = 0;
  double _monthEarnings = 0;
  int _todayTrips = 0;
  int _weekTrips = 0;
  int _monthTrips = 0;
  List<Map<String, dynamic>> _recentTrips = [];

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);

    try {
      final rideProvider = context.read<RideProvider>();

      // Get completed rides
      await rideProvider.getUserRides(status: 'completed');
      final completedRides = rideProvider.userRides;

      // Calculate earnings
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      double todayTotal = 0;
      double weekTotal = 0;
      double monthTotal = 0;
      int todayCount = 0;
      int weekCount = 0;
      int monthCount = 0;
      List<Map<String, dynamic>> recent = [];

      for (var ride in completedRides) {
        final createdAt = ride.createdAt ?? now;
        final fare = ride.fare ?? 0;

        // Driver typically gets 80% of fare
        final driverEarning = fare * 0.80;

        if (createdAt.isAfter(todayStart)) {
          todayTotal += driverEarning;
          todayCount++;
        }
        if (createdAt.isAfter(weekStart)) {
          weekTotal += driverEarning;
          weekCount++;
        }
        if (createdAt.isAfter(monthStart)) {
          monthTotal += driverEarning;
          monthCount++;
        }

        // Add to recent trips (first 10)
        if (recent.length < 10) {
          recent.add({
            'id': ride.id,
            'pickup': ride.pickupAddress ?? 'Unknown pickup',
            'dropoff': ride.dropoffAddress ?? 'Unknown dropoff',
            'fare': driverEarning,
            'date': createdAt,
            'status': ride.status,
          });
        }
      }

      setState(() {
        _todayEarnings = todayTotal;
        _weekEarnings = weekTotal;
        _monthEarnings = monthTotal;
        _todayTrips = todayCount;
        _weekTrips = weekCount;
        _monthTrips = monthCount;
        _recentTrips = recent;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading earnings: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Earnings',
          style: GoogleFonts.geologica(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _loadEarnings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's earnings card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0066CC), Color(0xFF0052A3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0066CC).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Earnings',
                            style: GoogleFonts.geologica(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${_todayEarnings.toStringAsFixed(2)}',
                            style: GoogleFonts.geologica(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_todayTrips ${_todayTrips == 1 ? 'trip' : 'trips'} completed',
                            style: GoogleFonts.geologica(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'You earn 80% of each fare',
                                  style: GoogleFonts.geologica(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Weekly and monthly summary
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'This Week',
                            '\$${_weekEarnings.toStringAsFixed(2)}',
                            '$_weekTrips trips',
                            Icons.calendar_view_week,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'This Month',
                            '\$${_monthEarnings.toStringAsFixed(2)}',
                            '$_monthTrips trips',
                            Icons.calendar_month,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recent trips header
                    Text(
                      'Recent Trips',
                      style: GoogleFonts.geologica(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Recent trips list
                    if (_recentTrips.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No completed trips yet',
                                style: GoogleFonts.geologica(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your earnings will appear here after you complete trips',
                                style: GoogleFonts.geologica(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(_recentTrips.length, (index) {
                        final trip = _recentTrips[index];
                        return _buildTripItem(
                          '${trip['pickup']} → ${trip['dropoff']}',
                          '\$${(trip['fare'] as double).toStringAsFixed(2)}',
                          _formatDate(trip['date'] as DateTime),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tripDate = DateTime(date.year, date.month, date.day);

    if (tripDate == today) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (tripDate == yesterday) {
      return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildSummaryCard(
      String title, String amount, String trips, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0066CC)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.geologica(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: GoogleFonts.geologica(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trips,
            style: GoogleFonts.geologica(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripItem(String route, String fare, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0066CC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_taxi,
              color: Color(0xFF0066CC),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route,
                  style: GoogleFonts.geologica(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.geologica(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            fare,
            style: GoogleFonts.geologica(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFF0066CC),
            ),
          ),
        ],
      ),
    );
  }
}
