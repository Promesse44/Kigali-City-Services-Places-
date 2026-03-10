import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String name;
  final String category;
  final String address;
  final String contactNumber;
  final String? phone;
  final String? website;
  final String? description;
  final double latitude;
  final double longitude;
  final String createdBy;
  final String createdByEmail;
  final DateTime timestamp;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    this.address = '',
    this.contactNumber = '',
    this.phone,
    this.website,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.createdBy,
    this.createdByEmail = '',
    required this.timestamp,
  });

  bool isOwnedBy(String userId) => createdBy == userId;

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      address: data['address'] as String? ?? '',
      contactNumber: data['contactNumber'] as String? ?? '',
      phone: data['phone'] as String?,
      website: data['website'] as String?,
      description: data['description'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      createdBy: data['createdBy'] as String? ?? '',
      createdByEmail: data['createdByEmail'] as String? ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
    );
  }

  factory ServiceModel.fromMap(String id, Map<String, dynamic> data) {
    return ServiceModel(
      id: id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      address: data['address'] as String? ?? '',
      contactNumber: data['contactNumber'] as String? ?? '',
      phone: data['phone'] as String?,
      website: data['website'] as String?,
      description: data['description'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      createdBy: data['createdBy'] as String? ?? '',
      createdByEmail: data['createdByEmail'] as String? ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
    );
  }

  static DateTime _parseTimestamp(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'address': address,
    'contactNumber': contactNumber,
    if (phone != null) 'phone': phone,
    if (website != null) 'website': website,
    if (description != null) 'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'createdBy': createdBy,
    'createdByEmail': createdByEmail,
    'timestamp': Timestamp.fromDate(timestamp),
  };

  ServiceModel copyWith({
    String? id,
    String? name,
    String? category,
    String? address,
    String? contactNumber,
    String? phone,
    String? website,
    String? description,
    double? latitude,
    double? longitude,
    String? createdBy,
    String? createdByEmail,
    DateTime? timestamp,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdBy: createdBy ?? this.createdBy,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  double getDistance(double userLat, double userLng) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(latitude - userLat);
    final dLng = _toRad(longitude - userLng);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(userLat)) *
            cos(_toRad(latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double degrees) => degrees * pi / 180;

  static const List<String> categories = [
    'Hospital',
    'Police Station',
    'Library',
    'Restaurant',
    'Café',
    'Park',
    'Tourist Attraction',
    'School',
    'Bank',
    'Hotel',
    'Supermarket',
    'Embassy',
    'Government Office',
    'Other',
  ];
}
