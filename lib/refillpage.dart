// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart';
//
// class RefillPage extends StatefulWidget {
//   @override
//   _RefillPageState createState() => _RefillPageState();
// }
//
// class _RefillPageState extends State<RefillPage> {
//   GoogleMapController? _controller;
//   LatLng? _currentPosition;
//
//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }
//
//   Future<void> _getCurrentLocation() async {
//     Location location = Location();
//     LocationData locationData = await location.getLocation();
//     setState(() {
//       _currentPosition = LatLng(locationData.latitude!, locationData.longitude!);
//     });
//     _controller?.moveCamera(CameraUpdate.newLatLng(_currentPosition!));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           // Header section
//           Container(
//             height: 150,
//             decoration: BoxDecoration(
//               color: Colors.green,
//               borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   'REFILL',
//                   style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Hello Raj Sharma',
//                   style: TextStyle(fontSize: 20, color: Colors.white),
//                 ),
//                 SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Image.asset('images/car_image.png', width: 60), // Replace with your car image
//                     SizedBox(width: 8),
//                     Text(
//                       'JAGUAR F PACE 2020',
//                       style: TextStyle(fontSize: 16, color: Colors.white),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           // Map section
//           Expanded(
//             child: _currentPosition == null
//                 ? Center(child: CircularProgressIndicator())
//                 : GoogleMap(
//               onMapCreated: (controller) {
//                 _controller = controller;
//               },
//               initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 14),
//               markers: {
//                 Marker(
//                   markerId: MarkerId('currentLocation'),
//                   position: _currentPosition!,
//                 ),
//               },
//             ),
//           ),
//           // Location section
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//               boxShadow: [
//                 BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 0, offset: Offset(0, -2)),
//               ],
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
//                         Text('Jun 6, 2024 at 03:12 PM'),
//                         Text('Christ University, S.G Palya, Bengaluru, India'),
//                       ],
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         // Add functionality to open maps
//                       },
//                       child: Text('Open in Maps'),
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         _getCurrentLocation(); // Refresh location
//                       },
//                       child: Text('Refresh'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: [
//           BottomNavigationBarItem(
//             icon: Image.asset('images/home_icon.png', width: 24), // Replace with your icon
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Image.asset('images/car_icon.png', width: 24), // Replace with your icon
//             label: 'Car',
//           ),
//           BottomNavigationBarItem(
//             icon: Image.asset('images/profile_icon.png', width: 24), // Replace with your icon
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }
