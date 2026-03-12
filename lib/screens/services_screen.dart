import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services.dart';
import '../providers/auth_provider.dart';
import '../providers/services_provider.dart';
import '../providers/location_provider.dart';
import 'service_details_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String? _selectedCategory;
  bool _isDetailedView = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final locationProvider = context.read<LocationProvider>();
      locationProvider.loadUserLocation(authProvider.currentUser);
    });
  }

  void _filterByCategory(String? category) {
    setState(() => _selectedCategory = category);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesProvider = context.watch<ServicesProvider>();
    final locationProvider = context.watch<LocationProvider>();

    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isDetailedView ? Icons.list : Icons.view_list),
                  tooltip: _isDetailedView ? 'Compact view' : 'Detailed view',
                  onPressed: () {
                    setState(() => _isDetailedView = !_isDetailedView);
                  },
                ),
              ],
            ),
          ),
          StreamBuilder<List<String>>(
            stream: servicesProvider.getCategoriesStream(),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? [];
              return Padding(
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
                      ...categories.map(
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
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<ServiceModel>>(
              stream: servicesProvider.getAllServicesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final errorMessage = snapshot.error.toString();
                  final permissionDenied =
                      errorMessage.contains('permission-denied');

                  if (permissionDenied) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Access denied. Your session may still be using old verification data.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () async {
                                final authProvider =
                                    context.read<AuthProvider>();
                                final isVerified = await authProvider
                                    .refreshEmailVerificationStatus();

                                if (!context.mounted) return;

                                final msg = isVerified
                                    ? 'Session refreshed. Retrying access...'
                                    : 'Email not verified yet. Verify then try again.';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(msg)),
                                );

                                if (isVerified) {
                                  setState(() {});
                                }
                              },
                              child: const Text('Refresh Access'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Center(child: Text('Error: $errorMessage'));
                }

                final allServices = snapshot.data ?? [];
                final filteredServices = allServices.where((s) {
                  final matchesCategory =
                      _selectedCategory == null ||
                      s.category == _selectedCategory;
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      s.name.toLowerCase().contains(_searchQuery) ||
                      s.address.toLowerCase().contains(_searchQuery) ||
                      (s.description?.toLowerCase().contains(_searchQuery) ??
                          false);
                  return matchesCategory && matchesSearch;
                }).toList();

                if (filteredServices.isEmpty) {
                  return const Center(child: Text('No services found'));
                }

                return ListView.builder(
                  itemCount: filteredServices.length,
                  itemBuilder: (context, index) {
                    final service = filteredServices[index];
                    final distance =
                        locationProvider.userLat != null &&
                            locationProvider.userLng != null
                        ? service.getDistance(
                            locationProvider.userLat!,
                            locationProvider.userLng!,
                          )
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
                );
              },
            ),
          ),
        ],
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
