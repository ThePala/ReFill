import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<dynamic> _orders = []; // List to store fetched orders
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  // Function to get mobile number from file
  Future<String> getMobileNumberFromFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/mobile_number.txt');
    try {
      String content = await file.readAsString();
      return content.length > 10 ? content.substring(0, 10) : content; // Trim to 10 digits
    } catch (e) {
      print('Error reading mobile number: $e');
      return '';
    }
  }

  // Function to fetch order history
  Future<void> _fetchOrderHistory() async {
    try {
      // Get mobile number from file
      String mobileNumber = await getMobileNumberFromFile();
      if (mobileNumber.isEmpty) {
        setState(() {
          _errorMessage = "No mobile number found.";
          _isLoading = false;
        });
        return;
      }

      // Define the server endpoint URL
      String url = 'http://13.232.124.107:5000/get_orders';

      // Send the request to the backend
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"MobileNumber": mobileNumber}),
      );

      if (response.statusCode == 200) {
        // Parse the response body
        Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            _orders = responseData['orders'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = responseData['message'];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load order history. Please try again later.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching order history: $e');
      setState(() {
        _errorMessage = 'An error occurred while fetching the order history.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order History'),
        backgroundColor: Color(0xFF16560c),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading spinner while fetching data
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage)) // Display error message if present
          : _orders.isEmpty
          ? Center(child: Text('No orders found for this number.'))
          : ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text('Fuel Type: ${order['FuelType']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quantity: ${order['FuelQuantity']} liters'),
                  Text('Price: ₹${order['Price']}'),
                  Text('Ordered From: ${order['OrderedFrom']}'),
                  Text('Ordered To: Lat(${order['OrderedToLat']}), Long(${order['OrderedToLong']})'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
