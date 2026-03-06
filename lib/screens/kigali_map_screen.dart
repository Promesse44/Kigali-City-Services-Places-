import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/services_provider.dart';
import '../services.dart';
import 'service_details_screen.dart';

class KigaliMapScreen extends StatefulWidget {
  final ServiceModel? selectedService;

  const KigaliMapScreen({super.key, this.selectedService});

  @override
  State<KigaliMapScreen> createState() => _KigaliMapScreenState();
}

class _KigaliMapScreenState extends State<KigaliMapScreen> {
  final MapController _mapController = MapController();
  String _currentTileProvider = 'openstreetmap';

  static const double kigaliLat = -1.9505;
  static const double kigaliLng = 29.8739;

  final Map<String, String> _tileProviders = {
    'openstreetmap': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'opentopomap': 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
    'humanitarian': 'https://tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      context.read<LocationProvider>().loadUserLocation(authProvider.currentUser);
    });
  }

  LatLng _getInitialCenter(double? userLat, double? userLng) {
    if (widget.selectedService != null) {
      return LatLng(
        widget.selectedService!.latitude,
        widget.selectedService!.longitude,
      );
    }

    if (userLat != null && userLng != null) {
      return LatLng(userLat, userLng);
    }

    return const LatLng(kigaliLat, kigaliLng);
  }

  void _showServiceBottomSheet({
    required ServiceModel service,
    required double? userLat,
    required double? userLng,
  }) {
    final distance =
        (userLat != null && userLng != null)
        ? service.getDistance(userLat, userLng)
        : null;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => _ServiceBottomSheet(
        service: service,
        distance: distance,
        onViewDetails: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailsScreen(service: service),
            ),
          );
        },
        onOpenDirections: () async {
          Navigator.pop(ctx);
          final origin = (userLat != null && userLng != null)
              ? '$userLat,$userLng'
              : '$kigaliLat,$kigaliLng';
          final url =
              'https://www.google.com/maps/dir/?api=1'
              '&origin=$origin'
              '&destination=${service.latitude},${service.longitude}';
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesProvider = context.watch<ServicesProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final userLat = locationProvider.userLat;
    final userLng = locationProvider.userLng;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services Map - Kigali'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (provider) {
              setState(() {
                _currentTileProvider = provider;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'openstreetmap', child: Text('Standard OSM')),
              PopupMenuItem(value: 'opentopomap', child: Text('Topo')),
              PopupMenuItem(value: 'humanitarian', child: Text('Humanitarian')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<ServiceModel>>(
        stream: servicesProvider.getAllServicesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Map load failed: ${snapshot.error}'));
          }

          final services = snapshot.data ?? const <ServiceModel>[];
          final markers = <Marker>[
            if (userLat != null && userLng != null)
              Marker(
                point: LatLng(userLat, userLng),
                width: 38,
                height: 38,
                child: const Tooltip(
                  message: 'Your Location',
                  child: Icon(Icons.my_location, color: Colors.blue, size: 30),
                ),
              ),
            ...services.map((service) {
              final isSelected = widget.selectedService?.id == service.id;
              return Marker(
                point: LatLng(service.latitude, service.longitude),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _showServiceBottomSheet(
                    service: service,
                    userLat: userLat,
                    userLng: userLng,
                  ),
                  child: Tooltip(
                    message: service.name,
                    child: Icon(
                      Icons.location_on,
                      color: isSelected ? Colors.orange : Colors.red,
                      size: isSelected ? 38 : 32,
                    ),
                  ),
                ),
              );
            }),
          ];

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _getInitialCenter(userLat, userLng),
                  initialZoom: widget.selectedService != null ? 15 : 13,
                  minZoom: 10,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        _tileProviders[_currentTileProvider] ??
                        _tileProviders['openstreetmap']!,
                    userAgentPackageName: 'com.example.kigali_service_app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'centerUser',
                      onPressed: () {
                        if (userLat == null || userLng == null) return;
                        _mapController.move(LatLng(userLat, userLng), 15);
                      },
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'centerKigali',
                      onPressed: () {
                        _mapController.move(const LatLng(kigaliLat, kigaliLng), 13);
                      },
                      child: const Icon(Icons.location_city),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceBottomSheet extends StatelessWidget {
  final ServiceModel service;
  final double? distance;
  final VoidCallback onViewDetails;
  final VoidCallback onOpenDirections;

  const _ServiceBottomSheet({
    required this.service,
    required this.distance,
    required this.onViewDetails,
    required this.onOpenDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Category: ${service.category}'),
          if (distance != null)
            Text('Distance: ${distance!.toStringAsFixed(1)} km'),
          if (service.phone != null && service.phone!.isNotEmpty)
            Text('Phone: ${service.phone}'),
          if (service.description != null && service.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                service.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenDirections,
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
