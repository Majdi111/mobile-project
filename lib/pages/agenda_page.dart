import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../models/booking_model.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final AuthController _authController = AuthController();
  final BookingController _bookingController = BookingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<BookingModel>> _bookingsByDate = {};
  List<BookingModel> _selectedDayBookings = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadBookings();
    // Update booking statuses on agenda load
    _bookingController.updateBookingStatusesBasedOnTime();
  }

  Future<void> _toggleFavorite(String providerId) async {
    final user = _authController.getCurrentUser();
    if (user == null) return;

    try {
      final clientRef = _db.collection('clients').doc(user.uid);
      final clientDoc = await clientRef.get();
      final data = clientDoc.data() ?? {};
      List<dynamic> favorites = data['favorite_providers'] ?? [];

      if (favorites.contains(providerId)) {
        // Remove from favorites
        favorites.remove(providerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
        }
      } else {
        // Add to favorites
        favorites.add(providerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites')),
          );
        }
      }

      await clientRef.set({
        'favorite_providers': favorites,
      }, SetOptions(merge: true));

      setState(() {}); // Refresh UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating favorites: $e')),
        );
      }
    }
  }

  Future<bool> _isFavorite(String providerId) async {
    final user = _authController.getCurrentUser();
    if (user == null) return false;

    try {
      final clientDoc = await _db.collection('clients').doc(user.uid).get();
      final data = clientDoc.data() ?? {};
      List<dynamic> favorites = data['favorite_providers'] ?? [];
      return favorites.contains(providerId);
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadBookings() async {
    final user = _authController.getCurrentUser();
    if (user == null) return;

    final snapshot = await _db
        .collection('bookings')
        .where('client_id', isEqualTo: user.uid)
        .get();

    final Map<DateTime, List<BookingModel>> bookingsByDate = {};

    for (var doc in snapshot.docs) {
      final booking = BookingModel.fromFirestore(doc);
      final dateKey = DateTime(
        booking.bookingDate.year,
        booking.bookingDate.month,
        booking.bookingDate.day,
      );

      if (bookingsByDate[dateKey] == null) {
        bookingsByDate[dateKey] = [];
      }
      bookingsByDate[dateKey]!.add(booking);
    }

    setState(() {
      _bookingsByDate = bookingsByDate;
      _selectedDayBookings = _getBookingsForDay(_selectedDay ?? DateTime.now());
    });
  }

  List<BookingModel> _getBookingsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _bookingsByDate[dateKey] ?? [];
  }

  List<BookingModel> _getBookingsForDayMarker(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    
    // Only show markers for today and future dates
    if (dateKey.isBefore(todayKey)) {
      return [];
    }
    
    return _bookingsByDate[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.getCurrentUser();
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Agenda'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Agenda'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedDayBookings = _getBookingsForDay(selectedDay);
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) {
                  return _getBookingsForDayMarker(day);
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                  markerSize: 8,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedDay != null
                          ? 'Appointments on ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
                          : 'Select a day',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _selectedDayBookings.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No appointments on this day',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _selectedDayBookings.length,
                    itemBuilder: (context, index) {
                      final booking = _selectedDayBookings[index];
                      return _buildBookingCard(booking);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    Color statusColor;
    IconData statusIcon;

    switch (booking.status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        booking.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.providerName,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ),
                ),
                FutureBuilder<bool>(
                  future: _isFavorite(booking.providerId),
                  builder: (context, snapshot) {
                    final isFav = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        _toggleFavorite(booking.providerId);
                      },
                      tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${booking.bookingDate.hour}:${booking.bookingDate.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
                const SizedBox(width: 24),
                const Icon(Icons.attach_money, size: 18, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  '${booking.price.toStringAsFixed(2)} TND',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (_shouldShowRating(booking)) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              if (booking.isRated)
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'You rated this service: ${booking.rating?.toStringAsFixed(1)} / 5.0',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRatingDialog(booking),
                    icon: const Icon(Icons.star_rate, size: 20),
                    label: const Text('Rate this service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  bool _shouldShowRating(BookingModel booking) {
    // Show rating only if status is completed
    return booking.status == 'completed';
  }

  void _showRatingDialog(BookingModel booking) {
    double rating = 3.0;
    final scaffoldContext = context;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.star_rate, color: Colors.amber),
              SizedBox(width: 8),
              Text('Rate Service'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                booking.serviceName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'by ${booking.providerName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'How would you rate this service?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        rating = (index + 1).toDouble();
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '${rating.toStringAsFixed(1)} / 5.0',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                // Show loading
                showDialog(
                  context: scaffoldContext,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                final result = await _bookingController.rateBooking(
                  booking.id,
                  booking.providerId,
                  rating,
                );

                // Close loading
                if (scaffoldContext.mounted) {
                  Navigator.of(scaffoldContext).pop();
                }

                if (result['success']) {
                  if (scaffoldContext.mounted) {
                    _loadBookings(); // Reload bookings
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for your rating!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (scaffoldContext.mounted) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${result['error']}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }
}
