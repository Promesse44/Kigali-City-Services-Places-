import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/services_provider.dart';
import '../services.dart';

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
      appBar: AppBar(title: const Text('My Listings')),
      body: StreamBuilder<List<ServiceModel>>(
        stream: servicesProvider.getUserServicesStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Failed to load listings: ${snapshot.error}'));
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
              final canEdit = listing.isOwnedBy(user.uid);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(listing.name),
                  subtitle: Text(
                    '${listing.category}\nCreated: ${DateFormat('yMMMd, HH:mm').format(listing.timestamp)}',
                  ),
                  isThreeLine: true,
                  trailing: canEdit
                      ? PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await _openListingForm(
                                context: context,
                                userId: user.uid,
                                existing: listing,
                              );
                              return;
                            }

                            await _confirmDelete(
                              context: context,
                              serviceId: listing.id,
                              serviceName: listing.name,
                              userId: user.uid,
                            );
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        )
                      : const Icon(Icons.lock_outline),
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
            content: Text(existing == null ? 'Listing added.' : 'Listing updated.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operation failed: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete({
    required BuildContext context,
    required String serviceId,
    required String serviceName,
    required String userId,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Delete "$serviceName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!context.mounted || shouldDelete != true) return;

    try {
      await context.read<ServicesProvider>().deleteService(
        serviceId: serviceId,
        currentUserId: userId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing deleted.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final listing = widget.existing;
    if (listing == null) return;

    _nameController.text = listing.name;
    _categoryController.text = listing.category;
    _latitudeController.text = listing.latitude.toString();
    _longitudeController.text = listing.longitude.toString();
    _phoneController.text = listing.phone ?? '';
    _websiteController.text = listing.website ?? '';
    _descriptionController.text = listing.description ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.parse(_latitudeController.text.trim());
    final lng = double.parse(_longitudeController.text.trim());
    if (!LocationService.isWithinKigaliBounds(lat, lng)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location must be inside Kigali bounds.')),
      );
      return;
    }

    final existing = widget.existing;
    final service = ServiceModel(
      id: existing?.id ?? '',
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      latitude: lat,
      longitude: lng,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      createdBy: existing?.createdBy ?? widget.userId,
      timestamp: existing?.timestamp ?? DateTime.now(),
    );

    Navigator.of(context).pop(service);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Listing' : 'New Listing'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _latitudeController,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null) return 'Enter a valid latitude';
                  return null;
                },
              ),
              TextFormField(
                controller: _longitudeController,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null) return 'Enter a valid longitude';
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
              ),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Website (optional)'),
              ),
              TextFormField(
                controller: _descriptionController,
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
          onPressed: () => Navigator.of(context).pop(),
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
