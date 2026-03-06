import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSubscription;

  UserModel? _currentUser;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _authSubscription = _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        _isInitialized = true;
        notifyListeners();
        return;
      }

      _currentUser = await _authService.getCurrentUser();
      _isInitialized = true;
      notifyListeners();
    });
  }

  UserModel? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get firebaseUser => _authService.currentUser;
  bool get isAuthenticated => firebaseUser != null;
  bool get isEmailVerified => _authService.isEmailVerified;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<void> refreshCurrentUser() async {
    if (firebaseUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? district,
    String? sector,
    String? cell,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        district: district,
        sector: sector,
        cell: cell,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(email: email, password: password);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? district,
    String? sector,
    String? cell,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _authService.updateProfile(
      fullName: fullName,
      district: district,
      sector: sector,
      cell: cell,
    );
    await refreshCurrentUser();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendEmailVerification() async {
    await _authService.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _authService.reloadUser();
    notifyListeners();
  }

  Future<bool> refreshEmailVerificationStatus() async {
    await _authService.reloadUser();
    notifyListeners();
    return isEmailVerified;
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
