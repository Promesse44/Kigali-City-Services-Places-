import 'package:flutter/foundation.dart';
import '../services.dart';

class ServicesProvider extends ChangeNotifier {
  final ServiceRepository _repository = ServiceRepository();
  String? _selectedCategory;

  String? get selectedCategory => _selectedCategory;

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Stream<List<ServiceModel>> getAllServicesStream() {
    return _repository.getServicesStream();
  }

  Stream<List<ServiceModel>> getFilteredServicesStream() {
    return _repository.getServicesStream(category: _selectedCategory);
  }

  Stream<List<ServiceModel>> getUserServicesStream(String userId) {
    return _repository.getUserServicesStream(userId);
  }

  Stream<List<String>> getCategoriesStream() {
    return _repository.getCategoriesStream();
  }

  Future<void> addService(ServiceModel service) async {
    await _repository.addService(service);
  }

  Future<void> updateService({
    required ServiceModel service,
    required String currentUserId,
  }) async {
    await _repository.updateService(
      service: service,
      currentUserId: currentUserId,
    );
  }

  Future<void> deleteService({
    required String serviceId,
    required String currentUserId,
  }) async {
    await _repository.deleteService(
      serviceId: serviceId,
      currentUserId: currentUserId,
    );
  }
}
