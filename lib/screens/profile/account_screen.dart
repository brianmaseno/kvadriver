import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/app_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            final userData = provider.currentUserData;
            final driver = provider.currentDriver;
            
            return Column(
              children: [
                // Profile Avatar
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF0066CC),
                    child: Text(
                      _getInitials(userData?['firstName'], userData?['lastName']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildInfoTile('Name', '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}' ?? driver?.name ?? 'N/A'),
                _buildInfoTile('Email', userData?['email'] ?? driver?.email ?? 'N/A'),
                _buildInfoTile('Phone', provider.currentPhone ?? userData?['phoneNumber'] ?? driver?.phone ?? 'N/A'),
                _buildInfoTile('Role', userData?['role']?.toString().toUpperCase() ?? 'DRIVER'),
                if (driver?.city != null) _buildInfoTile('City', driver!.city!),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _showEditProfileDialog(context, provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  String _getInitials(String? firstName, String? lastName) {
    final first = firstName?.isNotEmpty == true ? firstName![0] : 'D';
    final last = lastName?.isNotEmpty == true ? lastName![0] : 'R';
    return '$first$last'.toUpperCase();
  }
  
  void _showEditProfileDialog(BuildContext context, AppProvider provider) {
    final userData = provider.currentUserData;
    final firstNameController = TextEditingController(text: userData?['firstName'] ?? '');
    final lastNameController = TextEditingController(text: userData?['lastName'] ?? '');
    final emailController = TextEditingController(text: userData?['email'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement profile update API call
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile update feature coming soon!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}