import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'db_helper.dart';


class AddVehiclePage extends StatefulWidget {
  @override
  _AddVehiclePageState createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _chassisNumberController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  String? _vehicleType;
  String? _fuelType;
  final List<String> _vehicleTypes = ['2-Wheeler', '3-Wheeler', '4-Wheeler'];
  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'Electric'];

  DBHelper _dbHelper = DBHelper(); // Initialize DBHelper

  // Function to fetch the mobile number from the local storage
  Future<String> getMobileNumberFromFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/mobile_number.txt');
    try {
      String content = await file.readAsString();
      return content.length > 10 ? content.substring(0, 10) : content; // Read first 10 characters or less if the content is shorter
    } catch (e) {
      print('Error reading mobile number: $e');
      return '';
    }
  }

  // Function to send vehicle details to the backend and add to SQLite
  Future<void> _sendVehicleDetails() async {
    String mobileNumber = await getMobileNumberFromFile();

    // Fetch user details including UID from the database
    Map<String, dynamic>? userDetails = await _dbHelper.getUserDetails(mobileNumber);

    // Check if user details are found
    if (userDetails == null) {
      print('User not found in the database');
      return; // Handle user not found scenario
    }

    int uid = userDetails['id']; // Get UID from user details
    print("UID IS ");
    print(uid);

    // Create the vehicle details map, including the uid
    var vehicleData = {
      'user_mobile_number': mobileNumber,
      'vehicle_number': _vehicleNumberController.text,
      'chassis_number': _chassisNumberController.text,
      'vehicle_type': _vehicleType,
      'fuel_type': _fuelType,
      'make_and_model': _modelController.text,
      'color': _colorController.text,
      'uid': uid, // Add the uid to the vehicle data
    };

    var servervehicleData = {
      'user_mobile_number': mobileNumber,
      'vehicle_number': _vehicleNumberController.text,
      'chassis_number': _chassisNumberController.text,
      'vehicle_type': _vehicleType,
      'fuel_type': _fuelType,
      'vehicle_make_and_model': _modelController.text,
      'vehicle_color': _colorController.text,
      'uid': uid, // Add the uid to the vehicle data
    };
    print("data sent to server is");
    print(servervehicleData);

    // Insert the vehicle data into the SQLite database
    await _dbHelper.insertVehiclewUid(vehicleData, uid); // Make sure to pass uid if needed in insert method
    print('Vehicle added to local SQLite database');

    // Send the vehicle details to the backend server
    String apiUrl = 'http://13.232.124.107:5000/register_vehicles';
    var url = Uri.parse(apiUrl);

    var body = jsonEncode(servervehicleData);

    try {
      var response = await http.post(url, body: body, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 201) {
        print('Vehicle added to the server successfully');
        Navigator.pop(context); // Go back to the settings page after adding
      } else {
        print('Failed to add vehicle to the server');
      }
    } catch (e) {
      print('Error sending vehicle details to server: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Vehicle')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _vehicleNumberController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Number *',
                    hintText: 'KA-01-1234',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the Vehicle Number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _chassisNumberController,
                  decoration: InputDecoration(
                    labelText: 'Chassis Number *',
                    hintText: '1234567890',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the Chassis Number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Make and Model *',
                    hintText: 'Ex: Honda City',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the Vehicle Make and Model';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _vehicleType,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: _vehicleTypes.map((String type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _vehicleType = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the Vehicle Type';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _fuelType,
                  decoration: InputDecoration(
                    labelText: 'Fuel Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: _fuelTypes.map((String fuel) {
                    return DropdownMenuItem(
                      value: fuel,
                      child: Text(fuel),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _fuelType = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the Fuel Type';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _colorController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Color *',
                    hintText: 'Ex: White',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the Vehicle Color';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _sendVehicleDetails();
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
