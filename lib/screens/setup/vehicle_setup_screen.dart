import 'package:flutter/material.dart';

class VehicleSetupScreen extends StatefulWidget {
  const VehicleSetupScreen({super.key});

  @override
  State<VehicleSetupScreen> createState() => _VehicleSetupScreenState();
}

class _VehicleSetupScreenState extends State<VehicleSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _vehicleType = 'Sedan';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vehicle Setup',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tell us about your vehicle',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Vehicle Type
                DropdownButtonFormField<String>(
                  value: _vehicleType,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type / Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Sedan', 'SUV', 'Hatchback', 'Van', 'Truck']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _vehicleType = value!);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Vehicle Color
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Vehicle Color',
                    hintText: 'White, Other',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Plate Number
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Plate Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Passenger Seats
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Passenger Seats',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['2', '4', '5', '6', '7', '8+']
                      .map((seats) => DropdownMenuItem(
                            value: seats,
                            child: Text(seats),
                          ))
                      .toList(),
                  onChanged: (value) {},
                ),
                
                const SizedBox(height: 16),
                
                // Passenger Doors
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Passenger Doors',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['2', '4', '5']
                      .map((doors) => DropdownMenuItem(
                            value: doors,
                            child: Text(doors),
                          ))
                      .toList(),
                  onChanged: (value) {},
                ),
                
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/vehicle-details');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}