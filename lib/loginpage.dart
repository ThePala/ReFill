import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'otppage.dart';
import 'registerpersonal.dart';

void main() {
  runApp(RefillApp());
}

class RefillApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController mobileController = TextEditingController();
  String? verificationId;

  // Function to calculate the fill percentage
  double getFillPercentage(String mobileNumber) {
    return mobileNumber.length / 10; // Returns a value between 0.0 and 1.0
  }

  // Function to send OTP request to the server
  Future<String?> _sendOTP(String mobileNumber, BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request sent. Wait for 60 seconds')),
    );
    String apiUrl = "https://cpaas.messagecentral.com/verification/v3/send";
    String authToken =
        'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJDLUU0MTRFRDE5NTE5RjRCNSIsImlhdCI6MTcyNzE2MzA0NiwiZXhwIjoxODg0ODQzMDQ2fQ.3Ad_x0tfA49yRXs9KcYnPOOjfZ-O6jzntaydYWM8z5cxDWRFal8pxRVvj4ITPLMIwZgisG5X_PGByMWvRXOrQg';

    var url = Uri.parse(
        '$apiUrl?countryCode=91&flowType=SMS&mobileNumber=$mobileNumber');
    var headers = {'authToken': authToken};

    var response = await http.post(url, headers: headers);
    print(url);
    print(response.statusCode);

    if (response.statusCode == 200) {
      var res = json.decode(response.body);
      String verificationId = res["data"]["verificationId"].toString();
      return verificationId;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP. Please try again later.')),
      );
      return null;
    }
  }

  // Function to check if the mobile number is registered
  Future<bool> _checkAccountExists(String mobileNumber) async {
    String apiUrl = "http://13.232.124.107:5000/check_user";
    var url = Uri.parse(apiUrl);
    var headers = {'Content-Type': 'application/json'};
    print(mobileNumber);

    // Encode the mobile number into the body
    var body = json.encode({'mobile_number': mobileNumber});
    print("Body: $body");

    try {
      // Send POST request with headers and body
      var response = await http.post(url, headers: headers, body: body);
      print("Check exists API: ${response.statusCode}");

      if (response.statusCode == 200) {
        return true; // Account exists
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This mobile number is not registered.')),
        );
        return false; // Account does not exist
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking account. Please try again later.')),
        );
        return false;
      }
    } catch (e) {
      // Handle network errors or exceptions
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error. Please try again later.')),
      );
      return false;
    }
  }

  // Save mobile number to local storage
  Future<File> writeMobileNumber(String mobileNumber) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/mobile_number.txt');
    return file.writeAsString(mobileNumber);
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
                            'LOGIN',
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: mobileController,
                                  decoration: InputDecoration(
                                    labelText: 'Mobile Number *',
                                    labelStyle: const TextStyle(fontFamily: 'Inter'),
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
                                  onChanged: (value) {
                                    setState(() {}); // Update UI on text change
                                  },
                                ),
                                SizedBox(height: 20),
                                GestureDetector(
                                  onTap: () async {
                                    final mobileNumber = mobileController.text.trim();
                                    if (mobileNumber.isEmpty || mobileNumber.length != 10) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Please enter a valid 10-digit mobile number.')),
                                      );
                                      return;
                                    }

                                    // Check if account exists
                                    bool accountExists = await _checkAccountExists(mobileNumber);
                                    if (accountExists) {
                                      // Write the mobile number to the file
                                      await writeMobileNumber(mobileNumber);

                                      // Send OTP and get verification ID
                                      verificationId = await _sendOTP(mobileNumber, context);
                                    }
                                  },
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: mobileController.text.length == 10
                                          ? Color(0xFF16560c) // Valid color
                                          : Colors.grey.withOpacity(0.5), // Disabled color
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Send OTP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                // Update the Continue button
                                GestureDetector(
                                  onTap: () {
                                    if (verificationId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => OtpPage(
                                            verificationId: verificationId!,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: Color(0xFF16560c).withOpacity(getFillPercentage(mobileController.text)),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Continue',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Inter',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Don't have an account ?",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Jost',
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => RegistrationPage()),
                                    );
                                  },
                                  child: const Text(
                                    "Register Here",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Jost',
                                      color: Colors.blue,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
