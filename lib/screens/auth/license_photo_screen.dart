import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html' as html;

class LicensePhotoScreen extends StatefulWidget {
  const LicensePhotoScreen({super.key});

  @override
  State<LicensePhotoScreen> createState() => _LicensePhotoScreenState();
}

class _LicensePhotoScreenState extends State<LicensePhotoScreen> {
  XFile? _licenseImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _licenseImage = image;
        _imageBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take a photo of your Drivers Licenses'),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Review the background check disclosure and authorization',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Background check disclosure and authorization text would go here...',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _licenseImage != null
                    ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                            Text('Take Photo', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            const Text('Clear driver license required'),
            const Spacer(),
            
            ElevatedButton(
              onPressed: _licenseImage != null ? () {
                final completeData = {
                  ...registrationData,
                  'licenseImageUrl': _licenseImage!.path,
                };
                Navigator.pushNamed(context, '/insurance-photo', arguments: completeData);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('I Agree & Acknowledge', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}