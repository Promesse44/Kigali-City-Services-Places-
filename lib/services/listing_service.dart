import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_model.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('services');

  Stream<List<ServiceModel>> getAllServices() {
    return _col
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ServiceModel.fromFirestore).toList());
  }

  Stream<List<ServiceModel>> getAllServicesFiltered({String? category}) {
    Query<Map<String, dynamic>> query = _col;
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ServiceModel.fromFirestore).toList());
  }

  Stream<List<ServiceModel>> getMyServices(String uid) {
    return _col.where('createdBy', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(ServiceModel.fromFirestore).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<DocumentReference> createService(ServiceModel service) async {
    return await _col.add(service.toMap());
  }

  Future<void> updateService(ServiceModel service) async {
    await _col.doc(service.id).update(service.toMap());
  }

  Future<void> deleteService(String id) async {
    await _col.doc(id).delete();
  }

  Future<ServiceModel?> getServiceById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ServiceModel.fromFirestore(doc);
  }

  Stream<List<String>> getCategoriesStream() {
    return _col.snapshots().map((snap) {
      final categories = snap.docs
          .map((doc) => doc.data()['category'] as String?)
          .whereType<String>()
          .where((c) => c.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      return categories;
    });
  }
}
