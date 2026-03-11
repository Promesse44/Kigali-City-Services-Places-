import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/services_provider.dart';
import '../services.dart';
import 'service_details_screen.dart';

// Category colors
const Map<String, Color> categoryColors = {
  'Hospital': Color(0xFFFF6B6B),
  'Pharmacy': Color(0xFF51CF66),
  'School': Color(0xFF4ECDC4),
  'Market': Color(0xFFFFD93D),
  'Government': Color(0xFF6C5CE7),
  'Bank': Color(0xFF00B4D8),
  'Religious': Color(0xFFD4A574),
  'Hotel': Color(0xFFFF9F1C),
};

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.firebaseUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view your listings.')),
      );
    }

    final servicesProvider = context.watch<ServicesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings'), elevation: 0),
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<List<ServiceModel>>(
        stream: servicesProvider.getUserServicesStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load listings: ${snapshot.error}'),
            );
          }

          final listings = snapshot.data ?? [];
          if (listings.isEmpty) {
            return const Center(
              child: Text('No listings yet. Tap + to create your first one.'),
            );
          }

          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              final isOwner = listing.isOwnedBy(user.uid);
              final catColor = categoryColors[listing.category] ?? Colors.grey;
              final lightColor = Color.lerp(catColor, Colors.white, 0.85)!;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [lightColor, Colors.white],
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailsScreen(service: listing),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 60,
                            decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  listing.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: catColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        listing.category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: catColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat(
                                        'MMM d, yyyy',
                                      ).format(listing.timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          isOwner
                              ? _buildListingMenu(context, listing, user.uid)
                              : Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openListingForm(context: context, userId: user.uid),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListingMenu(
    BuildContext context,
    ServiceModel listing,
    String userId,
  ) {
    return PopupMenuButton<String>(
      onSelected: (action) async {
        if (action == 'edit') {
          await _openListingForm(
            context: context,
            userId: userId,
            existing: listing,
          );
        } else if (action == 'delete') {
          await _deleteWithConfirmation(context, listing, userId);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Future<void> _deleteWithConfirmation(
    BuildContext context,
    ServiceModel listing,
    String userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: Text('Are you sure you want to delete "${listing.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!context.mounted || confirmed != true) return;

    try {
      await context.read<ServicesProvider>().deleteService(
        serviceId: listing.id,
        currentUserId: userId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Listing deleted.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Future<void> _openListingForm({
    required BuildContext context,
    required String userId,
    ServiceModel? existing,
  }) async {
    final result = await showDialog<ServiceModel>(
      context: context,
      builder: (_) => _ListingFormDialog(existing: existing, userId: userId),
    );

    if (!context.mounted || result == null) return;

    try {
      final servicesProvider = context.read<ServicesProvider>();
      if (existing == null) {
        await servicesProvider.addService(result);
      } else {
        await servicesProvider.updateService(
          service: result,
          currentUserId: userId,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null ? 'Listing added.' : 'Listing updated.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }
}

class _ListingFormDialog extends StatefulWidget {
  final ServiceModel? existing;
  final String userId;

  const _ListingFormDialog({required this.existing, required this.userId});

  @override
  State<_ListingFormDialog> createState() => _ListingFormDialogState();
}

class _ListingFormDialogState extends State<_ListingFormDialog> {
  late final GlobalKey<FormState> _form;
  late final TextEditingController name;
  late final TextEditingController category;
  late final TextEditingController address;
  late final TextEditingController phone;
  late final TextEditingController contact;
  late final TextEditingController lat;
  late final TextEditingController lng;
  late final TextEditingController website;
  late final TextEditingController description;

  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _form = GlobalKey();
    name = TextEditingController();
    category = TextEditingController();
    address = TextEditingController();
    phone = TextEditingController();
    contact = TextEditingController();
    lat = TextEditingController();
    lng = TextEditingController();
    website = TextEditingController();
    description = TextEditingController();

    if (widget.existing != null) {
      _populateFromExisting(widget.existing!);
    }
  }

  void _populateFromExisting(ServiceModel s) {
    name.text = s.name;
    selectedCategory = s.category;
    category.text = s.category;
    address.text = s.address;
    contact.text = s.contactNumber;
    lat.text = s.latitude.toString();
    lng.text = s.longitude.toString();
    phone.text = s.phone ?? '';
    website.text = s.website ?? '';
    description.text = s.description ?? '';
  }

  @override
  void dispose() {
    name.dispose();
    category.dispose();
    address.dispose();
    phone.dispose();
    contact.dispose();
    lat.dispose();
    lng.dispose();
    website.dispose();
    description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;

    try {
      final latitude = double.parse(lat.text.trim());
      final longitude = double.parse(lng.text.trim());

      if (!LocationService.isWithinKigaliBounds(latitude, longitude)) {
        _showError('Location must be within Kigali bounds.');
        return;
      }

      final selectedCat = selectedCategory ?? category.text.trim();

      final service = ServiceModel(
        id: widget.existing?.id ?? '',
        name: name.text.trim(),
        category: selectedCat,
        address: address.text.trim(),
        contactNumber: contact.text.trim(),
        latitude: latitude,
        longitude: longitude,
        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
        website: website.text.trim().isEmpty ? null : website.text.trim(),
        description: description.text.trim().isEmpty
            ? null
            : description.text.trim(),
        createdBy: widget.existing?.createdBy ?? widget.userId,
        createdByEmail: widget.existing?.createdByEmail ?? '',
        timestamp: widget.existing?.timestamp ?? DateTime.now(),
      );

      Navigator.pop(context, service);
    } on FormatException {
      _showError('Invalid latitude/longitude format.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Listing' : 'New Listing'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ServiceModel.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => selectedCategory = v),
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Select a category' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contact,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lat,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Required';
                  if (double.tryParse(v!) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lng,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Required';
                  if (double.tryParse(v!) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: website,
                decoration: const InputDecoration(
                  labelText: 'Website (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: description,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
