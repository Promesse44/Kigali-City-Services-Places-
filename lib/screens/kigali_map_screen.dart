import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final ServiceRepository _serviceRepository = ServiceRepository();
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();

  List<ServiceModel> _services = [];
  double? _userLat;
  double? _userLng;
  bool _isLoading = true;
  String _currentTileProvider = 'openstreetmap';

  // Default center of Kigali
  static const double kigaliLat = -1.9505;
  static const double kigaliLng = 29.8739;

  // Alternative tile providers for improved map display
  final Map<String, String> tileProviders = {
    'openstreetmap': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'opentopomap': 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
    'cartodb': 'https://tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await _loadUserLocation();

    final servicesStream = _serviceRepository.getServicesStream();
    servicesStream.first.then((services) {
      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadUserLocation() async {
    final user = await _authService.getCurrentUser();

    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
      return;
    }

    if (user?.district != null && user!.district!.isNotEmpty) {
      final coords = _locationService.getDistrictCoordinates(user.district);
      if (coords != null) {
        setState(() {
          _userLat = coords[0];
          _userLng = coords[1];
        });
        return;
      }
    }

    final defaultCoords = LocationService.getDefaultCoordinates();
    setState(() {
      _userLat = defaultCoords[0];
      _userLng = defaultCoords[1];
    });
  }

  LatLng _getInitialCenter() {
    if (widget.selectedService != null) {
      return LatLng(
        widget.selectedService!.latitude,
        widget.selectedService!.longitude,
      );
    }
    if (_userLat != null && _userLng != null) {
      return LatLng(_userLat!, _userLng!);
    }
    return const LatLng(kigaliLat, kigaliLng);
  }

  void _switchTileProvider(String provider) {
    setState(() {
      _currentTileProvider = provider;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Map switched to $provider')));
  }

  void _showServiceDetails(ServiceModel service) {
    final distance = _userLat != null && _userLng != null
        ? service.getDistance(_userLat!, _userLng!)
        : null;

    showModalBottomSheet(
      context: context,
      builder: (context) => _ServiceBottomSheet(
        service: service,
        distance: distance,
        onViewDetails: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailsScreen(service: service),
            ),
          );
        },
        onOpenDirections: () async {
          Navigator.pop(context);
          final url =
              'https://www.google.com/maps/dir/?api=1'
              '&origin=$_userLat,$_userLng'
              '&destination=${service.latitude},${service.longitude}';
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // User location marker
    if (_userLat != null && _userLng != null) {
      markers.add(
        Marker(
          point: LatLng(_userLat!, _userLng!),
          width: 40,
          height: 40,
          child: const Tooltip(
            message: 'Your Location',
            child: Icon(Icons.my_location, color: Colors.blue, size: 32),
          ),
        ),
      );
    }

    // Service markers
    for (final service in _services) {
      final isSelected = widget.selectedService?.id == service.id;
      markers.add(
        Marker(
          point: LatLng(service.latitude, service.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showServiceDetails(service),
            child: Tooltip(
              message: service.name,
              child: Icon(
                Icons.location_on,
                color: isSelected ? Colors.orange : Colors.red,
                size: isSelected ? 40 : 32,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services Map - Kigali'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _switchTileProvider,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'openstreetmap',
                child: Text('Standard OSM'),
              ),
              const PopupMenuItem<String>(
                value: 'opentopomap',
                child: Text('Topo Map'),
              ),
              const PopupMenuItem<String>(
                value: 'cartodb',
                child: Text('CartoDB'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _getInitialCenter(),
                    initialZoom: widget.selectedService != null ? 15.0 : 13.0,
                    minZoom: 10.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          tileProviders[_currentTileProvider] ??
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.kigali_service_app',
                      tms: false,
                      maxNativeZoom: 19,
                    ),
                    MarkerLayer(markers: _buildMarkers()),
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
                          if (_userLat != null && _userLng != null) {
                            _mapController.move(
                              LatLng(_userLat!, _userLng!),
                              15.0,
                            );
                          }
                        },
                        tooltip: 'Center on your location',
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        mini: true,
                        heroTag: 'centerKigali',
                        onPressed: () {
                          _mapController.move(
                            const LatLng(kigaliLat, kigaliLng),
                            13.0,
                          );
                        },
                        tooltip: 'Center on Kigali',
                        child: const Icon(Icons.location_city),
                      ),
                    ],
                  ),
                ),
              ],
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
    this.distance,
    required this.onViewDetails,
    required this.onOpenDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            'Category: ${service.category}',
            style: const TextStyle(color: Colors.grey),
          ),
          if (distance != null) ...[
            const SizedBox(height: 4),
            Text(
              '${service.name} is ${distance!.toStringAsFixed(1)} km from your location',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey,
              ),
            ),
          ],
          if (service.phone != null) ...[
            const SizedBox(height: 4),
            Text('Phone: ${service.phone}'),
          ],
          if (service.description != null) ...[
            const SizedBox(height: 4),
            Text(
              service.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View Details'),
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
