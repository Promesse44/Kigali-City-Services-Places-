import 'package:flutter/material.dart';
import '../services.dart';
import 'service_details_screen.dart';
import 'kigali_map_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final ServiceRepository _serviceRepository = ServiceRepository();
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();

  List<ServiceModel> _allServices = [];
  List<ServiceModel> _filteredServices = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isDetailedView = false;
  double? _userLat;
  double? _userLng;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await _loadUserLocation();
    final services = await _serviceRepository.getAllServices();
    final categories = await _serviceRepository.getAllCategories();

    setState(() {
      _allServices = services;
      _filteredServices = services;
      _categories = categories;
      _isLoading = false;
    });
  }

  Future<void> _loadUserLocation() async {
    final user = await _authService.getCurrentUser();

    // 1. Try GPS location first
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
      return;
    }

    // 2. Fall back to district-based coordinates
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

    // 3. Default fallback coordinates (Kigali City)
    final defaultCoords = LocationService.getDefaultCoordinates();
    setState(() {
      _userLat = defaultCoords[0];
      _userLng = defaultCoords[1];
    });

    // Prompt user if neither GPS nor address is available
    if (user?.district == null || user!.district!.isEmpty) {
      _showLocationPrompt();
    }
  }

  void _showLocationPrompt() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Location Not Set'),
          content: const Text(
            'Your profile has no address and GPS is unavailable. '
            'Please enable location services or update your address in Profile settings '
            'for more accurate service results.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _locationService.openLocationSettings();
              },
              child: const Text('Enable GPS'),
            ),
          ],
        ),
      );
    });
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      if (category == null) {
        _filteredServices = _allServices;
      } else {
        _filteredServices = _allServices
            .where((s) => s.category == category)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KigaliMapScreen()),
              );
            },
            tooltip: 'View on Map',
          ),
          IconButton(
            icon: Icon(_isDetailedView ? Icons.list : Icons.view_list),
            onPressed: () {
              setState(() => _isDetailedView = !_isDetailedView);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: const Text('All'),
                            selected: _selectedCategory == null,
                            onSelected: (_) => _filterByCategory(null),
                          ),
                        ),
                        ..._categories.map(
                          (category) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (_) => _filterByCategory(category),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredServices.isEmpty
                      ? const Center(child: Text('No services found'))
                      : ListView.builder(
                          itemCount: _filteredServices.length,
                          itemBuilder: (context, index) {
                            final service = _filteredServices[index];
                            final distance =
                                _userLat != null && _userLng != null
                                ? service.getDistance(_userLat!, _userLng!)
                                : 0.0;

                            if (_isDetailedView) {
                              return ServiceDetailedTile(
                                service: service,
                                distance: distance,
                              );
                            }

                            return ServiceBriefTile(
                              service: service,
                              distance: distance,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class ServiceBriefTile extends StatelessWidget {
  final ServiceModel service;
  final double distance;

  const ServiceBriefTile({
    super.key,
    required this.service,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(service.name),
      subtitle: Text('${distance.toStringAsFixed(1)} km away'),
      trailing: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailsScreen(service: service),
            ),
          );
        },
        child: const Text('View Details'),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailsScreen(service: service),
          ),
        );
      },
    );
  }
}

class ServiceDetailedTile extends StatelessWidget {
  final ServiceModel service;
  final double distance;

  const ServiceDetailedTile({
    super.key,
    required this.service,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              service.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Category: ${service.category}'),
            Text('Distance: ${distance.toStringAsFixed(1)} km'),
            if (service.phone != null) Text('Phone: ${service.phone}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceDetailsScreen(service: service),
                  ),
                );
              },
              child: const Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }
}
