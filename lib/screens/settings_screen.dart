import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../seed_data.dart';
import '../services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  String? _selectedDistrict;
  final _sectorController = TextEditingController();
  final _cellController = TextEditingController();
  final List<String> _districts = LocationService.getAvailableDistricts();

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  void _startEdit(UserModel? user) {
    _nameController.text = user?.fullName ?? '';
    _selectedDistrict = user?.district;
    _sectorController.text = user?.sector ?? '';
    _cellController.text = user?.cell ?? '';
    setState(() => _isEditing = true);
  }

  Future<void> _saveProfile() async {
    try {
      await context.read<AuthProvider>().updateProfile(
        fullName: _nameController.text.trim(),
        district: _selectedDistrict,
        sector: _sectorController.text.trim(),
        cell: _cellController.text.trim(),
      );
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _seedData() async {
    try {
      final alreadySeeded = await FirestoreSeeder.isAlreadySeeded();
      if (alreadySeeded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sample services already loaded!')),
          );
        }
        return;
      }
      await FirestoreSeeder.seedServices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kigali services loaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profile',
              onPressed: () => _startEdit(user),
            ),
        ],
      ),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Profile card ──────────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _isEditing
                          ? _buildEditForm(user)
                          : _buildProfileView(user),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Notifications toggle ──────────────────────────────────
                  Card(
                    child: SwitchListTile(
                      title: const Text('Location Notifications'),
                      subtitle: const Text(
                        'Receive alerts about services near you',
                      ),
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      secondary: const Icon(Icons.notifications_outlined),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Load sample data ──────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: _seedData,
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: const Text('Load Sample Kigali Services'),
                  ),

                  const SizedBox(height: 12),

                  // ── Logout ────────────────────────────────────────────────
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileView(UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        _infoRow(Icons.location_city, 'District', user?.district ?? 'Not set'),
        _infoRow(Icons.place, 'Sector', user?.sector ?? 'Not set'),
        _infoRow(Icons.grid_view, 'Cell', user?.cell ?? 'Not set'),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildEditForm(UserModel? user) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedDistrict,
          hint: const Text('Select District'),
          decoration: const InputDecoration(
            labelText: 'District',
            border: OutlineInputBorder(),
          ),
          items: _districts
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (v) => setState(() => _selectedDistrict = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sectorController,
          decoration: const InputDecoration(
            labelText: 'Sector',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cellController,
          decoration: const InputDecoration(
            labelText: 'Cell',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _saveProfile, child: const Text('Save')),
          ],
        ),
      ],
    );
  }
}
