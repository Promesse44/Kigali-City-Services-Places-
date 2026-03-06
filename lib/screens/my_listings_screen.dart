import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services.dart';
import '../providers/auth_provider.dart';
import '../providers/services_provider.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final servicesProvider = context.watch<ServicesProvider>();
    final userId = authProvider.firebaseUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view your listings')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: StreamBuilder<List<ServiceModel>>(
        stream: servicesProvider.getUserServicesStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final listings = snapshot.data ?? [];

          if (listings.isEmpty) {
            return const Center(
              child: Text('You have no listings yet'),
            );
          }

          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final service = listings[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(service.name),
                  subtitle: Text('${service.category}\n${service.description ?? ""}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditDialog(context, service, userId);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmDelete(context, service.id, userId);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, ServiceModel service, String userId) {
    final nameController = TextEditingController(text: service.name);
    final descController = TextEditingController(text: service.description);
    final phoneController = TextEditingController(text: service.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Listing'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updated = ServiceModel(
                id: service.id,
                name: nameController.text,
                category: service.category,
                latitude: service.latitude,
                longitude: service.longitude,
                phone: phoneController.text,
                website: service.website,
                description: descController.text,
                createdBy: service.createdBy,
                timestamp: service.timestamp,
              );
              await context.read<ServicesProvider>().updateService(
                service: updated,
                currentUserId: userId,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String serviceId, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<ServicesProvider>().deleteService(
                serviceId: serviceId,
                currentUserId: userId,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
