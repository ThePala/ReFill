import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RegistrationPage(),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _mobileNumber;
  int? _uid; // Change this to int to store the UID

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Set mobile number
  void _setMobileNumber(String mobileNumber) {
    setState(() {
      _mobileNumber = mobileNumber;
    });
  }

  // Set UID
  void _setUid(int uid) { // Updated to accept an int
    setState(() {
      _uid = uid; // Directly set the UID
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: -110,
            child: Image.asset(
              'images/rect2svg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 60),
              Image.asset('images/refilltext.png', height: 80),
              PreferredSize(
                preferredSize: const Size.fromHeight(50.0),
                child: Container(
                  color: Colors.transparent,
                  child: TabBar(
                    labelStyle: const TextStyle(fontSize: 16, fontFamily: 'Inter'),
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Personal Details'),
                      Tab(text: 'Vehicle Details'),
                    ],
                    indicatorColor: const Color(0xFF16560c),
                    labelColor: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    PersonalDetailsForm(
                      onMobileNumberSubmitted: _setMobileNumber,
                      onUidSubmitted: _setUid, // Handle UID
                    ),
                    VehicleDetailsForm(
                      uid: _uid ?? 0, // This is fine, as it remains an int
                      mobileNumber: _mobileNumber ?? '', // This is also fine
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class PersonalDetailsForm extends StatefulWidget {
  final Function(String) onMobileNumberSubmitted;
  final Function(int) onUidSubmitted;

  PersonalDetailsForm({
    required this.onMobileNumberSubmitted,
    required this.onUidSubmitted,
  });

  @override
  _PersonalDetailsFormState createState() => _PersonalDetailsFormState();
}

class _PersonalDetailsFormState extends State<PersonalDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final TextStyle buttonTextStyle2 = const TextStyle(
    color: Colors.white,
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  // Function to send the POST request
  Future<void> _sendPersonalDetails() async {
    final String url = 'http://13.232.124.107:5000/register_users'; // Replace with your backend URL

    Map<String, String> personalDetails = {
      'aadhaar_card_number': _aadhaarController.text,
      'mobile_number': _mobileController.text,
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'address': _addressController.text,
    };

    print("sending this ");print(personalDetails);


    try {

      //print("debug1");
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(personalDetails),
      );

      //print("waiting");

      if (response.statusCode == 201) {
        //print("debug2");
        final responseData = jsonDecode(response.body);
        final String uidString = responseData['uid']; // Get UID as a String
        //print("debug3");
        // Convert the UID to an integer if it's a valid string
        final int uid = int.tryParse(uidString) ?? 0; // Provide a fallback value in case parsing fails
        //print("debug4");
        // Pass the mobile number and UID (as an int) back to the parent widget
        widget.onMobileNumberSubmitted(_mobileController.text);
        //print("debug5");
        widget.onUidSubmitted(uid); // Pass the UID as an int now
        //print("debug6");
        print('Personal details sent successfully');
        print('User ID: $uid');
      } else {
        print('Status code: ${response.statusCode}');
        final responseData = jsonDecode(response.body);
        print('Error message: ${responseData['message']}');
      }
    } catch (error) {
      print('SEEError occurred: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(height: 20),
              // Aadhaar Card Number Field
              TextFormField(
                controller: _aadhaarController,
                decoration: InputDecoration(
                  labelText: 'Aadhaar Card Number *',
                  hintText: '1234 1234 1234',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Aadhaar Card Number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              // Mobile Number Field
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number *',
                  hintText: '+91 12345 67890',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Mobile Number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              // First Name and Last Name Fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name *',
                        hintText: 'Raj',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your First Name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name *',
                        hintText: 'Sharma',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your Last Name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Address Field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address *',
                  hintText: 'Ex: 124/3, 3rd Main Rd, S.G Palya, Bengaluru',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _sendPersonalDetails(); // Call the POST request
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF16560c),
                    minimumSize: const Size(120, 0),
                    maximumSize: const Size(200, 65),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: buttonTextStyle2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class VehicleDetailsForm extends StatefulWidget {
  final int uid; // Receive UID from the registration process
  final String mobileNumber; // Receive mobile number from the registration process

  const VehicleDetailsForm({required this.uid, required this.mobileNumber, Key? key}) : super(key: key);

  @override
  _VehicleDetailsFormState createState() => _VehicleDetailsFormState();
}

class _VehicleDetailsFormState extends State<VehicleDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _chassisNumberController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  String? _vehicleType;
  String? _fuelType;

  // List of dropdown options for vehicle types
  final List<String> _vehicleTypes = ['2-Wheeler', '3-Wheeler', '4-Wheeler'];

  // List of dropdown options for fuel types
  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'CNG', 'LPG', 'Electric'];

  // Function to send the POST request for vehicle details
  Future<void> _sendVehicleDetails() async {
    final String url = 'http://13.232.124.107:5000/register_vehicles'; // Replace with your backend URL

    // Prepare the data
    Map<String, dynamic> vehicleDetails = {
      'vehicle_number': _vehicleNumberController.text,
      'vehicle_color': _colorController.text,
      'vehicle_type': _vehicleType,
      'chassis_number': _chassisNumberController.text,
      'fuel_type': _fuelType,
      'vehicle_make_and_model': _modelController.text,
      'user_mobile_number': widget.mobileNumber.toString(), // Use the mobile number passed to the form
      'uid': widget.uid.toString(), // Send the UID from registration
    };

    print(vehicleDetails);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(vehicleDetails),
      );

      if (response.statusCode == 201) {
        // Success - Show a success message
        print('Vehicle details sent successfully');
        print(response.body);
      } else {
        // Error - Handle the error
        print('Status code: ${response.statusCode}');
        print('Error: ${response.body}');
      }
    } catch (error) {
      print('Error occurred: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _vehicleNumberController,
                decoration: InputDecoration(
                  labelText: 'Vehicle Number *',
                  hintText: 'KA-01-1234',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the Vehicle Number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _chassisNumberController,
                decoration: InputDecoration(
                  labelText: 'Chassis Number *',
                  hintText: '1234567890',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the Chassis Number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _modelController,
                decoration: InputDecoration(
                  labelText: 'Vehicle Make and Model *',
                  hintText: 'Ex: Honda City',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the Vehicle Make and Model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _vehicleType,
                decoration: InputDecoration(
                  labelText: 'Vehicle Type *',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
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
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _fuelType,
                decoration: InputDecoration(
                  labelText: 'Fuel Type *',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
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
              const SizedBox(height: 10),
              TextFormField(
                controller: _colorController,
                decoration: InputDecoration(
                  labelText: 'Vehicle Color *',
                  hintText: 'Ex: White',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the Vehicle Color';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _sendVehicleDetails(); // Call the POST request for vehicle details
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF16560c),
                    minimumSize: const Size(120, 0),
                    maximumSize: const Size(200, 65),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
