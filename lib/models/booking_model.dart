import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String clientId;
  final String clientName;
  final String providerId;
  final String providerName;
  final String serviceId;
  final String serviceName;
  final double price;
  final int duration; // in minutes
  final DateTime bookingDate;
  final String status; // pending, confirmed, in-progress, completed, cancelled
  final DateTime createdAt;
  final double? rating;
  final bool isRated;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.providerId,
    required this.providerName,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.duration,
    required this.bookingDate,
    required this.status,
    required this.createdAt,
    this.rating,
    this.isRated = false,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      clientId: data['client_id'] ?? '',
      clientName: data['client_name'] ?? '',
      providerId: data['provider_id'] ?? '',
      providerName: data['provider_name'] ?? '',
      serviceId: data['service_id'] ?? '',
      serviceName: data['service_name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      duration: data['duration'] ?? 60,
      bookingDate:
          (data['booking_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: data['rating']?.toDouble(),
      isRated: data['is_rated'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'client_id': clientId,
      'client_name': clientName,
      'provider_id': providerId,
      'provider_name': providerName,
      'service_id': serviceId,
      'service_name': serviceName,
      'price': price,
      'duration': duration,
      'booking_date': Timestamp.fromDate(bookingDate),
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'rating': rating,
      'is_rated': isRated,
    };
  }
}
