import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:refillappjava/locationpage.dart';
import 'package:refillappjava/db_helper.dart';

class OtpPage extends StatefulWidget {
  final String verificationId;

  OtpPage({required this.verificationId});

  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  // Read mobile number from local storage
  Future<String> getMobileNumberFromFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/mobile_number.txt');
    try {
      return await file.readAsString();
    } catch (e) {
      print('Error reading mobile number: $e');
      return '';
    }
  }

// Function to append 'Logged' to the mobile number file
  Future<void> _appendLoggedToFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/mobile_number.txt');

      // Read the current mobile number from the file
      String mobileNumber = await file.readAsString();

      // Append the word "Logged" to the mobile number
      mobileNumber = "$mobileNumber Logged";

      // Write the updated content back to the file
      await file.writeAsString(mobileNumber);

      print('Successfully appended "Logged" to mobile_number.txt');
    } catch (e) {
      print('Error appending "Logged" to file: $e');
    }
  }

  Future<void> _verifyOTP() async {
    String otp = otpControllers.map((controller) => controller.text).join();
    String apiUrl = 'https://cpaas.messagecentral.com/verification/v3/validateOtp';
    String authToken =
        "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJDLUU0MTRFRDE5NTE5RjRCNSIsImlhdCI6MTcyNzE2MzA0NiwiZXhwIjoxODg0ODQzMDQ2fQ.3Ad_x0tfA49yRXs9KcYnPOOjfZ-O6jzntaydYWM8z5cxDWRFal8pxRVvj4ITPLMIwZgisG5X_PGByMWvRXOrQg";

    var url = Uri.parse('$apiUrl?&verificationId=${widget.verificationId}&code=$otp');
    var headers = {'authToken': authToken};

    var response = await http.get(url, headers: headers);
    print("Response Code: ${response.statusCode}");

    if (response.statusCode == 200) {
      var res = json.decode(response.body);
      String verificationStatus = res["data"]["verificationStatus"].toString();

        if (verificationStatus == "VERIFICATION_COMPLETED") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully Logged In')),
          );
          print("Verification successful!");

          // Fetch the mobile number and pass it to the new combined function
          String mobileNumber = await getMobileNumberFromFile();
          await fetchUserAndVehicleDetails(mobileNumber);

      } else {
        print("Verification failed!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wrong OTP Entered')),
        );
      }
    } else {
      print("Error: Failed to verify OTP");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wrong OTP Entered')),
      );
    }
  }
  Future<void> debugPrintUserAndVehicleDetails(String mobileNumber) async {
    DBHelper dbHelper = DBHelper();

    // Fetch and print user details
    var userDetails = await dbHelper.getUserDetails(mobileNumber);
    if (userDetails != null) {
      print("User Details:");
      print("First Name: ${userDetails['first_name']}");
      print("Last Name: ${userDetails['last_name']}");
      print("Mobile Number: ${userDetails['mobile_number']}");
      print("Address: ${userDetails['address']}");
    } else {
      print("No user found with mobile number: $mobileNumber");
    }

    // Fetch and print vehicle details
    var vehicleDetails = await dbHelper.getVehicleDetails(mobileNumber);
    if (vehicleDetails.isNotEmpty) {
      print("\nVehicle Details:");
      for (var vehicle in vehicleDetails) {
        print("Vehicle Number: ${vehicle['vehicle_number']}");
        print("Chassis Number: ${vehicle['chassis_number']}");
        print("Vehicle Type: ${vehicle['vehicle_type']}");
        print("Fuel Type: ${vehicle['fuel_type']}");
        print("Make and Model: ${vehicle['make_and_model']}");
        print("Color: ${vehicle['color']}\n");
      }
    } else {
      print("No vehicles found for user with mobile number: $mobileNumber");
    }
  }

  Future<bool> getUserDetails(String mobileNumber) async {
    String apiUrl = "http://13.232.124.107:5000/get_user_details";
    var url = Uri.parse(apiUrl);
    var headers = {'Content-Type': 'application/json'};
    var body = json.encode({'mobile_number': mobileNumber});
    print("User Details Request Body: $body");

    try {
      // Send POST request to get user details
      var response = await http.post(url, headers: headers, body: body);
      print("User Details API Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Parse the response body
        var jsonData = json.decode(response.body);
        var userDetails = jsonData['user_details'];

        // Insert into SQLite
        DBHelper dbHelper = DBHelper();

        // Insert user details
        await dbHelper.insertUser({
          'first_name': userDetails['first_name'],
          'last_name': userDetails['last_name'],
          'mobile_number': userDetails['mobile_number'],
          'address': userDetails['address'],
        });

        return true;
      } else {
        print("Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }

  Future<bool> getVehicleDetails(String mobileNumber) async {
    String apiUrl = "http://13.232.124.107:5000/get_vehicle_details";
    var url = Uri.parse(apiUrl);
    var headers = {'Content-Type': 'application/json'};
    var body = json.encode({'mobile_number': mobileNumber});
    print("Vehicle Details Request Body: $body");

    try {
      // Send POST request to get vehicle details
      var response = await http.post(url, headers: headers, body: body);
      print("Vehicle Details API Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Parse the response body
        var jsonData = json.decode(response.body);
        var vehicleDetails = jsonData['vehicle_details'];

        // Insert into SQLite
        DBHelper dbHelper = DBHelper();

        // Insert vehicle details
        for (var vehicle in vehicleDetails) {
          await dbHelper.insertVehicle({
            'vehicle_number': vehicle['vehicle_number'],
            'chassis_number': vehicle['chassis_number'],
            'vehicle_type': vehicle['vehicle_type'],
            'fuel_type': vehicle['fuel_type'],
            'make_and_model': vehicle['vehicle_make_and_model'],
            'color': vehicle['vehicle_color'],
            'user_mobile_number': mobileNumber,  // Foreign key reference
          });
        }

        return true;
      } else {
        print("Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }

  Future<void> fetchUserAndVehicleDetails(String mobileNumber) async {
    bool userDetailsSuccess = await getUserDetails(mobileNumber);
    bool vehicleDetailsSuccess = await getVehicleDetails(mobileNumber);

    if (userDetailsSuccess && vehicleDetailsSuccess) {
      await _appendLoggedToFile();

      // Print user and vehicle details for debugging
      await debugPrintUserAndVehicleDetails(mobileNumber);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LocationPage()),
      );
    } else {
      print("Error fetching user or vehicle details.");
    }
  }

  @override
  void dispose() {
    // Dispose of controllers and focus nodes
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 140,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Image.asset(
                          'images/rectangle2.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                      Column(
                        children: [
                          SizedBox(height: 70),
                          Image.asset(
                            'images/refilltext.png',
                            height: 60,
                          ),
                          const SizedBox(height: 120),
                          const Text(
                            'OTP',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 60),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(4, (index) {
                                return SizedBox(
                                  width: 60,
                                  child: TextField(
                                    controller: otpControllers[index],
                                    focusNode: focusNodes[index],
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                      counterText: '', // Remove the character counter
                                    ),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 1,
                                    onChanged: (value) {
                                      if (value.length == 1 && index < 3) {
                                        // Move to the next TextField
                                        FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                                      } else if (value.isEmpty && index > 0) {
                                        // Move back to the previous TextField
                                        FocusScope.of(context).requestFocus(focusNodes[index - 1]);
                                      }
                                    },
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              _verifyOTP();
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF16560c),
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: const Text('Verify OTP'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
