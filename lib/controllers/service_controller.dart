import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';

class ServiceController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new service
  Future<Map<String, dynamic>> addService({
    required String providerId,
    required String providerName,
    required String serviceName,
    required String description,
    required double price,
    required int duration,
    required String category,
    String imageUrl = '',
  }) async {
    try {
      await _db.collection('services').add({
        'provider_id': providerId,
        'provider_name': providerName,
        'service_name': serviceName,
        'description': description,
        'price': price,
        'duration': duration,
        'category': category,
        'image_url': imageUrl,
        'is_available': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get services by provider
  Stream<List<ServiceModel>> getProviderServices(String providerId) {
    return _db
        .collection('services')
        .where('provider_id', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceModel.fromFirestore(doc))
            .toList());
  }

  // Get all services
  Stream<List<ServiceModel>> getAllServices() {
    return _db
        .collection('services')
        .where('is_available', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceModel.fromFirestore(doc))
            .toList());
  }

  // Get services by category
  Stream<List<ServiceModel>> getServicesByCategory(String category) {
    return _db
        .collection('services')
        .where('category', isEqualTo: category)
        .where('is_available', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceModel.fromFirestore(doc))
            .toList());
  }

  // Update service
  Future<Map<String, dynamic>> updateService(
      String serviceId, Map<String, dynamic> data) async {
    try {
      await _db.collection('services').doc(serviceId).update(data);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Delete service
  Future<Map<String, dynamic>> deleteService(String serviceId) async {
    try {
      await _db.collection('services').doc(serviceId).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
