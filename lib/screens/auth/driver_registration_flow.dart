import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppProvider>();

      // First, register/update the user
      final userData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'role': 'driver',
      };

      print('📝 Starting driver registration flow...');
      print('📝 User data: $userData');

      // Register user first if not already done
      final userResponse = await ApiService.registerUser(userData);
      print('📝 User registration response: $userResponse');

      // Request OTP for verification
      print('📱 Requesting OTP for phone: ${_phoneController.text.trim()}');
      final otpResponse =
          await ApiService.requestOtp(_phoneController.text.trim());
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
          'phoneNumber': _phoneController.text.trim(),
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
      appBar: AppBar(
        title: Text(_stepTitles[_currentStep]),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(6, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? const Color(0xFF0066CC)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Text('Step ${_currentStep + 1} of 6',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),

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
            padding: const EdgeInsets.all(16),
            child: _currentStep < 5
                ? ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Continue',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  )
                : ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit & Verify Phone',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _personalInfoKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Your legal name must match your Driver\'s License exactly',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),

            // Profile Photo
            Center(
              child: GestureDetector(
                onTap: () => _pickImage('profile'),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profilePhotoBytes != null
                          ? MemoryImage(_profilePhotoBytes!)
                          : null,
                      child: _profilePhotoBytes == null
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0066CC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Center(
                child: Text('Profile Photo *',
                    style: TextStyle(fontSize: 12, color: Colors.grey))),
            const SizedBox(height: 24),

            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                  labelText: 'First Name *', border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _middleNameController,
              decoration: const InputDecoration(
                  labelText: 'Middle Name (Optional)',
                  border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                  labelText: 'Last Name *', border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _dateOfBirthController,
              readOnly: true,
              onTap: () => _selectDate(
                  _dateOfBirthController, (d) => _selectedDateOfBirth = d),
              decoration: const InputDecoration(
                labelText: 'Date of Birth *',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
                hintText: 'MM/DD/YYYY',
              ),
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
            const SizedBox(height: 12),

            TextFormField(
              controller: _ssnController,
              decoration: const InputDecoration(
                labelText: 'Social Security Number *',
                border: OutlineInputBorder(),
                hintText: 'XXX-XX-XXXX',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Required for background check' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
                hintText: '+1234567890',
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: 'Email *', border: OutlineInputBorder()),
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

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _addressKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Residential Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Must be a physical US address (P.O. Boxes are not accepted)',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetAddressController,
              decoration: const InputDecoration(
                  labelText: 'Street Address *', border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                  labelText: 'City *', border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                        labelText: 'State *', border: OutlineInputBorder()),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _zipCodeController,
                    decoration: const InputDecoration(
                        labelText: 'ZIP Code *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Proof of Residency',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'If your license address is different, upload a utility bill or bank statement',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _licenseKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Driver\'s License',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Must be a valid in-state license for where you intend to drive',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _licenseNumberController,
              decoration: const InputDecoration(
                  labelText: 'License Number *', border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _licenseStateController,
              decoration: const InputDecoration(
                  labelText: 'Issuing State *', border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _licenseExpiryController,
              readOnly: true,
              onTap: () => _selectDate(
                  _licenseExpiryController, (d) => _selectedLicenseExpiry = d),
              decoration: const InputDecoration(
                labelText: 'Expiration Date *',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (_selectedLicenseExpiry != null &&
                    _selectedLicenseExpiry!.isBefore(DateTime.now())) {
                  return 'License must not be expired';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text('Upload License Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildImageUploadBox(
                    title: 'Front *',
                    imageBytes: _licenseFrontBytes,
                    onTap: () => _pickImage('licenseFront'),
                    height: 120,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImageUploadBox(
                    title: 'Back *',
                    imageBytes: _licenseBackBytes,
                    onTap: () => _pickImage('licenseBack'),
                    height: 120,
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
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _vehicleKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vehicle Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Car must be 15 years old or newer',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vinController,
              decoration: const InputDecoration(
                labelText: 'VIN (Vehicle Identification Number) *',
                border: OutlineInputBorder(),
                hintText: '17 characters',
              ),
              maxLength: 17,
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (v!.length != 17) return 'VIN must be 17 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _makeController,
                    decoration: const InputDecoration(
                        labelText: 'Make *',
                        border: OutlineInputBorder(),
                        hintText: 'Toyota'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                        labelText: 'Model *',
                        border: OutlineInputBorder(),
                        hintText: 'Camry'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                        labelText: 'Year *',
                        border: OutlineInputBorder(),
                        hintText: '2022'),
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
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(
                        labelText: 'Color *',
                        border: OutlineInputBorder(),
                        hintText: 'Silver'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _licensePlateController,
              decoration: const InputDecoration(
                  labelText: 'License Plate Number *',
                  border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _doors,
                    decoration: const InputDecoration(
                        labelText: 'Doors', border: OutlineInputBorder()),
                    items: [2, 4, 5]
                        .map((d) =>
                            DropdownMenuItem(value: d, child: Text('$d')))
                        .toList(),
                    onChanged: (v) => setState(() => _doors = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _seats,
                    decoration: const InputDecoration(
                        labelText: 'Seats', border: OutlineInputBorder()),
                    items: [2, 4, 5, 7, 8]
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text('$s')))
                        .toList(),
                    onChanged: (v) => setState(() => _seats = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Vehicle Registration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _insuranceKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Insurance Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Must have rideshare endorsement or commercial coverage',
                style: TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _insuranceProviderController,
              decoration: const InputDecoration(
                  labelText: 'Insurance Provider *',
                  border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _insurancePolicyController,
              decoration: const InputDecoration(
                  labelText: 'Policy Number *', border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _insuranceExpiryController,
              readOnly: true,
              onTap: () => _selectDate(_insuranceExpiryController,
                  (d) => _selectedInsuranceExpiry = d),
              decoration: const InputDecoration(
                labelText: 'Expiration Date *',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (_selectedInsuranceExpiry != null &&
                    _selectedInsuranceExpiry!.isBefore(DateTime.now())) {
                  return 'Insurance must not be expired';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('I have Rideshare Endorsement'),
              subtitle: const Text('Required for rideshare drivers',
                  style: TextStyle(fontSize: 12)),
              value: _hasRideshareEndorsement,
              onChanged: (v) => setState(() => _hasRideshareEndorsement = v!),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            _buildImageUploadBox(
              title: 'Upload Insurance Card *',
              imageBytes: _insurancePhotoBytes,
              onTap: () => _pickImage('insurance'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Background Check Authorization',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'By checking the box below, I authorize KVA to conduct a background check including criminal history, driving record, and identity verification. I understand this is required for driver approval.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('I agree to the background check *'),
              value: _backgroundCheckConsent,
              onChanged: (v) => setState(() => _backgroundCheckConsent = v!),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review Your Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Please review all details before submitting',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'After submitting, you will verify your phone number via OTP. Your application will then be reviewed by our team.',
                    style: TextStyle(fontSize: 12),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(item, style: const TextStyle(fontSize: 14)),
              )),
        ],
      ),
    );
  }

  Widget _buildImageUploadBox({
    required String title,
    required Uint8List? imageBytes,
    required VoidCallback onTap,
    double height = 150,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
              color: imageBytes != null ? Colors.green : Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: imageBytes != null ? Colors.green[50] : null,
        ),
        child: imageBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(imageBytes, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(color: Colors.grey)),
                ],
              ),
      ),
    );
  }
}
