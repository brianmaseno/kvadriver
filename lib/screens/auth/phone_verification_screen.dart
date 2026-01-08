import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/app_provider.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _hasRequestedOtp = false;
  String? _phoneNumber;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _phoneNumber = args?['phoneNumber'];
    if (_phoneNumber != null && !_hasRequestedOtp) {
      _hasRequestedOtp = true;
      _requestOtp();
    }
  }

  Future<void> _requestOtp() async {
    final provider = context.read<AppProvider>();
    final success = await provider.requestOtp(_phoneNumber!);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send OTP. You may be rate limited. Please wait a few minutes and try again.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _phoneNumber == null) return;

    setState(() => _isLoading = true);

    final provider = context.read<AppProvider>();
    final success = await provider.verifyOtp(_phoneNumber!, _otpController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // Check if driver registration is complete
      final hasCompletedRegistration = await provider.hasCompletedDriverRegistration();
      
      if (hasCompletedRegistration) {
        // Existing driver - go to home
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        // New driver - go to vehicle info setup
        Navigator.pushNamedAndRemoveUntil(context, '/vehicle-info', (route) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text(
              'Enter the verification code sent to\n$_phoneNumber',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Verify', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () {
                _hasRequestedOtp = false;
                _requestOtp();
              },
              child: const Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}