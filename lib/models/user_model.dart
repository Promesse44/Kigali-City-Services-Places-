import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final bool notificationsEnabled;
  final List<String> likedListings;
  final String? district;
  final String? sector;
  final String? cell;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.notificationsEnabled = false,
    this.likedListings = const [],
    this.district,
    this.sector,
    this.cell,
  });

  /// Backward-compatibility alias used by existing screens.
  String get fullName => displayName;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName:
          data['displayName'] as String? ?? data['fullName'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? false,
      likedListings: List<String>.from(data['likedListings'] ?? []),
      district: data['district'] as String?,
      sector: data['sector'] as String?,
      cell: data['cell'] as String?,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String? ?? '',
      email: data['email'] as String? ?? '',
      displayName:
          data['displayName'] as String? ?? data['fullName'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? false,
      likedListings: List<String>.from(data['likedListings'] ?? []),
      district: data['district'] as String?,
      sector: data['sector'] as String?,
      cell: data['cell'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'fullName': displayName, // backward compat with existing Firestore documents
    'createdAt': Timestamp.fromDate(createdAt),
    'notificationsEnabled': notificationsEnabled,
    'likedListings': likedListings,
    if (district != null) 'district': district,
    if (sector != null) 'sector': sector,
    if (cell != null) 'cell': cell,
  };

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    bool? notificationsEnabled,
    List<String>? likedListings,
    String? district,
    String? sector,
    String? cell,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      likedListings: likedListings ?? this.likedListings,
      district: district ?? this.district,
      sector: sector ?? this.sector,
      cell: cell ?? this.cell,
    );
  }
}
