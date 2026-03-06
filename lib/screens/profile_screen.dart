import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../seed_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;

  final _nameController = TextEditingController();
  String? _selectedDistrict;
  final _sectorController = TextEditingController();
  final _cellController = TextEditingController();
  final List<String> _kigaliDistricts = LocationService.getAvailableDistricts();

  @override
  void initState() {
    super.initState();
  }

  void _syncForm(UserModel? user) {
    if (_isEditing) return;
    _nameController.text = user?.fullName ?? '';
    _selectedDistrict = user?.district;
    _sectorController.text = user?.sector ?? '';
    _cellController.text = user?.cell ?? '';
  }

  Future<void> _updateProfile() async {
    try {
      await context.read<AuthProvider>().updateProfile(
        fullName: _nameController.text,
        district: _selectedDistrict,
        sector: _sectorController.text,
        cell: _cellController.text,
      );

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _seedData() async {
    try {
      final alreadySeeded = await FirestoreSeeder.isAlreadySeeded();
      if (alreadySeeded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Services already loaded!')),
          );
        }
        return;
      }

      await FirestoreSeeder.seedServices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kigali services loaded! Go to Services tab to see them.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error seeding data: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    context.read<LocationProvider>().clear();
    await context.read<AuthProvider>().logout();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sectorController.dispose();
    _cellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    _syncForm(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _syncForm(user);
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isEditing) _buildEditForm() else _buildProfileView(user),
                  const SizedBox(height: 24),
                  if (!_isEditing) ...[
                    ElevatedButton.icon(
                      onPressed: _seedData,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Load Sample Kigali Services'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildProfileView(UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileField('Email', user?.email ?? ''),
        _buildProfileField('Full Name', user?.fullName ?? ''),
        _buildProfileField('District', user?.district ?? 'Not provided'),
        _buildProfileField('Sector', user?.sector ?? 'Not provided'),
        _buildProfileField('Cell', user?.cell ?? 'Not provided'),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedDistrict,
            hint: const Text('Select District (Kigali)'),
            items: _kigaliDistricts
                .map(
                  (district) =>
                      DropdownMenuItem(value: district, child: Text(district)),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _selectedDistrict = value);
            },
            decoration: const InputDecoration(
              labelText: 'District (Kigali)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sectorController,
            decoration: const InputDecoration(
              labelText: 'Sector',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cellController,
            decoration: const InputDecoration(
              labelText: 'Cell',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
          Divider(),
        ],
      ),
    );
  }
}
