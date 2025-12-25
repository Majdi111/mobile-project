import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String providerId;
  final String providerName;
  final String serviceName;
  final String description;
  final double price;
  final int duration; // in minutes
  final String category;
  final String imageUrl;
  final bool isAvailable;
  final DateTime createdAt;

  ServiceModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.serviceName,
    required this.description,
    required this.price,
    required this.duration,
    required this.category,
    required this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
  });

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      providerId: data['provider_id'] ?? '',
      providerName: data['provider_name'] ?? '',
      serviceName: data['service_name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      duration: data['duration'] ?? 0,
      category: data['category'] ?? '',
      imageUrl: data['image_url'] ?? '',
      isAvailable: data['is_available'] ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider_id': providerId,
      'provider_name': providerName,
      'service_name': serviceName,
      'description': description,
      'price': price,
      'duration': duration,
      'category': category,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
