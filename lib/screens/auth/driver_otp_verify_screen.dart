import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/providers/app_provider.dart';
import '../../data/services/api_service.dart';

class DriverOtpVerifyScreen extends StatefulWidget {
  const DriverOtpVerifyScreen({super.key});

  @override
  State<DriverOtpVerifyScreen> createState() => _DriverOtpVerifyScreenState();
}

class _DriverOtpVerifyScreenState extends State<DriverOtpVerifyScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _phoneNumber;
  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? _vehicleData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _phoneNumber = args?['phoneNumber'];
    _driverData = args?['driverData'];
    _vehicleData = args?['vehicleData'];
  }

  Future<void> _resendOtp() async {
    if (_phoneNumber == null) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.requestOtp(_phoneNumber!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend OTP: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndRegister() async {
    if (_otpController.text.isEmpty || _phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppProvider>();

      print('🔐 Verifying OTP...');
      // Verify OTP
      final success =
          await provider.verifyOtp(_phoneNumber!, _otpController.text);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid OTP. Please try again.')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      print('✅ OTP verified successfully');
      print('🚗 Registering driver profile...');

      // Now register the driver profile with all the collected data
      final driverResponse = await ApiService.registerDriver(
        provider.currentUserId!,
        _driverData ?? {},
        _vehicleData ?? {},
      );

      print('🚗 Driver registration response: $driverResponse');

      // Check for success or "already exists" (which is also fine)
      final isSuccess = driverResponse['success'] == true ||
          driverResponse['data'] != null ||
          (driverResponse['error']
                  ?.toString()
                  .toLowerCase()
                  .contains('already exists') ??
              false);

      if (isSuccess) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Registration failed: ${driverResponse['error'] ?? 'Unknown error'}')),
          );
        }
      }
    } catch (e) {
      print('🔴 Error during verification/registration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verify Phone Number',
          style: GoogleFonts.geologica(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.phone_android, size: 80, color: Color(0xFF0066CC)),
            const SizedBox(height: 24),
            Text(
              'Enter the verification code sent to\n$_phoneNumber',
              textAlign: TextAlign.center,
              style: GoogleFonts.geologica(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'For testing: Use OTP 123456',
              textAlign: TextAlign.center,
              style: GoogleFonts.geologica(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.geologica(fontSize: 28, letterSpacing: 12),
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Verification Code',
                labelStyle: GoogleFonts.geologica(),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF0066CC)),
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyAndRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Verify & Complete Registration',
                      style: GoogleFonts.geologica(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading ? null : _resendOtp,
              child: Text(
                'Resend Code',
                style: GoogleFonts.geologica(
                  color: const Color(0xFF0066CC),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'After verification, your application will be reviewed. This typically takes 1-2 business days.',
                      style: GoogleFonts.geologica(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
