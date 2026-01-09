import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GetHelpScreen extends StatelessWidget {
  const GetHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Get Help',
          style: GoogleFonts.geologica(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How can we help you?',
              style: GoogleFonts.geologica(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildHelpCategory(
              'Trip Issues',
              'Problems with rides, payments, or passengers',
              Icons.directions_car,
              () {},
            ),
            _buildHelpCategory(
              'Account & Profile',
              'Update your information or account settings',
              Icons.person,
              () {},
            ),
            _buildHelpCategory(
              'Vehicle & Documents',
              'Vehicle registration, insurance, or license issues',
              Icons.description,
              () {},
            ),
            _buildHelpCategory(
              'Earnings & Payments',
              'Questions about your earnings or payment methods',
              Icons.payment,
              () {},
            ),
            _buildHelpCategory(
              'App Issues',
              'Technical problems or app not working properly',
              Icons.bug_report,
              () {},
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.headset_mic,
                    size: 40,
                    color: Color(0xFF0066CC),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Need immediate help?',
                    style: GoogleFonts.geologica(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact our 24/7 support team',
                    style: GoogleFonts.geologica(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Call Support',
                      style: GoogleFonts.geologica(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCategory(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0066CC)),
        ),
        title: Text(
          title,
          style: GoogleFonts.geologica(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.geologica(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
