import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import 'notification_controller.dart';

class BookingController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationController _notificationController = NotificationController();

  // Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required String clientId,
    required String clientName,
    required String providerId,
    required String providerName,
    required String serviceId,
    required String serviceName,
    required double price,
    required int duration,
    required DateTime bookingDate,
  }) async {
    try {
      final docRef = await _db.collection('bookings').add({
        'client_id': clientId,
        'client_name': clientName,
        'provider_id': providerId,
        'provider_name': providerName,
        'service_id': serviceId,
        'service_name': serviceName,
        'price': price,
        'duration': duration,
        'booking_date': Timestamp.fromDate(bookingDate),
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      // Send notification to provider
      await _notificationController.notifyNewBooking(
        providerId: providerId,
        clientName: clientName,
        serviceName: serviceName,
        bookingDate: bookingDate,
        bookingId: docRef.id,
      );

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get client bookings
  Stream<List<BookingModel>> getClientBookings(String clientId) {
    return _db
        .collection('bookings')
        .where('client_id', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
      // Sort in memory instead of using orderBy to avoid index issues
      bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      return bookings;
    });
  }

  // Get provider bookings
  Stream<List<BookingModel>> getProviderBookings(String providerId) {
    return _db
        .collection('bookings')
        .where('provider_id', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
      // Sort in memory instead of using orderBy to avoid index issues
      bookings.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
      return bookings;
    });
  }

  // Update booking status
  Future<Map<String, dynamic>> updateBookingStatus(
      String bookingId, String status) async {
    try {
      // Get booking data first for notifications
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      final bookingData = bookingDoc.data();
      
      await _db.collection('bookings').doc(bookingId).update({
        'status': status,
      });

      // Send appropriate notifications
      if (bookingData != null) {
        if (status == 'confirmed') {
          await _notificationController.notifyBookingAccepted(
            clientId: bookingData['client_id'],
            providerName: bookingData['provider_name'],
            serviceName: bookingData['service_name'],
            bookingDate: (bookingData['booking_date'] as Timestamp).toDate(),
            bookingId: bookingId,
          );
        } else if (status == 'cancelled') {
          // Notify the other party about cancellation
          // This could be improved to detect who cancelled
          await _notificationController.notifyBookingDeclined(
            clientId: bookingData['client_id'],
            providerName: bookingData['provider_name'],
            serviceName: bookingData['service_name'],
            bookingId: bookingId,
          );
        }
      }

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Cancel booking
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      // Get booking data for notification
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      final bookingData = bookingDoc.data();
      
      await _db.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
      });

      // Send notification to provider
      if (bookingData != null) {
        await _notificationController.notifyBookingCancelled(
          providerId: bookingData['provider_id'],
          clientName: bookingData['client_name'],
          serviceName: bookingData['service_name'],
          bookingDate: (bookingData['booking_date'] as Timestamp).toDate(),
          bookingId: bookingId,
        );
      }

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Rate a booking and update provider rating
  Future<Map<String, dynamic>> rateBooking(
      String bookingId, String providerId, double rating) async {
    try {
      // First, check if already rated
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      if (bookingDoc.data()?['is_rated'] == true) {
        return {'success': false, 'error': 'This booking has already been rated'};
      }

      // Update booking with rating
      await _db.collection('bookings').doc(bookingId).update({
        'rating': rating,
        'is_rated': true,
      });

      // Update provider rating
      final providerDoc = await _db.collection('providers').doc(providerId).get();
      final providerData = providerDoc.data() ?? {};
      
      final currentTotalRating = (providerData['total_rating'] ?? 0).toDouble();
      final currentRatingCount = (providerData['rating_count'] ?? 0);
      
      final newTotalRating = currentTotalRating + rating;
      final newRatingCount = currentRatingCount + 1;
      final newAverageRating = newTotalRating / newRatingCount;

      await _db.collection('providers').doc(providerId).update({
        'total_rating': newTotalRating,
        'rating_count': newRatingCount,
        'rating': newAverageRating,
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Auto-update booking statuses based on time
  Future<void> updateBookingStatusesBasedOnTime() async {
    try {
      final now = DateTime.now();
      
      // Get all bookings that are pending
      final pendingSnapshot = await _db
          .collection('bookings')
          .where('status', isEqualTo: 'pending')
          .get();
      
      // Get all bookings that are confirmed or in-progress
      final confirmedSnapshot = await _db
          .collection('bookings')
          .where('status', isEqualTo: 'confirmed')
          .get();
      
      final inProgressSnapshot = await _db
          .collection('bookings')
          .where('status', isEqualTo: 'in-progress')
          .get();

      // Cancel pending bookings if their time has passed
      for (var doc in pendingSnapshot.docs) {
        final data = doc.data();
        final bookingDate = (data['booking_date'] as Timestamp).toDate();
        
        // If booking time has passed and still pending, cancel it
        if (now.isAfter(bookingDate)) {
          await doc.reference.update({'status': 'cancelled'});
        }
      }

      // Update confirmed bookings to in-progress if their time has come
      for (var doc in confirmedSnapshot.docs) {
        final data = doc.data();
        final bookingDate = (data['booking_date'] as Timestamp).toDate();
        
        // If booking time has arrived or passed, change to in-progress
        if (now.isAfter(bookingDate) || now.isAtSameMomentAs(bookingDate)) {
          await doc.reference.update({'status': 'in-progress'});
        }
      }

      // Update in-progress bookings to completed if their duration has ended
      for (var doc in inProgressSnapshot.docs) {
        final data = doc.data();
        final bookingDate = (data['booking_date'] as Timestamp).toDate();
        final duration = data['duration'] ?? 60; // default 60 minutes
        final endTime = bookingDate.add(Duration(minutes: duration));
        
        // If booking end time has passed, change to completed
        if (now.isAfter(endTime)) {
          await doc.reference.update({'status': 'completed'});
        }
      }
    } catch (e) {
      // Silent fail - this is a background operation
      print('Error updating booking statuses: $e');
    }
  }

  // Check and update a specific booking's status
  Future<void> checkAndUpdateBookingStatus(String bookingId) async {
    try {
      final doc = await _db.collection('bookings').doc(bookingId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final status = data['status'];
      final bookingDate = (data['booking_date'] as Timestamp).toDate();
      final duration = data['duration'] ?? 60;
      final now = DateTime.now();

      // Check if status should be updated
      if (status == 'pending' && now.isAfter(bookingDate)) {
        // Cancel pending bookings whose time has passed
        await doc.reference.update({'status': 'cancelled'});
      } else if (status == 'confirmed' && now.isAfter(bookingDate)) {
        await doc.reference.update({'status': 'in-progress'});
      } else if (status == 'in-progress') {
        final endTime = bookingDate.add(Duration(minutes: duration));
        if (now.isAfter(endTime)) {
          await doc.reference.update({'status': 'completed'});
        }
      }
    } catch (e) {
      print('Error checking booking status: $e');
    }
  }
}
