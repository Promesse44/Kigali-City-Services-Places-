import 'package:flutter/foundation.dart';

import '../models/service_model.dart';
import '../services/listing_service.dart';

class ServicesProvider extends ChangeNotifier {
  final ListingService _listingService = ListingService();
  String? _selectedCategory;

  String? get selectedCategory => _selectedCategory;

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Stream<List<ServiceModel>> getAllServicesStream() {
    return _listingService.getAllServices();
  }

  Stream<List<ServiceModel>> getFilteredServicesStream() {
    return _listingService.getAllServicesFiltered(
      category: _selectedCategory,
    );
  }

  Stream<List<ServiceModel>> getUserServicesStream(String userId) {
    return _listingService.getMyServices(userId);
  }

  Stream<List<String>> getCategoriesStream() {
    return _listingService.getCategoriesStream();
  }

  Future<void> addService(ServiceModel service) async {
    await _listingService.createService(service);
  }

  Future<void> updateService({
    required ServiceModel service,
    required String currentUserId,
  }) async {
    if (!service.isOwnedBy(currentUserId)) {
      throw Exception('You can only edit your own listings');
    }
    await _listingService.updateService(service);
  }

  Future<void> deleteService({
    required String serviceId,
    required String currentUserId,
  }) async {
    final existing = await _listingService.getServiceById(serviceId);
    if (existing == null) throw Exception('Listing not found');
    if (!existing.isOwnedBy(currentUserId)) {
      throw Exception('You can only delete your own listings');
    }
    await _listingService.deleteService(serviceId);
  }
}