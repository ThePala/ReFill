import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._();
  static Database? _database;

  DBHelper._();

  factory DBHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = await getDatabasesPath();
    String dbPath = join(path, 'user_vehicle.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> printAllUsersAndVehicles() async {
    final db = await database;
    var users = await db.query('users');
    var vehicles = await db.query('vehicles');
    print('Users: $users');
    print('Vehicles: $vehicles');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute(''' 
    CREATE TABLE users(
      id INTEGER PRIMARY KEY,
      first_name TEXT,
      last_name TEXT,
      mobile_number TEXT UNIQUE,
      address TEXT
    )
  ''');

    await db.execute(''' 
    CREATE TABLE vehicles(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      vehicle_number TEXT,
      chassis_number TEXT,
      vehicle_type TEXT,
      fuel_type TEXT,
      make_and_model TEXT,
      color TEXT,
      user_mobile_number TEXT,  
      uid INTEGER
    )
  ''');
  }

  Future<void> deleteVehicle(String vehicleNumber) async {
    final db = await database; // Ensure 'database' is initialized in DBHelper

    try {
      int count = await db.delete(
        'vehicles',
        where: 'vehicle_number = ?',
        whereArgs: [vehicleNumber],
      );

      if (count > 0) {
        print('Vehicle with vehicle number $vehicleNumber deleted from local database.');
      } else {
        print('No vehicle found with vehicle number $vehicleNumber.');
      }
    } catch (e) {
      print('Error deleting vehicle: $e');
    }
  }

  Future<void> insertVehiclewUid(Map<String, dynamic> vehicle, int uid) async {
    final db = await database;
    // Include the uid in the vehicle map before inserting
    vehicle['uid'] = uid;
    await db.insert('vehicles', vehicle, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertVehicle(Map<String, dynamic> vehicle) async {
    final db = await database;
    await db.insert('vehicles', vehicle, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserDetails(String mobileNumber) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber.toString()], // Ensure it's compared as a string
    );

    if (result.isNotEmpty) {
      return result.first; // Return the first (and likely only) user
    }
    return null; // User not found
  }

  Future<List<Map<String, dynamic>>> getVehicleDetails(String mobileNumber) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'vehicles',
      where: 'user_mobile_number = ?',
      whereArgs: [mobileNumber.toString()], // Ensure it's compared as a string
    );

    return result; // Return all vehicle records associated with the user
  }

  // New method to fetch vehicle details by vehicle number
  Future<Map<String, dynamic>?> getVehicleDetailsByNumber(String vehicleNumber) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'vehicles',
      where: 'vehicle_number = ?',
      whereArgs: [vehicleNumber.toString()], // Ensure it's compared as a string
    );

    if (result.isNotEmpty) {
      return result.first; // Return the first matching vehicle
    }
    return null; // Vehicle not found
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null; // Reset the instance
    }
  }
}

