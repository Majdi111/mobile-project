import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? specialty;
  final bool isAvailable;
  final DateTime? createdAt;
  final int? startingHour;
  final int? closingHour;

  ProviderModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    this.address,
    this.specialty,
    this.isAvailable = true,
    this.createdAt,
    this.startingHour,
    this.closingHour,
  });

  // Factory method to create ProviderModel from Firestore document
  factory ProviderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Try to get location from GeoPoint first, then fall back to separate lat/lng fields
    double? lat;
    double? lng;
    
    if (data['location'] is GeoPoint) {
      final geoPoint = data['location'] as GeoPoint;
      lat = geoPoint.latitude;
      lng = geoPoint.longitude;
    } else {
      lat = data['latitude']?.toDouble();
      lng = data['longitude']?.toDouble();
    }
    
    return ProviderModel(
      id: doc.id,
      fullName: data['full_name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phone_number'] ?? data['phone'],
      latitude: lat,
      longitude: lng,
      address: data['address'],
      specialty: data['specialty'],
      isAvailable: data['is_available'] ?? data['isAvailable'] ?? true,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : (data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate()
              : null),
      startingHour: data['starting_hour'] as int?,
      closingHour: data['closing_hour'] as int?,
    );
  }

  // Factory method to create from JSON (for API responses)
  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      address: json['address'],
      specialty: json['specialty'],
      isAvailable: json['is_available'] ?? json['isAvailable'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      startingHour: json['starting_hour'] as int?,
      closingHour: json['closing_hour'] as int?,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'specialty': specialty,
      'is_available': isAvailable,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      if (startingHour != null) 'starting_hour': startingHour,
      if (closingHour != null) 'closing_hour': closingHour,
    };
  }

  // Check if provider has valid location
  bool hasLocation() {
    return latitude != null && 
           longitude != null && 
           (latitude != 0 || longitude != 0);
  }

  // Calculate distance (simple euclidean distance, not considering earth curvature)
  // For more accurate distance, use a proper geo library
  double distanceTo(double lat, double lng) {
    if (latitude == null || longitude == null) return double.infinity;
    final dx = latitude! - lat;
    final dy = longitude! - lng;
    return (dx * dx + dy * dy);
  }
}
