import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:refillappjava/settingspage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import 'package:refillappjava/db_helper.dart'; // Import your DBHelper
import 'package:http/http.dart' as http; // Import http for API requests
import 'orderpage.dart'; // Import OrderPage

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  GoogleMapController? _controller;
  LatLng _currentLocation = LatLng(12.9313983, 77.6067696);
  int _selectedIndex = 0;
  DBHelper _dbHelper = DBHelper(); // Create an instance of DBHelper
  Map<String, dynamic>? _vehicleDetails; // Store vehicle details
  List<Map<String, dynamic>> _stations = []; // Store list of stations
  LatLng? _selectedStationLocation; // Store the selected station location
  Map<String, dynamic>? _selectedStation; // Store selected station details
  double _selectedStationDistance = 0.0; // Store the distance to the selected station

  @override
  void initState() {
    super.initState();
    _checkLocationPermission(); // Check for location permission on init
  }

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

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) { // Assuming "Settings" is the third tab
      String mobileNumber = await getMobileNumberFromFile(); // Wait for the mobile number
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsPage(userMobileNumber: mobileNumber), // Pass the fetched mobile number
        ),
      );
    } else if (index == 1) { // Navigate to MapPage (now it's OrderPage)
      if (_selectedStationLocation != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderPage(
              stationName: _stations.firstWhere((station) => station['location'] == _selectedStationLocation)['name'], // Pass the selected station name
              currentLocation: _currentLocation, // Pass the user's current location
              distance: _selectedStationDistance, // Pass the distance
            ),
          ),
        );
      } else {
        // Handle case where no station is selected
        print("No station selected.");
      }
    }
  }

  // Check and request location permission
  Future<void> _checkLocationPermission() async {
    var permissionStatus = await Permission.location.status;

    if (permissionStatus.isGranted) {
      _getCurrentLocation();
    } else if (permissionStatus.isDenied) {
      // Request permission
      if (await Permission.location.request().isGranted) {
        // Permission granted, get the location
        _getCurrentLocation();
      } else {
        // Handle the case when permission is denied
        print("Location permission denied.");
      }
    } else if (permissionStatus.isPermanentlyDenied) {
      // Handle the case when permission is permanently denied
      openAppSettings(); // Optionally open app settings to allow users to enable permissions
    }
  }

  // Get user's current location and fetch nearest stations
  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _controller?.moveCamera(CameraUpdate.newLatLng(_currentLocation));
    });

    // Read vehicle number from file and fetch details
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/current_number.txt');
    if (await file.exists()) {
      String vehicleNumber = await file.readAsString();
      await _fetchVehicleDetails(vehicleNumber.trim()); // Fetch vehicle details
    }
  }

  Future<void> _fetchVehicleDetails(String vehicleNumber) async {
    print("Running fetchVehicleDetails");
    _vehicleDetails = await _dbHelper.getVehicleDetailsByNumber(vehicleNumber);
    if (_vehicleDetails != null && _vehicleDetails!.isNotEmpty) {
      // Proceed with vehicle details
      String fuelType = _vehicleDetails!['fuel_type'];
      // Fetch and display nearest stations based on fuel type
      await _fetchNearestStations(fuelType, _currentLocation.latitude, _currentLocation.longitude);
    } else {
      // Handle case where vehicle details are not found
      print('No vehicle details found for number: $vehicleNumber');
    }
  }

  // Fetch nearest stations based on fuel type
  Future<void> _fetchNearestStations(String fuelType, double latitude, double longitude) async {
    print("latitude is $latitude");
    print("longitude is $longitude");
    String placeType = fuelType.toLowerCase() == 'electric' ? 'charging_station&keyword=\'charging\'' : 'gas_station';
    String apiKey = 'AIzaSyDjHEuqC4JSCGSvTZ-0zOJvkvVidAU7eDc';
    String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=3000&type=$placeType&key=$apiKey';
    print(url);
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List results = data['results'];

        if (results.isNotEmpty) {
          // Process and store results
          setState(() {
            _stations = results.map((station) {
              return {
                'name': station['name'],
                'address': station['vicinity'],
                'location': LatLng(
                  station['geometry']['location']['lat'],
                  station['geometry']['location']['lng'],
                ),
              };
            }).toList();
          });
        } else {
          print('No stations found nearby.');
        }
      } else {
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  // Select a station and move the map to its location
  void _onStationSelected(Map<String, dynamic> station) {
    setState(() {
      _selectedStation = station;
      _selectedStationLocation = station['location'];
      _selectedStationDistance = Geolocator.distanceBetween(
        _currentLocation.latitude,
        _currentLocation.longitude,
        station['location'].latitude,
        station['location'].longitude,
      ) / 1000; // Convert to kilometers
      _controller?.moveCamera(CameraUpdate.newLatLng(station['location']));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Your Current Location'),
          backgroundColor: Color(0xFF16560c),
        ),
        body: Column(
          children: [
            // Map covering half the screen
            Expanded(
              flex: 1,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation,
                  zoom: 14.0,
                ),
                myLocationEnabled: true,
                onMapCreated: (controller) {
                  _controller = controller;
                },
                markers: _selectedStationLocation != null
                    ? {
                  Marker(
                    markerId: MarkerId('selected_station'),
                    position: _selectedStationLocation!,
                  ),
                }
                    : {},
              ),
            ),
            // List of stations
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: _stations.length,
                itemBuilder: (context, index) {
                  var station = _stations[index];
                  double distance = Geolocator.distanceBetween(
                    _currentLocation.latitude,
                    _currentLocation.longitude,
                    station['location'].latitude,
                    station['location'].longitude,
                  ) / 1000; // Convert to kilometers
                  return ListTile(
                    title: Text(station['name']),
                    subtitle: Text('${distance.toStringAsFixed(2)} km away'),
                    onTap: () {
                      _onStationSelected(station);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
        icon: Icon(Icons.location_on),
    label: 'Location',
    ),
    BottomNavigationBarItem(
    icon: Icon(Icons.map),
    label: 'Map',
    ),
    BottomNavigationBarItem(
    icon: Icon(Icons.settings),
    label: 'Settings',
    ),
    ],
    currentIndex: _selectedIndex,
    selectedItemColor: Color(0xFF16560c),
    onTap: _onItemTapped,
        ),
    );
  }
}