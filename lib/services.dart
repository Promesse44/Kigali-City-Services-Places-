import 'package:geolocator/geolocator.dart';

export 'models/user_model.dart';
export 'models/service_model.dart';

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