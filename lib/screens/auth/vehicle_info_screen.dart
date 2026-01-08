import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/providers/app_provider.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  int _doors = 4;
  int _seats = 5;
  dynamic _licenseImageFront;
  dynamic _licenseImageBack;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    final provider = context.read<AppProvider>();
    final hasCompleted = await provider.hasCompletedDriverRegistration();
    if (hasCompleted && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    _insuranceNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          if (isFront) {
            _licenseImageFront = bytes;
          } else {
            _licenseImageBack = bytes;
          }
        });
      } else {
        setState(() {
          if (isFront) {
            _licenseImageFront = File(image.path);
          } else {
            _licenseImageBack = File(image.path);
          }
        });
      }
    }
  }

  Future<void> _submitVehicleInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<AppProvider>();
    final vehicleData = {
      'make': _makeController.text.trim(),
      'model': _modelController.text.trim(),
      'year': int.parse(_yearController.text.trim()),
      'color': _colorController.text.trim(),
      'doors': _doors,
      'seats': _seats,
      'licensePlate': _licensePlateController.text.trim(),
      'insuranceNumber': _insuranceNumberController.text.trim(),
      'licenseImageUrl': kIsWeb ? '' : (_licenseImageFront?.path ?? ''),
      'insuranceImageUrl': kIsWeb ? '' : (_licenseImageBack?.path ?? ''),
    };

    final success = await provider.completeDriverRegistration(vehicleData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Information'),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _makeController,
                decoration: const InputDecoration(
                  labelText: 'Make (e.g., Toyota)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model (e.g., Axio)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Year (e.g., 2017)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  final year = int.tryParse(value!);
                  if (year == null || year < 1990 || year > DateTime.now().year + 1) {
                    return 'Enter valid year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color (e.g., White)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Doors'),
                        DropdownButtonFormField<int>(
                          value: _doors,
                          items: [2, 4, 5].map((doors) => 
                            DropdownMenuItem(value: doors, child: Text('$doors'))
                          ).toList(),
                          onChanged: (value) => setState(() => _doors = value!),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Seats'),
                        DropdownButtonFormField<int>(
                          value: _seats,
                          items: [2, 4, 5, 7, 8].map((seats) => 
                            DropdownMenuItem(value: seats, child: Text('$seats'))
                          ).toList(),
                          onChanged: (value) => setState(() => _seats = value!),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _licensePlateController,
                decoration: const InputDecoration(
                  labelText: 'License Plate (e.g., KDA-123A)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _insuranceNumberController,
                decoration: const InputDecoration(
                  labelText: 'Insurance Number (e.g., INS-9988)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              
              const Text('License Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // License Front Image
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _licenseImageFront != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.memory(_licenseImageFront, fit: BoxFit.cover)
                            : Image.file(_licenseImageFront, fit: BoxFit.cover),
                      )
                    : InkWell(
                        onTap: () => _pickImage(true),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                            Text('License Front', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              
              // License Back Image
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _licenseImageBack != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.memory(_licenseImageBack, fit: BoxFit.cover)
                            : Image.file(_licenseImageBack, fit: BoxFit.cover),
                      )
                    : InkWell(
                        onTap: () => _pickImage(false),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                            Text('License Back', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submitVehicleInfo,
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
      ),
    );
  }
}