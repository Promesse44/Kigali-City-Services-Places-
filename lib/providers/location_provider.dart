import 'package:flutter/foundation.dart';
import '../services.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  double? _userLat;
  double? _userLng;
  bool _isLoading = false;
  String? _lastLoadedUserId;

  double? get userLat => _userLat;
  double? get userLng => _userLng;
  bool get isLoading => _isLoading;

  Future<void> loadUserLocation(UserModel? user) async {
    if (_isLoading) return;

    final userId = user?.uid;
    if (_lastLoadedUserId == userId && _userLat != null && _userLng != null) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _userLat = position.latitude;
      _userLng = position.longitude;
      _isLoading = false;
      _lastLoadedUserId = userId;
      notifyListeners();
      return;
    }

    if (user?.district != null && user!.district!.isNotEmpty) {
      final coords = _locationService.getDistrictCoordinates(user.district);
      if (coords != null) {
        _userLat = coords[0];
        _userLng = coords[1];
        _isLoading = false;
        _lastLoadedUserId = userId;
        notifyListeners();
        return;
      }
    }

    final defaultCoords = LocationService.getDefaultCoordinates();
    _userLat = defaultCoords[0];
    _userLng = defaultCoords[1];
    _isLoading = false;
    _lastLoadedUserId = userId;
    notifyListeners();
  }

  void clear() {
    _userLat = null;
    _userLng = null;
    _lastLoadedUserId = null;
    notifyListeners();
  }

  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }
}
