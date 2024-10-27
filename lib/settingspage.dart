import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // To get directory paths
import 'package:refillappjava/db_helper.dart'; // Ensure your DBHelper is correctly imported
import 'package:refillappjava/AddVehiclePage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'package:shared_preferences/shared_preferences.dart'; // Required for getDatabasesPath
import 'package:refillappjava/locationpage.dart'; // Import LocationPage
import 'package:refillappjava/orderhistory.dart';
import 'package:http/http.dart' as http;


class SettingsPage extends StatefulWidget {
  final String userMobileNumber;

  SettingsPage({required this.userMobileNumber});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  DBHelper _dbHelper = DBHelper();
  Map<String, dynamic>? _userDetails;
  List<Map<String, dynamic>> _vehicleDetails = [];
  String? _selectedVehicle;
  int _selectedIndex = 0; // Track the selected tab index
  String? _profileImagePath; // Holds the path of the profile image

  @override
  void initState() {
    super.initState();
    _fetchDetails();
    _dbHelper.printAllUsersAndVehicles();
  }

  Future<void> _fetchDetails() async {
    var userDetails = await _dbHelper.getUserDetails(widget.userMobileNumber);
    var vehicleDetails = await _dbHelper.getVehicleDetails(widget.userMobileNumber);

    setState(() {
      _userDetails = userDetails;
      _vehicleDetails = List<Map<String, dynamic>>.from(vehicleDetails); // Convert to a mutable list
    });
  }

  Future<void> _storeCurrentVehicleNumber(String vehicleNumber) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/current_number.txt');

    try {
      await file.writeAsString(vehicleNumber);
      print('Stored current vehicle number: $vehicleNumber');
    } catch (e) {
      print('Error writing vehicle number to file: $e');
    }
  }

  Future<void> _logoutAndDeleteData() async {
    // Show confirmation dialog
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout Confirmation'),
          content: Text('Are you sure you want to log out and delete all data?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel logout
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm logout
              },
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      // Clear Shared Preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear Secure Storage (if used)
      final secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll(); // This will clear all securely stored items

      await _dbHelper.close(); // Make sure DBHelper has a close method

      // Get a reference to the open database
      final db = await _dbHelper.database;

      // Wrap in a transaction for safety
      await db.transaction((txn) async {
        // List all your table names and clear data from each one
        await txn.execute('DELETE FROM users');
        await txn.execute('DELETE FROM vehicles');
        // Add more DELETE statements for other tables if needed
      });

      // Clear the cache
      final cacheDir = Directory((await getTemporaryDirectory()).path);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        print("Deleted cache at: ${cacheDir.path}");
      }

      // Delete the mobile_number.txt file in the custom folder
      final directory = await getApplicationDocumentsDirectory();
      final mobileFile = File('${directory.path}/mobile_number.txt');
      if (await mobileFile.exists()) {
        await mobileFile.delete();
      }

      // Navigate to login or onboarding page
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login', // Change this to your actual login or onboarding route
            (Route<dynamic> route) => false, // Remove all previous routes
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery); // Change to ImageSource.camera to take a picture

    if (image != null) {
      setState(() {
        _profileImagePath = image.path; // Update the profile image path
      });
    }
  }

  // Function to delete vehicle from backend
  Future<void> _deleteVehicleFromBackend(String vehicleNumber) async {
    try {
      final response = await http.post(
        Uri.parse('http://13.232.124.107:5000/delete_vehicle'), // Update with your API URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'vehicle_number': vehicleNumber}),
      );

      if (response.statusCode == 200) {
        print('Vehicle deleted from backend.');
      } else {
        print('Failed to delete vehicle from backend: ${response.body}');
      }
    } catch (e) {
      print('Error deleting vehicle from backend: $e');
    }
  }

  // Handle bottom navigation bar taps
  void _onItemTapped(int index) {
    if (index == 0) {
      // If the first tab (Location) is tapped
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LocationPage()),
      );
    } else if (index == 1) {
      // If the second tab (Settings) is already selected, do nothing
      // Or you can refresh the settings page if necessary
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: _userDetails == null && _vehicleDetails.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildUserInfo(),
          _buildOrderHistoryButton(),
          _vehicleDetails.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('No vehicles found for this user.'),
          )
              : _buildVehicleList(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddVehiclePage()),
                );
              },
              child: Text('Add Vehicle'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xfff86c6c),
        onPressed: _logoutAndDeleteData,
        child: Icon(Icons.logout),
        tooltip: 'Logout',
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF16560c),
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Update the selected index
          });
          _onItemTapped(index); // Handle the tap
        },
      ),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage, // Open image picker on tap
            child: CircleAvatar(
              radius: 40,
              backgroundImage: _profileImagePath != null
                  ? FileImage(File(_profileImagePath!))
                  : AssetImage('images/logo.png') as ImageProvider, // Use a default profile image
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User Details', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Name: ${_userDetails!['first_name']} ${_userDetails!['last_name']}'),
                Text('Mobile: ${_userDetails!['mobile_number']}'),
                Text('Address: ${_userDetails!['address']}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function to build the Order History Button
  Widget _buildOrderHistoryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderHistoryPage(),
            ),
          );
        },
        child: Text('View Order History'),
      ),
    );
  }

  Widget _buildVehicleList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _vehicleDetails.length,
        itemBuilder: (context, index) {
          var vehicle = _vehicleDetails[index];

          return Dismissible(
            key: Key(vehicle['vehicle_number']), // Unique key for each item
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
              onDismissed: (direction) async {
                try {
                  // Ensure index is within bounds
                  if (index < 0 || index >= _vehicleDetails.length) {
                    print("Index out of bounds: $index");
                    return;
                  }

                  var vehicle = _vehicleDetails[index];
                  String vehicleNumber = vehicle['vehicle_number'] ?? '';
                  print("VEHICLE DELETED IS $vehicleNumber");

                  // Remove the item from the list immediately after dismissal
                  setState(() {
                    _vehicleDetails.removeAt(index);
                    print("Set state achieved");
                  });

                  // Call the delete API
                  print("Calling server delete");
                  await _deleteVehicleFromBackend(vehicleNumber);

                  // Delete from SQLite database
                  print("Calling local delete");
                  await _dbHelper.deleteVehicle(vehicleNumber);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vehicle deleted')),
                  );

                } catch (e) {
                  print("Error in onDismissed: $e");
                }
              },
            child: ListTile(
              title: Text(vehicle['make_and_model']),
              subtitle: Text('Vehicle Number: ${vehicle['vehicle_number']}'),
              trailing: Radio<String>(
                value: vehicle['vehicle_number'],
                groupValue: _selectedVehicle,
                onChanged: (String? value) {
                  setState(() {
                    _selectedVehicle = value;
                  });
                  if (value != null) {
                    _storeCurrentVehicleNumber(value);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
