import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services.dart';
import 'kigali_map_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final ServiceModel service;

  const ServiceDetailsScreen({Key? key, required this.service})
    : super(key: key);

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();
  double? _userLat;
  double? _userLng;
  double? _distance;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final user = await _authService.getCurrentUser();

    double lat;
    double lng;

    // 1. Try GPS location first
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      lat = position.latitude;
      lng = position.longitude;
    } else if (user?.district != null && user!.district!.isNotEmpty) {
      // 2. Fall back to district-based coordinates
      final coords = _locationService.getDistrictCoordinates(user.district);
      if (coords != null) {
        lat = coords[0];
        lng = coords[1];
      } else {
        final defaultCoords = LocationService.getDefaultCoordinates();
        lat = defaultCoords[0];
        lng = defaultCoords[1];
      }
    } else {
      // 3. Default fallback (Kigali City)
      final defaultCoords = LocationService.getDefaultCoordinates();
      lat = defaultCoords[0];
      lng = defaultCoords[1];
    }

    setState(() {
      _userLat = lat;
      _userLng = lng;
      _distance = widget.service.getDistance(lat, lng);
    });
  }

  Future<void> _openInGoogleMaps() async {
    final url =
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$_userLat,$_userLng'
        '&destination=${widget.service.latitude},${widget.service.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWebsite(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      KigaliMapScreen(selectedService: widget.service),
                ),
              );
            },
            tooltip: 'View on Map',
          ),
        ],
      ),
      body: _userLat == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interactive map showing service & user location
                  SizedBox(
                    height: 250,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          widget.service.latitude,
                          widget.service.longitude,
                        ),
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.kigali_service_app',
                        ),
                        MarkerLayer(
                          markers: [
                            if (_userLat != null && _userLng != null)
                              Marker(
                                point: LatLng(_userLat!, _userLng!),
                                width: 36,
                                height: 36,
                                child: const Tooltip(
                                  message: 'Your Location',
                                  child: Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                                ),
                              ),
                            Marker(
                              point: LatLng(
                                widget.service.latitude,
                                widget.service.longitude,
                              ),
                              width: 36,
                              height: 36,
                              child: Tooltip(
                                message: widget.service.name,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Directions button
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openInGoogleMaps,
                        icon: const Icon(Icons.directions),
                        label: const Text('Get Directions in Google Maps'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Category', widget.service.category),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${widget.service.name} is ${_distance?.toStringAsFixed(1) ?? '0'} km from your location',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                        if (widget.service.phone != null)
                          InkWell(
                            onTap: () => _launchPhone(widget.service.phone!),
                            child: _buildInfoRow(
                              'Phone',
                              widget.service.phone!,
                              linkColor: Colors.blue,
                            ),
                          ),
                        if (widget.service.website != null)
                          InkWell(
                            onTap: () =>
                                _launchWebsite(widget.service.website!),
                            child: _buildInfoRow(
                              'Website',
                              widget.service.website!,
                              linkColor: Colors.blue,
                            ),
                          ),
                        if (widget.service.description != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(widget.service.description!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? linkColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: linkColor != null
                  ? TextStyle(
                      color: linkColor,
                      decoration: TextDecoration.underline,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
