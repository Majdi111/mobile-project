import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/provider_model.dart';

class ProviderController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch all providers with location data
  Future<List<ProviderModel>> getAllProviders() async {
    try {
      final snapshot = await _db
          .collection('providers')
          .get();

      return snapshot.docs
          .map((doc) => ProviderModel.fromFirestore(doc))
          .where((provider) => provider.hasLocation())
          .toList();
    } catch (e) {
      throw Exception('Error fetching providers: $e');
    }
  }

  // Stream all providers with location data
  Stream<List<ProviderModel>> getProvidersStream() {
    return _db
        .collection('providers')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProviderModel.fromFirestore(doc))
            .where((provider) => provider.hasLocation())
            .toList());
  }

  // Fetch providers within a bounding box
  // Note: Firestore doesn't support efficient bbox queries natively
  // This implementation fetches all providers and filters in memory
  // For production with many providers, consider using a geospatial index
  // or a service like GeoFirestore
  Future<List<ProviderModel>> getProvidersInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    try {
      final allProviders = await getAllProviders();

      return allProviders.where((provider) {
        if (!provider.hasLocation()) return false;
        
        return provider.latitude! >= minLat &&
            provider.latitude! <= maxLat &&
            provider.longitude! >= minLng &&
            provider.longitude! <= maxLng;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching providers in bounds: $e');
    }
  }

  // Fetch providers within a radius (in kilometers)
  // Uses simple distance calculation - for production, use proper geo library
  Future<List<ProviderModel>> getProvidersInRadius({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
  }) async {
    try {
      final allProviders = await getAllProviders();

      return allProviders.where((provider) {
        if (!provider.hasLocation()) return false;

        // Simple distance calculation (approximate)
        // 1 degree latitude ≈ 111 km
        // 1 degree longitude ≈ 111 km * cos(latitude)
        final latDiff = (provider.latitude! - centerLat) * 111;
        final lngDiff = (provider.longitude! - centerLng) * 111 * 
            (3.14159 / 180 * centerLat).abs();
        
        final distance = (latDiff * latDiff + lngDiff * lngDiff);
        return distance <= (radiusKm * radiusKm);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching providers in radius: $e');
    }
  }

  // Update provider location
  Future<Map<String, dynamic>> updateProviderLocation({
    required String providerId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      await _db.collection('providers').doc(providerId).update({
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get provider by ID
  Future<ProviderModel?> getProviderById(String providerId) async {
    try {
      final doc = await _db.collection('providers').doc(providerId).get();
      
      if (!doc.exists) return null;
      
      return ProviderModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Error fetching provider: $e');
    }
  }

  // Search providers by name or specialty
  Future<List<ProviderModel>> searchProviders(String query) async {
    try {
      final allProviders = await getAllProviders();
      
      final lowerQuery = query.toLowerCase();
      
      return allProviders.where((provider) {
        return provider.fullName.toLowerCase().contains(lowerQuery) ||
            (provider.specialty?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Error searching providers: $e');
    }
  }
}
