import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? district;
  final String? sector;
  final String? cell;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.district,
    this.sector,
    this.cell,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'district': district,
      'sector': sector,
      'cell': cell,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      district: map['district'],
      sector: map['sector'],
      cell: map['cell'],
    );
  }
}

class ServiceModel {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? website;
  final String? description;

  ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.website,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'website': website,
      'description': description,
    };
  }

  factory ServiceModel.fromMap(String id, Map<String, dynamic> map) {
    return ServiceModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      phone: map['phone'],
      website: map['website'],
      description: map['description'],
    );
  }

  double getDistance(double userLat, double userLng) {
    const double earthRadiusKm = 6371;
    final double dLat = _degreesToRadians(latitude - userLat);
    final double dLng = _degreesToRadians(longitude - userLng);
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(userLat)) *
            cos(_degreesToRadians(latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> register({
    required String email,
    required String password,
    required String fullName,
    String? district,
    String? sector,
    String? cell,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        fullName: fullName,
        district: district,
        sector: sector,
        cell: cell,
      );

      await _firestore.collection('users').doc(user.uid).set(user.toMap());

      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Registration failed';
    }
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return getCurrentUser();
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      if (_auth.currentUser == null) {
        print('No authenticated user');
        return null;
      }

      final uid = _auth.currentUser!.uid;
      print('Fetching user data for uid: $uid');
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        print('User document found in Firestore');
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      print(
        'User document does not exist in Firestore, creating new document...',
      );
      // Auto-create Firestore document for authenticated users missing one
      final newUser = UserModel(
        uid: uid,
        email: _auth.currentUser!.email ?? '',
        fullName: _auth.currentUser!.displayName ?? 'User',
      );
      await _firestore.collection('users').doc(uid).set(newUser.toMap());
      print('Loaded user: ${newUser.fullName}');
      return newUser;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? district,
    String? sector,
    String? cell,
  }) async {
    try {
      // Use set with merge so it works even if the document doesn't exist yet
      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'uid': _auth.currentUser!.uid,
        'email': _auth.currentUser!.email ?? '',
        'fullName': fullName,
        'district': district,
        'sector': sector,
        'cell': cell,
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to update profile';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}

class LocationService {
  /// Kigali City Districts only (3 main districts)
  static const Map<String, List<double>> kigaliDistrictCoordinates = {
    'Gasabo': [-1.9440, 29.9850], // Northern Kigali
    'Kicukiro': [-1.9490, 29.8540], // Southern Kigali
    'Nyarugenge': [-1.9560, 29.8760], // Central Kigali
  };

  /// Kigali City Geographic Bounds
  /// North: -1.9200, South: -1.9700, East: 30.0200, West: 29.8300
  static const double kigaliNorthBound = -1.9200;
  static const double kigaliSouthBound = -1.9700;
  static const double kigaliEastBound = 30.0200;
  static const double kigaliWestBound = 29.8300;

  /// Kigali City Center (Downtown Kigali)
  static const double kigaliCenterLat = -1.9505;
  static const double kigaliCenterLng = 29.8739;

  Future<Position?> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get location from Kigali district name, returns null if district not found
  List<double>? getDistrictCoordinates(String? district) {
    if (district == null || district.isEmpty) return null;
    return kigaliDistrictCoordinates[district];
  }

  /// Check if coordinates are within Kigali city bounds
  static bool isWithinKigaliBounds(double latitude, double longitude) {
    return latitude >= kigaliSouthBound &&
        latitude <= kigaliNorthBound &&
        longitude >= kigaliWestBound &&
        longitude <= kigaliEastBound;
  }

  /// Get default Kigali City center coordinates as fallback
  static List<double> getDefaultCoordinates() => [
    kigaliCenterLat,
    kigaliCenterLng,
  ];

  /// Get all available Kigali districts for UI dropdowns
  static List<String> getAvailableDistricts() {
    return kigaliDistrictCoordinates.keys.toList()..sort();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}

class ServiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ServiceModel>> getAllServices() async {
    try {
      final snapshot = await _firestore.collection('services').get();
      print('Fetched ${snapshot.docs.length} services from Firestore');

      // Filter services to only include those within Kigali bounds
      final kigaliServices = snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.id, doc.data()))
          .where(
            (service) => LocationService.isWithinKigaliBounds(
              service.latitude,
              service.longitude,
            ),
          )
          .toList();

      print(
        'Filtered to ${kigaliServices.length} services within Kigali bounds',
      );
      return kigaliServices;
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  Future<ServiceModel?> getServiceById(String id) async {
    try {
      final doc = await _firestore.collection('services').doc(id).get();
      if (doc.exists) {
        final service = ServiceModel.fromMap(
          id,
          doc.data() as Map<String, dynamic>,
        );
        // Validate service is within Kigali bounds
        if (LocationService.isWithinKigaliBounds(
          service.latitude,
          service.longitude,
        )) {
          return service;
        }
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<ServiceModel>> getServicesByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('services')
          .where('category', isEqualTo: category)
          .get();

      // Filter services to only include those within Kigali bounds
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.id, doc.data()))
          .where(
            (service) => LocationService.isWithinKigaliBounds(
              service.latitude,
              service.longitude,
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getAllCategories() async {
    try {
      final snapshot = await _firestore.collection('services').get();
      final categories = <String>{};

      for (var doc in snapshot.docs) {
        final category = doc['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      print('Found ${categories.length} categories');
      return categories.toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }
}
