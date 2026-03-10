import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// idTokenChanges is more reliable than authStateChanges — it also fires on
  /// token refresh, ensuring the UI always reflects the current auth state.
  Stream<User?> get authStateChanges => _auth.idTokenChanges();

  User? get currentUser => _auth.currentUser;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
    String? district,
    String? sector,
    String? cell,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(displayName);

    final userModel = UserModel(
      uid: credential.user!.uid,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
      district: district,
      sector: sector,
      cell: cell,
    );

    try {
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toMap());
    } catch (e) {
      await credential.user?.delete();
      rethrow;
    }

    await credential.user?.sendEmailVerification();
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      final fallback = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        createdAt: DateTime.now(),
      );
      await docRef.set(fallback.toMap());
      return fallback;
    }

    return UserModel.fromFirestore(snapshot);
  }

  Future<void> updateProfile({
    required String displayName,
    String? district,
    String? sector,
    String? cell,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await user.updateDisplayName(displayName);
    await _firestore.collection('users').doc(user.uid).update({
      'displayName': displayName,
      'fullName': displayName,
      'district': district,
      'sector': sector,
      'cell': cell,
    });
  }

  Stream<UserModel?> profileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> updateNotificationPreference(String uid, bool enabled) async {
    await _firestore.collection('users').doc(uid).update({
      'notificationsEnabled': enabled,
    });
  }

  Future<void> toggleLike(
    String uid,
    String serviceId, {
    required bool isCurrentlyLiked,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'likedListings': isCurrentlyLiked
          ? FieldValue.arrayRemove([serviceId])
          : FieldValue.arrayUnion([serviceId]),
    });
  }

  Stream<List<String>> getLikedServiceIds(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return <String>[];
      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['likedListings'] ?? []);
    });
  }

  /// Converts a FirebaseAuthException (or any Exception) into a user-friendly
  /// message, matching the patterns used by Firebase Auth error codes.
  static String friendlyMessage(Exception e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) {
      return 'An account already exists with that email.';
    } else if (msg.contains('wrong-password') ||
        msg.contains('invalid-credential') ||
        msg.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'Invalid email or password.';
    } else if (msg.contains('user-not-found')) {
      return 'No account found for that email.';
    } else if (msg.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    } else if (msg.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    } else if (msg.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    } else if (msg.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    return 'Something went wrong. Please try again.';
  }
}
