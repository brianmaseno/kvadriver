import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/providers/app_provider.dart';
import '../../data/services/api_service.dart';

class DriverRegistrationFlow extends StatefulWidget {
  const DriverRegistrationFlow({super.key});

  @override
  State<DriverRegistrationFlow> createState() => _DriverRegistrationFlowState();
}

class _DriverRegistrationFlowState extends State<DriverRegistrationFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Form Keys
  final _personalInfoKey = GlobalKey<FormState>();
  final _addressKey = GlobalKey<FormState>();
  final _licenseKey = GlobalKey<FormState>();
  final _vehicleKey = GlobalKey<FormState>();
  final _insuranceKey = GlobalKey<FormState>();

  // Personal Info Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _ssnController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedDateOfBirth;

  // Address Controllers
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();

  // License Controllers
  final _licenseNumberController = TextEditingController();
  final _licenseStateController = TextEditingController();
  final _licenseExpiryController = TextEditingController();
  DateTime? _selectedLicenseExpiry;

  // Vehicle Controllers
  final _vinController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _licensePlateController = TextEditingController();
  int _doors = 4;
  int _seats = 5;

  // Insurance Controllers
  final _insuranceProviderController = TextEditingController();
  final _insurancePolicyController = TextEditingController();
  final _insuranceExpiryController = TextEditingController();
  DateTime? _selectedInsuranceExpiry;
  bool _hasRideshareEndorsement = false;

  // Image Data
  dynamic _profilePhoto;
  Uint8List? _profilePhotoBytes;
  dynamic _licenseFrontPhoto;
  Uint8List? _licenseFrontBytes;
  dynamic _licenseBackPhoto;
  Uint8List? _licenseBackBytes;
  dynamic _proofOfResidencyPhoto;
  Uint8List? _proofOfResidencyBytes;
  dynamic _registrationPhoto;
  Uint8List? _registrationPhotoBytes;
  dynamic _insurancePhoto;
  Uint8List? _insurancePhotoBytes;

  // Background Check
  bool _backgroundCheckConsent = false;

  final List<String> _stepTitles = [
    'Personal Information',
    'Residential Address',
    'Driver\'s License',
    'Vehicle Information',
    'Insurance & Documents',
    'Review & Submit',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final provider = context.read<AppProvider>();
    final userData = provider.currentUserData;
    if (userData != null) {
      _phoneController.text =
          userData['phoneNumber'] ?? provider.currentPhone ?? '';
      _emailController.text = userData['email'] ?? '';
      _firstNameController.text = userData['firstName'] ?? '';
      _lastNameController.text = userData['lastName'] ?? '';
    } else {
      _phoneController.text = provider.currentPhone ?? '';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _ssnController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _licenseNumberController.dispose();
    _licenseStateController.dispose();
    _licenseExpiryController.dispose();
    _vinController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    _insuranceProviderController.dispose();
    _insurancePolicyController.dispose();
    _insuranceExpiryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        switch (type) {
          case 'profile':
            _profilePhoto = kIsWeb ? bytes : File(image.path);
            _profilePhotoBytes = bytes;
            break;
          case 'licenseFront':
            _licenseFrontPhoto = kIsWeb ? bytes : File(image.path);
            _licenseFrontBytes = bytes;
            break;
          case 'licenseBack':
            _licenseBackPhoto = kIsWeb ? bytes : File(image.path);
            _licenseBackBytes = bytes;
            break;
          case 'proofOfResidency':
            _proofOfResidencyPhoto = kIsWeb ? bytes : File(image.path);
            _proofOfResidencyBytes = bytes;
            break;
          case 'registration':
            _registrationPhoto = kIsWeb ? bytes : File(image.path);
            _registrationPhotoBytes = bytes;
            break;
          case 'insurance':
            _insurancePhoto = kIsWeb ? bytes : File(image.path);
            _insurancePhotoBytes = bytes;
            break;
        }
      });
    }
  }

  Future<void> _selectDate(
      TextEditingController controller, Function(DateTime) onSelect) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        onSelect(picked);
        controller.text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  void _nextStep() {
    bool isValid = true;

    switch (_currentStep) {
      case 0:
        isValid = _personalInfoKey.currentState?.validate() ?? false;
        break;
      case 1:
        isValid = _addressKey.currentState?.validate() ?? false;
        break;
      case 2:
        isValid = _licenseKey.currentState?.validate() ?? false;
        if (isValid &&
            (_licenseFrontPhoto == null || _licenseBackPhoto == null)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Please upload front and back of your driver\'s license')),
          );
          isValid = false;
        }
        break;
      case 3:
        isValid = _vehicleKey.currentState?.validate() ?? false;
        break;
      case 4:
        isValid = _insuranceKey.currentState?.validate() ?? false;
        if (isValid && _insurancePhoto == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please upload your insurance document')),
          );
          isValid = false;
        }
        if (isValid && !_backgroundCheckConsent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please consent to the background check')),
          );
          isValid = false;
        }
        break;
    }

    if (isValid && _currentStep < 5) {
      setState(() => _currentStep++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
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

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    try {
      // Normalize phone number to E.164 format
      final normalizedPhone =
          _normalizePhoneNumber(_phoneController.text.trim());

      // First, register/update the user
      final userData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': normalizedPhone,
        'role': 'driver',
      };

      print('📝 Starting driver registration flow...');
      print('📝 User data: $userData');
      print('📝 Original phone: ${_phoneController.text.trim()}');
      print('📝 Normalized phone: $normalizedPhone');

      // Register user first if not already done
      final userResponse = await ApiService.registerUser(userData);
      print('📝 User registration response: $userResponse');

      // Request OTP for verification using normalized phone number
      print('📱 Requesting OTP for phone: $normalizedPhone');
      final otpResponse = await ApiService.requestOtp(normalizedPhone);
      print('📱 OTP response: $otpResponse');

      if (otpResponse['success'] != true &&
          !otpResponse.toString().contains('sent')) {
        throw Exception('Failed to send OTP');
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Navigate to OTP verification with all the collected data
      Navigator.pushNamed(
        context,
        '/driver-otp-verify',
        arguments: {
          'phoneNumber': normalizedPhone,
          'driverData': {
            'firstName': _firstNameController.text.trim(),
            'middleName': _middleNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'dateOfBirth':
                _selectedDateOfBirth?.toIso8601String().split('T')[0],
            'ssn': _ssnController.text.trim(),
            'streetAddress': _streetAddressController.text.trim(),
            'city': _cityController.text.trim(),
            'state': _stateController.text.trim(),
            'zipCode': _zipCodeController.text.trim(),
            'driversLicenseNumber': _licenseNumberController.text.trim(),
            'driversLicenseState': _licenseStateController.text.trim(),
            'driversLicenseExpiry':
                _selectedLicenseExpiry?.toIso8601String().split('T')[0],
            'driversLicenseFrontUrl': _licenseFrontPhoto is File
                ? (_licenseFrontPhoto as File).path
                : 'uploaded',
            'driversLicenseBackUrl': _licenseBackPhoto is File
                ? (_licenseBackPhoto as File).path
                : 'uploaded',
            'profilePhotoUrl': _profilePhoto is File
                ? (_profilePhoto as File).path
                : 'uploaded',
            'proofOfResidencyUrl': _proofOfResidencyPhoto is File
                ? (_proofOfResidencyPhoto as File).path
                : null,
            'backgroundCheckConsent': _backgroundCheckConsent,
          },
          'vehicleData': {
            'vin': _vinController.text.trim(),
            'make': _makeController.text.trim(),
            'model': _modelController.text.trim(),
            'year': int.tryParse(_yearController.text.trim()),
            'color': _colorController.text.trim(),
            'doors': _doors,
            'seats': _seats,
            'licensePlate': _licensePlateController.text.trim(),
            'registrationPhotoUrl': _registrationPhoto is File
                ? (_registrationPhoto as File).path
                : null,
            'insuranceProvider': _insuranceProviderController.text.trim(),
            'insurancePolicyNumber': _insurancePolicyController.text.trim(),
            'insuranceExpiry':
                _selectedInsuranceExpiry?.toIso8601String().split('T')[0],
            'hasRideshareEndorsement': _hasRideshareEndorsement,
            'insuranceDocumentUrl': _insurancePhoto is File
                ? (_insurancePhoto as File).path
                : 'uploaded',
          },
        },
      );
    } catch (e) {
      print('🔴 Registration error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _stepTitles[_currentStep],
          style: GoogleFonts.geologica(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: List.generate(6, (index) {
                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          gradient: index <= _currentStep
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF0066CC),
                                    Color(0xFF0052A3)
                                  ],
                                )
                              : null,
                          color: index > _currentStep ? Colors.grey[200] : null,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  'Step ${_currentStep + 1} of 6',
                  style: GoogleFonts.geologica(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Page Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPersonalInfoStep(),
                _buildAddressStep(),
                _buildLicenseStep(),
                _buildVehicleStep(),
                _buildInsuranceStep(),
                _buildReviewStep(),
              ],
            ),
          ),

          // Bottom Navigation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _currentStep < 5
                ? ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.geologica(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Submit & Verify Phone',
                            style: GoogleFonts.geologica(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _personalInfoKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your legal name must match your Driver\'s License exactly',
              style: GoogleFonts.geologica(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // Profile Photo
            Center(
              child: GestureDetector(
                onTap: () => _pickImage('profile'),
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        border: Border.all(
                          color: _profilePhotoBytes != null
                              ? const Color(0xFF0066CC)
                              : Colors.grey[300]!,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: _profilePhotoBytes != null
                          ? ClipOval(
                              child: Image.memory(
                                _profilePhotoBytes!,
                                fit: BoxFit.cover,
                                width: 110,
                                height: 110,
                              ),
                            )
                          : const Icon(Icons.person,
                              size: 50, color: Colors.grey),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0066CC),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Profile Photo *',
                style: GoogleFonts.geologica(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 28),

            _buildTextField(
              controller: _firstNameController,
              label: 'First Name *',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _middleNameController,
              label: 'Middle Name (Optional)',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _lastNameController,
              label: 'Last Name *',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _dateOfBirthController,
              label: 'Date of Birth *',
              readOnly: true,
              onTap: () => _selectDate(
                  _dateOfBirthController, (d) => _selectedDateOfBirth = d),
              suffixIcon:
                  const Icon(Icons.calendar_today, color: Color(0xFF0066CC)),
              hintText: 'MM/DD/YYYY',
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (_selectedDateOfBirth != null) {
                  final age =
                      DateTime.now().difference(_selectedDateOfBirth!).inDays ~/
                          365;
                  if (age < 21) return 'Must be at least 21 years old';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _ssnController,
              label: 'Social Security Number *',
              hintText: 'XXX-XX-XXXX',
              keyboardType: TextInputType.number,
              obscureText: true,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Required for background check' : null,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number *',
              hintText: '+1234567890',
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _emailController,
              label: 'Email *',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (!v!.contains('@')) return 'Invalid email';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
    bool readOnly = false,
    bool obscureText = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      style: GoogleFonts.geologica(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.geologica(
          color: Colors.grey[600],
          fontSize: 15,
        ),
        hintText: hintText,
        hintStyle: GoogleFonts.geologica(
          color: Colors.grey[400],
          fontSize: 15,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0066CC), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _addressKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Residential Address',
              style: GoogleFonts.geologica(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Must be a physical US address (P.O. Boxes are not accepted)',
              style: GoogleFonts.geologica(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _streetAddressController,
              label: 'Street Address *',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cityController,
              label: 'City *',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _stateController,
                    label: 'State *',
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _zipCodeController,
                    label: 'ZIP Code *',
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Proof of Residency',
              style: GoogleFonts.geologica(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If your license address is different, upload a utility bill or bank statement',
              style: GoogleFonts.geologica(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            _buildImageUploadBox(
              title: 'Proof of Residency (Optional)',
              imageBytes: _proofOfResidencyBytes,
              onTap: () => _pickImage('proofOfResidency'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _licenseKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver\'s License',
              style: GoogleFonts.geologica(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Must be a valid in-state license for where you intend to drive',
              style: GoogleFonts.geologica(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _licenseNumberController,
              label: 'License Number *',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _licenseStateController,
              label: 'Issuing State *',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _licenseExpiryController,
              label: 'Expiration Date *',
              readOnly: true,
              onTap: () => _selectDate(
                  _licenseExpiryController, (d) => _selectedLicenseExpiry = d),
              suffixIcon:
                  const Icon(Icons.calendar_today, color: Color(0xFF0066CC)),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (_selectedLicenseExpiry != null &&
                    _selectedLicenseExpiry!.isBefore(DateTime.now())) {
                  return 'License must not be expired';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Upload License Photos',
              style: GoogleFonts.geologica(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildImageUploadBox(
                    title: 'Front *',
                    imageBytes: _licenseFrontBytes,
                    onTap: () => _pickImage('licenseFront'),
                    height: 140,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageUploadBox(
                    title: 'Back *',
                    imageBytes: _licenseBackBytes,
                    onTap: () => _pickImage('licenseBack'),
                    height: 140,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _vehicleKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Information',
              style: GoogleFonts.geologica(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Car must be 15 years old or newer',
              style: GoogleFonts.geologica(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _vinController,
              label: 'VIN (Vehicle Identification Number) *',
              hintText: '17 characters',
              maxLength: 17,
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (v!.length != 17) return 'VIN must be 17 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _makeController,
                    label: 'Make *',
                    hintText: 'Toyota',
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _modelController,
                    label: 'Model *',
                    hintText: 'Camry',
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _yearController,
                    label: 'Year *',
                    hintText: '2022',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      final year = int.tryParse(v!);
                      if (year == null) return 'Invalid year';
                      if (year < DateTime.now().year - 15)
                        return 'Must be 15 years or newer';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _colorController,
                    label: 'Color *',
                    hintText: 'Silver',
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _licensePlateController,
              label: 'License Plate Number *',
              textCapitalization: TextCapitalization.characters,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _doors,
                        isExpanded: true,
                        items: [2, 4, 5]
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    '$d Doors',
                                    style: GoogleFonts.geologica(),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _doors = v!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _seats,
                        isExpanded: true,
                        items: [2, 4, 5, 7, 8]
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    '$s Seats',
                                    style: GoogleFonts.geologica(),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _seats = v!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Vehicle Registration',
              style: GoogleFonts.geologica(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildImageUploadBox(
              title: 'Upload Registration Photo',
              imageBytes: _registrationPhotoBytes,
              onTap: () => _pickImage('registration'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _insuranceKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insurance Information',
              style: GoogleFonts.geologica(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Must have rideshare endorsement or commercial coverage',
                      style: GoogleFonts.geologica(
                        color: Colors.red[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _insuranceProviderController,
              label: 'Insurance Provider *',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _insurancePolicyController,
              label: 'Policy Number *',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _insuranceExpiryController,
              label: 'Expiration Date *',
              readOnly: true,
              onTap: () => _selectDate(_insuranceExpiryController,
                  (d) => _selectedInsuranceExpiry = d),
              suffixIcon:
                  const Icon(Icons.calendar_today, color: Color(0xFF0066CC)),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (_selectedInsuranceExpiry != null &&
                    _selectedInsuranceExpiry!.isBefore(DateTime.now())) {
                  return 'Insurance must not be expired';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: CheckboxListTile(
                title: Text(
                  'I have Rideshare Endorsement',
                  style: GoogleFonts.geologica(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Required for rideshare drivers',
                  style: GoogleFonts.geologica(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                value: _hasRideshareEndorsement,
                onChanged: (v) => setState(() => _hasRideshareEndorsement = v!),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF0066CC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildImageUploadBox(
              title: 'Upload Insurance Card *',
              imageBytes: _insurancePhotoBytes,
              onTap: () => _pickImage('insurance'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              'Background Check Authorization',
              style: GoogleFonts.geologica(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'By checking the box below, I authorize KVA to conduct a background check including criminal history, driving record, and identity verification. I understand this is required for driver approval.',
                style: GoogleFonts.geologica(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _backgroundCheckConsent
                      ? const Color(0xFF0066CC)
                      : Colors.grey[300]!,
                ),
              ),
              child: CheckboxListTile(
                title: Text(
                  'I agree to the background check *',
                  style: GoogleFonts.geologica(fontWeight: FontWeight.w500),
                ),
                value: _backgroundCheckConsent,
                onChanged: (v) => setState(() => _backgroundCheckConsent = v!),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF0066CC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Information',
            style: GoogleFonts.geologica(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review all details before submitting',
            style: GoogleFonts.geologica(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          _buildReviewSection('Personal Information', [
            'Name: ${_firstNameController.text} ${_middleNameController.text} ${_lastNameController.text}',
            'DOB: ${_dateOfBirthController.text}',
            'Phone: ${_phoneController.text}',
            'Email: ${_emailController.text}',
          ]),
          _buildReviewSection('Address', [
            _streetAddressController.text,
            '${_cityController.text}, ${_stateController.text} ${_zipCodeController.text}',
          ]),
          _buildReviewSection('Driver\'s License', [
            'Number: ${_licenseNumberController.text}',
            'State: ${_licenseStateController.text}',
            'Expires: ${_licenseExpiryController.text}',
          ]),
          _buildReviewSection('Vehicle', [
            '${_yearController.text} ${_makeController.text} ${_modelController.text}',
            'Color: ${_colorController.text}',
            'VIN: ${_vinController.text}',
            'Plate: ${_licensePlateController.text}',
          ]),
          _buildReviewSection('Insurance', [
            'Provider: ${_insuranceProviderController.text}',
            'Policy: ${_insurancePolicyController.text}',
            'Expires: ${_insuranceExpiryController.text}',
            'Rideshare Endorsement: ${_hasRideshareEndorsement ? "Yes" : "No"}',
          ]),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0066CC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFF0066CC).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF0066CC)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'After submitting, you will verify your phone number via OTP. Your application will then be reviewed by our team.',
                    style: GoogleFonts.geologica(
                      fontSize: 13,
                      color: const Color(0xFF0066CC),
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

  Widget _buildReviewSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF0066CC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.geologica(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  item,
                  style: GoogleFonts.geologica(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildImageUploadBox({
    required String title,
    required Uint8List? imageBytes,
    required VoidCallback onTap,
    double height = 160,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: imageBytes != null ? Colors.green : Colors.grey[300]!,
            width: imageBytes != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: imageBytes != null ? Colors.green[50] : Colors.grey[50],
        ),
        child: imageBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.memory(imageBytes, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 30,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.geologica(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to upload',
                    style: GoogleFonts.geologica(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
