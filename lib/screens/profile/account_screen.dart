import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/providers/app_provider.dart';
import '../../data/services/api_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? _driverProfile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getDriverProfile();
      print('Profile response: $response');

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _driverProfile = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _error = 'Error loading profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.geologica(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 16),
                        _buildStatsSection(),
                        const SizedBox(height: 16),
                        _buildVehicleSection(),
                        const SizedBox(height: 16),
                        _buildPersonalInfoSection(),
                        const SizedBox(height: 16),
                        _buildDocumentsSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profile = _driverProfile;
    final profilePhotoUrl = profile?['profilePhotoUrl'];
    final firstName = profile?['firstName'] ?? '';
    final lastName = profile?['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = profile?['email'] ?? '';
    final phone = profile?['phone'] ?? '';
    final approvalStatus = profile?['approvalStatus'] ?? 'pending';
    final averageRating = (profile?['averageRating'] ?? 0).toDouble();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          // Profile Photo
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                      ? Image.network(
                          profilePhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildInitialsAvatar(firstName, lastName),
                        )
                      : _buildInitialsAvatar(firstName, lastName),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(approvalStatus),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    _getStatusIcon(approvalStatus),
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            fullName.isNotEmpty ? fullName : 'Driver',
            style: GoogleFonts.geologica(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          if (email.isNotEmpty)
            Text(
              email,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),

          // Phone
          if (phone.isNotEmpty)
            Text(
              phone,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),

          const SizedBox(height: 12),

          // Status Badge and Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(approvalStatus).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(approvalStatus),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(approvalStatus),
                      color: _getStatusColor(approvalStatus),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      approvalStatus.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(approvalStatus),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      averageRating > 0
                          ? averageRating.toStringAsFixed(1)
                          : 'N/A',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String firstName, String lastName) {
    final initials =
        '${firstName.isNotEmpty ? firstName[0] : 'D'}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();
    return Container(
      color: const Color(0xFF0066CC),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.geologica(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final profile = _driverProfile;
    final totalRides = profile?['totalRides'] ?? 0;
    final totalRatings = profile?['totalRatings'] ?? 0;
    final averageRating = (profile?['averageRating'] ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Rides',
              totalRides.toString(),
              Icons.local_taxi,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Avg Rating',
              averageRating > 0 ? averageRating.toStringAsFixed(1) : 'N/A',
              Icons.star,
              Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Reviews',
              totalRatings.toString(),
              Icons.rate_review,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.geologica(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    final vehicle = _driverProfile?['vehicle'];
    if (vehicle == null) {
      return const SizedBox.shrink();
    }

    final make = vehicle['make'] ?? '';
    final model = vehicle['model'] ?? '';
    final year = vehicle['year'];
    final color = vehicle['color'] ?? '';
    final licensePlate = vehicle['licensePlate'] ?? '';
    final registrationPhotoUrl = vehicle['registrationPhotoUrl'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                const Icon(Icons.directions_car, color: Colors.black),
                const SizedBox(width: 12),
                Text(
                  'Vehicle Information',
                  style: GoogleFonts.geologica(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Vehicle image if available
            if (registrationPhotoUrl != null &&
                registrationPhotoUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  registrationPhotoUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildVehicleInfoRow('Make', make),
            _buildVehicleInfoRow('Model', model),
            if (year != null) _buildVehicleInfoRow('Year', year.toString()),
            if (color.isNotEmpty) _buildVehicleInfoRow('Color', color),
            _buildVehicleInfoRow('License Plate', licensePlate),

            if (vehicle['insuranceProvider'] != null)
              _buildVehicleInfoRow('Insurance', vehicle['insuranceProvider']),
            if (vehicle['insuranceExpiry'] != null)
              _buildVehicleInfoRow(
                  'Insurance Expiry', _formatDate(vehicle['insuranceExpiry'])),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    final profile = _driverProfile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                const Icon(Icons.person, color: Colors.black),
                const SizedBox(width: 12),
                Text(
                  'Personal Information',
                  style: GoogleFonts.geologica(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (profile?['dateOfBirth'] != null)
              _buildInfoRow(
                  'Date of Birth', _formatDate(profile!['dateOfBirth'])),
            if (profile?['streetAddress'] != null)
              _buildInfoRow('Address', profile!['streetAddress']),
            if (profile?['city'] != null || profile?['state'] != null)
              _buildInfoRow(
                'City/State',
                '${profile?['city'] ?? ''}, ${profile?['state'] ?? ''}'.trim(),
              ),
            if (profile?['zipCode'] != null)
              _buildInfoRow('Zip Code', profile!['zipCode']),
            if (profile?['memberSince'] != null)
              _buildInfoRow(
                  'Member Since', _formatDate(profile!['memberSince'])),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    final profile = _driverProfile;
    final licenseNumber = profile?['driversLicenseNumber'];
    final licenseState = profile?['driversLicenseState'];
    final licenseExpiry = profile?['driversLicenseExpiry'];
    final licenseFrontUrl = profile?['driversLicenseFrontUrl'];
    final licenseBackUrl = profile?['driversLicenseBackUrl'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                const Icon(Icons.badge, color: Colors.black),
                const SizedBox(width: 12),
                Text(
                  "Driver's License",
                  style: GoogleFonts.geologica(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (licenseNumber != null)
              _buildInfoRow('License Number', licenseNumber),
            if (licenseState != null) _buildInfoRow('State', licenseState),
            if (licenseExpiry != null)
              _buildInfoRow('Expiry', _formatDate(licenseExpiry)),
            if (licenseFrontUrl != null || licenseBackUrl != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (licenseFrontUrl != null)
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              licenseFrontUrl,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('Front', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  if (licenseFrontUrl != null && licenseBackUrl != null)
                    const SizedBox(width: 12),
                  if (licenseBackUrl != null)
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              licenseBackUrl,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('Back', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.verified;
      case 'rejected':
        return Icons.block;
      case 'pending':
      default:
        return Icons.hourglass_empty;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<AppProvider>();
              await provider.logout();

              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/auth',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
