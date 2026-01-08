import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import '../../data/providers/app_provider.dart';

class InsurancePhotoScreen extends StatefulWidget {
  const InsurancePhotoScreen({super.key});

  @override
  State<InsurancePhotoScreen> createState() => _InsurancePhotoScreenState();
}

class _InsurancePhotoScreenState extends State<InsurancePhotoScreen> {
  final _ssnController = TextEditingController();
  XFile? _insuranceImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _insuranceImage = image;
        _imageBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Registration'),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Final Step: Insurance & Background Check',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _insuranceImage != null
                    ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                            Text('Upload Insurance Photo', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            
            TextFormField(
              controller: _ssnController,
              decoration: const InputDecoration(
                labelText: 'Social Security Number (for background check)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            const Text('✓ All information will be securely processed'),
            const Text('✓ Background check typically takes 1-2 business days'),
            const Spacer(),
            
            ElevatedButton(
              onPressed: (_isLoading || _insuranceImage == null) ? null : () => _completeRegistration(registrationData),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Complete Registration', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeRegistration(Map<String, dynamic> data) async {
    if (_ssnController.text.isEmpty || _insuranceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields and upload insurance photo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<AppProvider>();
    
    final completeData = {
      ...data,
      'ssn': _ssnController.text,
      'insuranceImageUrl': _insuranceImage!.path,
    };

    final success = await provider.completeDriverRegistration(completeData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration completed successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.')),
      );
    }
  }
}