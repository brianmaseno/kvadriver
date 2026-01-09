import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/providers/app_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AppProvider>().getCurrentUser();
    } catch (e) {
      print('Error loading profile: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Profile',
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
            onPressed: _loadProfileData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile header
                    _buildProfileHeader(),

                    const SizedBox(height: 24),

                    // Vehicle info card
                    _buildVehicleInfoCard(),

                    const SizedBox(height: 24),

                    // Account section
                    _buildSectionTitle('Account'),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      Icons.person_outline,
                      'Personal Information',
                      'View and edit your details',
                      () => _showPersonalInfoSheet(context),
                    ),
                    _buildMenuItem(
                      Icons.phone_outlined,
                      'Contact Details',
                      'Phone number and email',
                      () => _showContactDetailsSheet(context),
                    ),
                    _buildMenuItem(
                      Icons.lock_outline,
                      'Change Password',
                      'Update your password',
                      () => _showChangePasswordSheet(context),
                    ),

                    const SizedBox(height: 24),

                    // Support section
                    _buildSectionTitle('Support'),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      Icons.help_outline,
                      'Get Help',
                      'FAQs and support',
                      () => Navigator.pushNamed(context, '/get-help'),
                    ),
                    _buildMenuItem(
                      Icons.policy_outlined,
                      'Terms & Privacy',
                      'Read our policies',
                      () => _showTermsSheet(context),
                    ),
                    _buildMenuItem(
                      Icons.info_outline,
                      'About',
                      'App version and info',
                      () => _showAboutSheet(context),
                    ),

                    const SizedBox(height: 24),

                    // Logout button
                    _buildLogoutButton(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final userData = provider.currentUserData;
        final displayName = userData != null
            ? '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                .trim()
            : 'Driver Name';
        final email = userData?['email'] ?? 'driver@email.com';
        final phone = userData?['phoneNumber'] ?? '';
        final rating = userData?['rating']?.toString() ?? '0.0';
        final approvalStatus = userData?['approvalStatus'] ?? 'pending';
        final profilePhoto = userData?['profilePhoto'];
        final initials = userData != null
            ? '${userData['firstName']?.toString().substring(0, 1) ?? 'D'}${userData['lastName']?.toString().substring(0, 1) ?? ''}'
            : 'D';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0066CC), Color(0xFF0052A3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0066CC).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Profile photo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: profilePhoto != null && profilePhoto.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          profilePhoto,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white,
                            child: Text(
                              initials.toUpperCase(),
                              style: GoogleFonts.geologica(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0066CC),
                              ),
                            ),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white,
                        child: Text(
                          initials.toUpperCase(),
                          style: GoogleFonts.geologica(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0066CC),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                displayName.isNotEmpty ? displayName : 'Driver',
                style: GoogleFonts.geologica(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: GoogleFonts.geologica(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: GoogleFonts.geologica(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rating
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
                          Icons.star,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          double.tryParse(rating)?.toStringAsFixed(1) ?? '0.0',
                          style: GoogleFonts.geologica(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Verification status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(approvalStatus).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(approvalStatus).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(approvalStatus),
                          color: _getStatusColor(approvalStatus),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatApprovalStatus(approvalStatus),
                          style: GoogleFonts.geologica(
                            color: _getStatusColor(approvalStatus),
                            fontSize: 12,
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
      },
    );
  }

  Widget _buildVehicleInfoCard() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final userData = provider.currentUserData;
        final vehicleInfo = userData?['vehicle'] ?? userData?['vehicleInfo'];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066CC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Color(0xFF0066CC),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle Information',
                          style: GoogleFonts.geologica(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Your registered vehicle',
                          style: GoogleFonts.geologica(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              if (vehicleInfo != null) ...[
                _buildVehicleDetail('Make', vehicleInfo['make'] ?? 'N/A'),
                _buildVehicleDetail('Model', vehicleInfo['model'] ?? 'N/A'),
                _buildVehicleDetail(
                    'Year', vehicleInfo['year']?.toString() ?? 'N/A'),
                _buildVehicleDetail('Color', vehicleInfo['color'] ?? 'N/A'),
                _buildVehicleDetail(
                    'Plate Number',
                    vehicleInfo['plateNumber'] ??
                        vehicleInfo['licensePlate'] ??
                        'N/A'),
                _buildVehicleDetail(
                    'Vehicle Type', vehicleInfo['vehicleType'] ?? 'N/A'),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No vehicle information on file',
                          style: GoogleFonts.geologica(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.geologica(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.geologica(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.geologica(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0066CC).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0066CC),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.geologica(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.geologica(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: Text(
          'Logout',
          style: GoogleFonts.geologica(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.verified;
      case 'pending':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatApprovalStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Verified';
      case 'pending':
        return 'Pending Verification';
      case 'rejected':
        return 'Not Verified';
      default:
        return status;
    }
  }

  void _showPersonalInfoSheet(BuildContext context) {
    final provider = context.read<AppProvider>();
    final userData = provider.currentUserData;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Personal Information',
              style: GoogleFonts.geologica(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _detailRow('First Name', userData?['firstName'] ?? 'N/A'),
            _detailRow('Last Name', userData?['lastName'] ?? 'N/A'),
            _detailRow('Date of Birth', userData?['dateOfBirth'] ?? 'N/A'),
            _detailRow('Gender', userData?['gender'] ?? 'N/A'),
            _detailRow('Address', userData?['address'] ?? 'N/A'),
            const SizedBox(height: 24),
            _closeButton(context),
          ],
        ),
      ),
    );
  }

  void _showContactDetailsSheet(BuildContext context) {
    final provider = context.read<AppProvider>();
    final userData = provider.currentUserData;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Contact Details',
              style: GoogleFonts.geologica(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _detailRow('Email', userData?['email'] ?? 'N/A'),
            _detailRow('Phone Number', userData?['phoneNumber'] ?? 'N/A'),
            const SizedBox(height: 24),
            _closeButton(context),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Change Password',
                style: GoogleFonts.geologica(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'To change your password, please contact support or use the forgot password feature on the login screen.',
                style: GoogleFonts.geologica(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _closeButton(context),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Terms & Privacy Policy',
              style: GoogleFonts.geologica(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '''Terms of Service

By using our driver application, you agree to these terms:

1. Driver Requirements
   - Must possess a valid driver's license
   - Must maintain proper vehicle insurance
   - Must pass background verification

2. Service Standards
   - Maintain professional conduct at all times
   - Provide safe and reliable transportation
   - Keep your vehicle clean and well-maintained

3. Payment Terms
   - Drivers receive 80% of each fare
   - Payments are processed weekly
   - Ensure accurate banking information

4. Privacy Policy
   - We collect location data for service delivery
   - Personal information is protected
   - Data is not shared with third parties

For full terms, visit our website.''',
                  style: GoogleFonts.geologica(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _closeButton(context),
          ],
        ),
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF0066CC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_taxi,
                size: 40,
                color: Color(0xFF0066CC),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'KVA Driver',
              style: GoogleFonts.geologica(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.geologica(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'The official driver application for KVA ride-sharing service. Connect with passengers and earn on your schedule.',
              style: GoogleFonts.geologica(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _closeButton(context),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.geologica(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.geologica(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _closeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0066CC),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Close',
          style: GoogleFonts.geologica(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.geologica(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.geologica(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.geologica(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<AppProvider>().logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: Text(
                'Logout',
                style: GoogleFonts.geologica(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
