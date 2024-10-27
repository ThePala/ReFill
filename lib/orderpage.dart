import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:refillappjava/db_helper.dart'; // Import your DBHelper

class OrderPage extends StatefulWidget {
  final String stationName; // Selected station passed from LocationPage
  final LatLng currentLocation; // Current location passed from LocationPage
  final double distance; // Distance from the selected station to current location

  OrderPage({
    required this.stationName,
    required this.currentLocation,
    required this.distance, // Accept distance as a parameter
  });

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  String _deliveringTo = '';
  String _deliveringFrom = '';
  String _carNumber = '';
  String _fuelType = '';
  double _fuelPrice = 0.0;
  double _liters = 1.0; // Default value to 1 liter
  double _additionalCharges = 0.0; // Additional charges based on distance

  late Razorpay _razorpay;

  final TextEditingController _deliveringToController = TextEditingController();
  final TextEditingController _deliveringFromController = TextEditingController();
  final TextEditingController _carNumberController = TextEditingController();
  final TextEditingController _fuelTypeController = TextEditingController();
  final TextEditingController _fuelPriceController = TextEditingController();

  DBHelper _dbHelper = DBHelper(); // Create an instance of DBHelper

  @override
  void initState() {
    super.initState();
    _setDefaultValues();

    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear(); // Clear the Razorpay instance when not needed
  }

  Future<void> _setDefaultValues() async {
    // Set Delivering To as user's current location
    _deliveringTo = '${widget.currentLocation.latitude}, ${widget.currentLocation.longitude}';
    _deliveringToController.text = _deliveringTo;

    // Set Delivering From as selected station
    _deliveringFrom = widget.stationName;
    _deliveringFromController.text = _deliveringFrom;

    // Read Car Number from file
    _carNumber = await _readCarNumberFromFile();
    _carNumberController.text = _carNumber;

    // Fetch Fuel Type from DB based on Car Number
    _fuelType = await _fetchFuelType(_carNumber);
    _fuelTypeController.text = _fuelType;

    // Fetch Fuel Price based on Fuel Type
    _fuelPrice = _fetchFuelPrice(_fuelType);
    _fuelPriceController.text = _fuelPrice.toStringAsFixed(2);

    // Calculate additional charges (50 per kilometer)
    _additionalCharges = widget.distance * 50;

    setState(() {});
  }

  Future<String> _readCarNumberFromFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/current_number.txt');
    if (await file.exists()) {
      String carNumber = await file.readAsString();
      return carNumber.trim();
    }
    return '';
  }

  Future<String> _fetchFuelType(String vehicleNumber) async {
    Map<String, dynamic>? vehicleDetails = await _dbHelper.getVehicleDetailsByNumber(vehicleNumber);
    if (vehicleDetails != null && vehicleDetails.isNotEmpty) {
      return vehicleDetails['fuel_type'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  double _fetchFuelPrice(String fuelType) {
    if (fuelType == 'Diesel') {
      return 88.94; // Dummy price for Diesel
    } else if (fuelType == 'Petrol') {
      return 102.86; // Dummy price for Petrol
    }
    return 0.0;
  }

  void openCheckout() {
    double totalAmount = (_fuelPrice * _liters) + _additionalCharges;
    var options = {
      'key': 'rzp_test_Zw3JJnievoiJMW', // Your Razorpay API key
      'amount': (totalAmount * 100).toInt(), // Amount in paise
      'name': 'Fuel Order',
      'description': 'Fuel payment for $_fuelType',
      'prefill': {
        'contact': '1234567890', // Replace with user's contact
        'email': 'test@user.com'  // Replace with user's email
      },
      'external': {
        'wallets': ['paytm'] // Optional: Enable wallets like PayTM
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print(e.toString());
    }
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

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Success: ${response.paymentId}');

    var mobileNumber = await getMobileNumberFromFile();

    // Define your server endpoint URL
    String serverUrl = 'http://13.232.124.107:5000/insert_order';

    // Prepare the data you want to send
    Map<String, dynamic> orderData = {
      'FuelQuantity': _liters,
      'FuelType': _fuelType,
      'MobileNumber': mobileNumber, // Replace with actual mobile number if available
      'OrderedFrom': _deliveringFrom,
      'OrderedToLat': widget.currentLocation.latitude.toString(),
      'OrderedToLong': widget.currentLocation.longitude.toString(),
      'Price': ((_fuelPrice * _liters) + _additionalCharges).toStringAsFixed(2),
    };

    print("Order is");
    print(orderData);

    try {
      // Send the POST request
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200) {
        // Success: Show pop-up indicating order success
        _showOrderSuccessDialog();
      } else {
        // Error handling
        print('Failed to place order. Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred while sending order to server: $e');
    }
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Order Successful"),
          content: Text("Your Order is a Success!"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: ${response.code} - ${response.message}');
    // Handle payment failure scenario here
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
    // Handle wallet payment here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Fuel'),
        backgroundColor: Color(0xFF16560c),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _deliveringToController,
              decoration: InputDecoration(
                labelText: 'Delivering To',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _deliveringFromController,
              decoration: InputDecoration(
                labelText: 'Delivering From',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _carNumberController,
              decoration: InputDecoration(
                labelText: 'Car Number',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _fuelTypeController,
              decoration: InputDecoration(
                labelText: 'Fuel Type',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _fuelPriceController,
              decoration: InputDecoration(
                labelText: 'Price per Liter',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                Text('Liters: '),
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (_liters > 1) _liters--;
                    });
                  },
                ),
                Text('$_liters'),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _liters++;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Text(
              'Additional Charges: ₹${_additionalCharges.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                openCheckout(); // Trigger Razorpay payment when button is pressed
              },
              child: Text(
                'Pay ₹${((_fuelPrice * _liters) + _additionalCharges).toStringAsFixed(2)}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF16560c),
                foregroundColor: Colors.white, // Set text color to white
              ),
            ),
          ],
        ),
      ),
    );
  }
}
