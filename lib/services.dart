import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? district;
  final String? sector;
  final String? cell;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.district,
    this.sector,
    this.cell,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? district,
    String? sector,
    String? cell,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      district: district ?? this.district,
      sector: sector ?? this.sector,
      cell: cell ?? this.cell,
    );
  }

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
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      district: map['district'] as String?,
      sector: map['sector'] as String?,
      cell: map['cell'] as String?,
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
  final String createdBy;
  final DateTime timestamp;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.website,
    this.description,
    required this.createdBy,
    required this.timestamp,
  });

  ServiceModel copyWith({
    String? id,
    String? name,
    String? category,
    double? latitude,
    double? longitude,
    String? phone,
    String? website,
    String? description,
    String? createdBy,
    DateTime? timestamp,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool isOwnedBy(String userId) => createdBy == userId;

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
      'createdBy': createdBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ServiceModel.fromMap(String id, Map<String, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    DateTime parsedTimestamp = DateTime.now();

    if (rawTimestamp is Timestamp) {
      parsedTimestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is String && rawTimestamp.isNotEmpty) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    }

    return ServiceModel(
      id: id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      phone: map['phone'] as String?,
      website: map['website'] as String?,
      description: map['description'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
      timestamp: parsedTimestamp,
    );
  }

  double getDistance(double userLat, double userLng) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(latitude - userLat);
    final dLng = _degreesToRadians(longitude - userLng);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(userLat)) *
            cos(_degreesToRadians(latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) => degrees * pi / 180;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

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

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw 'Registration failed';
      }

      final user = UserModel(
        uid: firebaseUser.uid,
        email: email,
        fullName: fullName,
        district: district,
        sector: sector,
        cell: cell,
      );

      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      await firebaseUser.sendEmailVerification();

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
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      final fallback = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        fullName: firebaseUser.displayName ?? 'User',
      );
      await docRef.set(fallback.toMap());
      return fallback;
    }

    final data = snapshot.data();
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  Stream<UserModel?> profileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return UserModel.fromMap(data);
    });
  }

  Future<void> updateProfile({
    required String fullName,
    String? district,
    String? sector,
    String? cell,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw 'No authenticated user';
    }

    await _firestore.collection('users').doc(firebaseUser.uid).set({
      'uid': firebaseUser.uid,
      'email': firebaseUser.email ?? '',
      'fullName': fullName,
      'district': district,
      'sector': sector,
      'cell': cell,
    }, SetOptions(merge: true));
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}

class LocationService {
  static const Map<String, List<double>> kigaliDistrictCoordinates = {
    'Gasabo': [-1.9440, 29.9850],
    'Kicukiro': [-1.9490, 29.8540],
    'Nyarugenge': [-1.9560, 29.8760],
  };

  static const double kigaliNorthBound = -1.9200;
  static const double kigaliSouthBound = -1.9700;
  static const double kigaliEastBound = 30.0200;
  static const double kigaliWestBound = 29.8300;
  static const double kigaliCenterLat = -1.9505;
  static const double kigaliCenterLng = 29.8739;

  Future<Position?> getCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  List<double>? getDistrictCoordinates(String? district) {
    if (district == null || district.isEmpty) return null;
    return kigaliDistrictCoordinates[district];
  }

  static bool isWithinKigaliBounds(double latitude, double longitude) {
    return latitude >= kigaliSouthBound &&
        latitude <= kigaliNorthBound &&
        longitude >= kigaliWestBound &&
        longitude <= kigaliEastBound;
  }

  static List<double> getDefaultCoordinates() {
    return [kigaliCenterLat, kigaliCenterLng];
  }

  static List<String> getAvailableDistricts() {
    return kigaliDistrictCoordinates.keys.toList()..sort();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}

class ServiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ServiceModel>> getServicesStream({String? category}) {
    Query<Map<String, dynamic>> query = _firestore.collection('services');
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      final services = snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.id, doc.data()))
          .where(
            (service) => LocationService.isWithinKigaliBounds(
              service.latitude,
              service.longitude,
            ),
          )
          .toList();
      services.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return services;
    });
  }

  Stream<List<ServiceModel>> getUserServicesStream(String userId) {
    return _firestore
        .collection('services')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final services = snapshot.docs
              .map((doc) => ServiceModel.fromMap(doc.id, doc.data()))
              .toList();
          services.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return services;
        });
  }

  Stream<List<String>> getCategoriesStream() {
    return _firestore.collection('services').snapshots().map((snapshot) {
      final categories = snapshot.docs
          .map((doc) => doc.data()['category'] as String?)
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      return categories;
    });
  }

  Future<void> addService(ServiceModel service) async {
    final docRef = _firestore.collection('services').doc();
    final payload = service.copyWith(id: docRef.id).toMap();
    await docRef.set(payload);
  }

  Future<void> updateService({
    required ServiceModel service,
    required String currentUserId,
  }) async {
    final docRef = _firestore.collection('services').doc(service.id);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw 'Listing not found';
    }

    final data = snapshot.data();
    if (data == null) {
      throw 'Listing data is invalid';
    }

    final existing = ServiceModel.fromMap(snapshot.id, data);
    if (!existing.isOwnedBy(currentUserId)) {
      throw 'You can only edit your own listings';
    }

    final safeService = service.copyWith(
      createdBy: existing.createdBy,
      timestamp: existing.timestamp,
    );
    await docRef.update(safeService.toMap());
  }

  Future<void> deleteService({
    required String serviceId,
    required String currentUserId,
  }) async {
    final docRef = _firestore.collection('services').doc(serviceId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw 'Listing not found';
    }

    final data = snapshot.data();
    if (data == null) {
      throw 'Listing data is invalid';
    }

    final existing = ServiceModel.fromMap(snapshot.id, data);
    if (!existing.isOwnedBy(currentUserId)) {
      throw 'You can only delete your own listings';
    }

    await docRef.delete();
  }
}
