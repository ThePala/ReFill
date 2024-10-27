import 'dart:async'; // For Timer
import 'dart:io'; // For File I/O operations
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:refillappjava/registerpersonal.dart';
import 'package:refillappjava/loginpage.dart';
import 'package:refillappjava/locationpage.dart'; // Import your LocationPage here

void main() {
  runApp(RefillApp());
}

class RefillApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/': (context) => HomePage(),
        '/register': (context) => RegistrationPage(),
        '/login': (context) => LoginPage(),
        '/location': (context) => LocationPage(),  // Add LocationPage route
      },
    );
  }
}

// Splash Screen widget
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Check if the user is logged in and navigate accordingly
    _checkLoginStatus().then((isLoggedIn) {
      if (isLoggedIn) {
        // Navigate to LocationPage if user is logged in
        Navigator.pushReplacementNamed(context, '/location');
      } else {
        // Otherwise, navigate to HomePage after 3 seconds
        Timer(Duration(seconds: 5), () {
          Navigator.pushReplacementNamed(context, '/');
        });
      }
    });
  }

  // Function to check if the file ends with "Logged"
  Future<bool> _checkLoginStatus() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/mobile_number.txt');

      if (await file.exists()) {
        // Read the contents of the file
        String contents = await file.readAsString();
        // Check if it ends with "Logged"
        return contents.trim().endsWith('Logged');
      } else {
        // If file does not exist, return false
        return false;
      }
    } catch (e) {
      print('Error reading login status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF030303),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/loading.gif',
              width: 300,
              height: 300,
            ),
            SizedBox(height: 20),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Home Page
class HomePage extends StatelessWidget {
  final TextStyle buttonTextStyle = const TextStyle(
    color: Colors.black,
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            top: 280,
            bottom: 0,
            child: Image.asset(
              'images/rectangle1.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 90),
              Container(
                height: 90,
                child: Image.asset('images/logowobg.png'),
              ),
              SizedBox(height: 20),
              Container(
                width: 250,
                child: Image.asset('images/refilltext.png'),
              ),
              SizedBox(height: 120),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        minimumSize: const Size(400, 65),
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        textStyle: buttonTextStyle,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side: const BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                      child: const Text('Register'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF16560c),
                        minimumSize: const Size(400, 65),
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        textStyle: buttonTextStyle,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side: const BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                      child: const Text('Login'),
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
