import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/providers/app_provider.dart';

class DriverSignUpSignInScreen extends StatefulWidget {
  const DriverSignUpSignInScreen({Key? key}) : super(key: key);

  @override
  State<DriverSignUpSignInScreen> createState() =>
      _DriverSignUpSignInScreenState();
}

class _DriverSignUpSignInScreenState extends State<DriverSignUpSignInScreen> {
  bool _isSignIn = true;
  bool _isLoading = false;

  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  // Sign in controllers
  final _signInPhoneController = TextEditingController();

  // Sign up controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _signInPhoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  /// Normalize phone number to E.164 format with + prefix
  String _normalizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');

    // Already has + prefix
    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    // Kenyan format without + (e.g., 254XXXXXXXXX)
    if (cleaned.startsWith('254') && cleaned.length >= 12) {
      return '+$cleaned';
    }

    // Kenyan local format (07XXXXXXXX or 7XXXXXXXX)
    if (RegExp(r'^0?7\d{8}$').hasMatch(cleaned)) {
      return '+254${cleaned.substring(cleaned.length - 9)}';
    }

    // US format (10 digits or 1 + 10 digits)
    if (RegExp(r'^1?\d{10}$').hasMatch(cleaned)) {
      final digits = cleaned.substring(cleaned.length - 10);
      return '+1$digits';
    }

    // Default: add + prefix
    return '+$cleaned';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final normalizedPhone =
        _normalizePhoneNumber(_signInPhoneController.text.trim());
    print(
        '📱 Sign in with phone: $normalizedPhone (original: ${_signInPhoneController.text.trim()})');

    final provider = context.read<AppProvider>();
    final success = await provider.requestOtp(normalizedPhone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushNamed(context, '/phone-verification', arguments: {
        'phoneNumber': normalizedPhone,
      });
    } else {
      _showError('Login failed. Please try again.');
    }
  }

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<AppProvider>();

    String fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

    // Store the phone number in provider for later use
    provider.setCurrentPhone(_phoneController.text.trim());

    final success = await provider.registerUser(
      fullName,
      _emailController.text.trim(),
      _phoneController.text.trim(),
      _cityController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushNamed(context, '/phone-verification', arguments: {
        'phoneNumber': _phoneController.text.trim(),
      });
    } else {
      _showError('Registration failed. Please try again.');
    }
  }

  Widget _buildToggleButtons() {
    const blue = Color(0xFF0066CC);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSignIn = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isSignIn ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Sign in',
                    style: GoogleFonts.geologica(
                      fontSize: 16,
                      fontWeight: _isSignIn ? FontWeight.bold : FontWeight.w500,
                      color: _isSignIn ? blue : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSignIn = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isSignIn ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Sign up',
                    style: GoogleFonts.geologica(
                      fontSize: 16,
                      fontWeight:
                          !_isSignIn ? FontWeight.bold : FontWeight.w500,
                      color: !_isSignIn ? blue : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInForm() {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back',
            style: GoogleFonts.geologica(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Login with your phone number to continue',
            style: GoogleFonts.geologica(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _signInPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '+1234567890',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF0066CC)),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Continue',
                      style: GoogleFonts.geologica(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Join as a driver',
            style: GoogleFonts.geologica(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your driver account to start earning',
            style: GoogleFonts.geologica(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Info card about requirements
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF0066CC)),
                    SizedBox(width: 8),
                    Text('Requirements to become a driver:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 12),
                Text('• Must be at least 21 years old'),
                Text('• Valid US Driver\'s License'),
                Text('• Vehicle 15 years old or newer'),
                Text('• Insurance with rideshare endorsement'),
                Text('• Pass background check'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.pushNamed(context, '/driver-registration');
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Start Application',
                style: GoogleFonts.geologica(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Center(
            child: Text(
              'The application takes about 10-15 minutes to complete',
              style: GoogleFonts.geologica(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0066CC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              const SizedBox(height: 16),
              Text(
                'KVA Driver',
                style: GoogleFonts.geologica(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: blue,
                ),
              ),
              const SizedBox(height: 16),
              _buildToggleButtons(),
              const SizedBox(height: 24),
              _isSignIn ? _buildSignInForm() : _buildSignUpForm(),
            ],
          ),
        ),
      ),
    );
  }
}
