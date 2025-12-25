import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? bookingId,
  }) async {
    try {
      print('Creating notification for user $userId: $message');
      await _db.collection('notifications').add({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'booking_id': bookingId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      print('Notification created successfully');
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Get notifications for a user
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      // Get all documents and convert to list
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by created_at manually (most recent first)
      notifications.sort((a, b) {
        final aTime = a['created_at'] as Timestamp?;
        final bTime = b['created_at'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      // Limit to 50 most recent
      return notifications.take(50).toList();
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({
        'is_read': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final notifications = await _db
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get unread count
  Stream<int> getUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Send notification when booking is created
  Future<void> notifyNewBooking({
    required String providerId,
    required String clientName,
    required String serviceName,
    required DateTime bookingDate,
    required String bookingId,
  }) async {
    await createNotification(
      userId: providerId,
      title: 'New Booking Request',
      message: '$clientName has requested a booking for $serviceName on ${bookingDate.day}/${bookingDate.month}/${bookingDate.year} at ${bookingDate.hour}:${bookingDate.minute.toString().padLeft(2, '0')}',
      type: 'new_booking',
      bookingId: bookingId,
    );
  }

  // Send notification when booking is accepted
  Future<void> notifyBookingAccepted({
    required String clientId,
    required String providerName,
    required String serviceName,
    required DateTime bookingDate,
    required String bookingId,
  }) async {
    await createNotification(
      userId: clientId,
      title: 'Booking Confirmed',
      message: '$providerName has accepted your booking for $serviceName on ${bookingDate.day}/${bookingDate.month}/${bookingDate.year} at ${bookingDate.hour}:${bookingDate.minute.toString().padLeft(2, '0')}',
      type: 'booking_accepted',
      bookingId: bookingId,
    );
  }

  // Send notification when booking is declined
  Future<void> notifyBookingDeclined({
    required String clientId,
    required String providerName,
    required String serviceName,
    required String bookingId,
  }) async {
    await createNotification(
      userId: clientId,
      title: 'Booking Declined',
      message: '$providerName has declined your booking request for $serviceName',
      type: 'booking_declined',
      bookingId: bookingId,
    );
  }

  // Send notification when booking is cancelled by client
  Future<void> notifyBookingCancelled({
    required String providerId,
    required String clientName,
    required String serviceName,
    required DateTime bookingDate,
    required String bookingId,
  }) async {
    await createNotification(
      userId: providerId,
      title: 'Booking Cancelled',
      message: '$clientName has cancelled their booking for $serviceName on ${bookingDate.day}/${bookingDate.month}/${bookingDate.year}',
      type: 'booking_cancelled',
      bookingId: bookingId,
    );
  }

  // Send upcoming booking reminder (1 hour before)
  Future<void> notifyUpcomingBooking({
    required String userId,
    required String serviceName,
    required String otherPartyName,
    required DateTime bookingDate,
    required String bookingId,
    required bool isProvider,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Upcoming Appointment',
      message: 'Reminder: You have an appointment for $serviceName with $otherPartyName in 1 hour at ${bookingDate.hour}:${bookingDate.minute.toString().padLeft(2, '0')}',
      type: 'upcoming_booking',
      bookingId: bookingId,
    );
  }

  // Check and send reminders for upcoming bookings (should be called periodically)
  Future<void> checkUpcomingBookings() async {
    try {
      final now = DateTime.now();
      final oneHourLater = now.add(const Duration(hours: 1));

      // Get all confirmed bookings that are upcoming
      final bookings = await _db
          .collection('bookings')
          .where('status', isEqualTo: 'confirmed')
          .where('booking_date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      print('Checking ${bookings.docs.length} confirmed bookings for reminders');

      for (var doc in bookings.docs) {
        final data = doc.data();
        final bookingDate = (data['booking_date'] as Timestamp).toDate();
        final timeDiff = bookingDate.difference(now);

        // Send notification if within 50-70 minutes (to account for check frequency)
        if (timeDiff.inMinutes >= 50 && timeDiff.inMinutes <= 70) {
          // Check if notification already sent
          final existingNotification = await _db
              .collection('notifications')
              .where('booking_id', isEqualTo: doc.id)
              .where('type', isEqualTo: 'upcoming_booking')
              .get();

          if (existingNotification.docs.isEmpty) {
            print('Sending reminder for booking ${doc.id} - ${timeDiff.inMinutes} minutes away');
            
            // Send to client
            await notifyUpcomingBooking(
              userId: data['client_id'],
              serviceName: data['service_name'],
              otherPartyName: data['provider_name'],
              bookingDate: bookingDate,
              bookingId: doc.id,
              isProvider: false,
            );

            // Send to provider
            await notifyUpcomingBooking(
              userId: data['provider_id'],
              serviceName: data['service_name'],
              otherPartyName: data['client_name'],
              bookingDate: bookingDate,
              bookingId: doc.id,
              isProvider: true,
            );
          }
        }
      }
    } catch (e) {
      print('Error checking upcoming bookings: $e');
    }
  }
}
