import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../services.dart';
import 'kigali_map_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final ServiceModel service;

  const ServiceDetailsScreen({super.key, required this.service});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      context.read<LocationProvider>().loadUserLocation(authProvider.currentUser);
    });
  }

  Future<void> _openInGoogleMaps(double? userLat, double? userLng) async {
    final origin = (userLat != null && userLng != null)
        ? '$userLat,$userLng'
        : '${LocationService.kigaliCenterLat},${LocationService.kigaliCenterLng}';

    final url =
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
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
    final locationProvider = context.watch<LocationProvider>();
    final userLat = locationProvider.userLat;
    final userLng = locationProvider.userLng;
    final distance = (userLat != null && userLng != null)
        ? widget.service.getDistance(userLat, userLng)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      KigaliMapScreen(selectedService: widget.service),
                ),
              );
            },
            tooltip: 'View on map',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    widget.service.latitude,
                    widget.service.longitude,
                  ),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.kigali_service_app',
                  ),
                  MarkerLayer(
                    markers: [
                      if (userLat != null && userLng != null)
                        Marker(
                          point: LatLng(userLat, userLng),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openInGoogleMaps(userLat, userLng),
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
                  if (distance != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${widget.service.name} is ${distance.toStringAsFixed(1)} km from your location',
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
                      onTap: () => _launchWebsite(widget.service.website!),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
