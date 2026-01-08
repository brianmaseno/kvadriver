import 'package:flutter/material.dart';

class BackgroundCheckScreen extends StatefulWidget {
  const BackgroundCheckScreen({super.key});

  @override
  State<BackgroundCheckScreen> createState() => _BackgroundCheckScreenState();
}

class _BackgroundCheckScreenState extends State<BackgroundCheckScreen> {
  final _ssnController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final registrationData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Help'),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('In progress'),
                  SizedBox(height: 16),
                  Text('Next Step', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Background check'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'For authentication purposes, we need your social security number to begin a background check',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            TextFormField(
              controller: _ssnController,
              decoration: const InputDecoration(
                labelText: 'Social Security Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            
            const Text('We confirm that we through a background check to ensure safety and security of our users'),
            const SizedBox(height: 16),
            
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Personal information protection guaranteed'),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.check, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Secure data - data stored in device'),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.check, color: Colors.green),
                    SizedBox(width: 8),
                    Text('No data shared with third parties'),
                  ],
                ),
              ],
            ),
            const Spacer(),
            
            ElevatedButton(
              onPressed: () {
                if (_ssnController.text.isNotEmpty) {
                  final completeData = {
                    ...registrationData,
                    'ssn': _ssnController.text,
                  };
                  Navigator.pushNamed(context, '/license-photo', arguments: completeData);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Continue', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}