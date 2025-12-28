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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Please sign in'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue[900]!, Colors.blue[800]!],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Schedule',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: null,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadBookings,
                  tooltip: 'Refresh',
                  color: Colors.white,
                ),
              ),
            ],
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendar Card
                  _buildModernCalendar(),
                  const SizedBox(height: 32),

                  // Schedule Title
                  _buildScheduleHeader(),
                  const SizedBox(height: 16),

                  // Appointments List
                  _buildAppointmentsList(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning! 🌅';
    if (hour < 18) return 'Good afternoon! ☀️';
    return 'Good evening! 🌙';
  }

  Widget _buildModernCalendar() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
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
              color: Colors.blue[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue[900]!, width: 2),
            ),
            selectedDecoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[600]!],
              ),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Colors.red[500],
              shape: BoxShape.circle,
            ),
            markersMaxCount: 1,
            markerSize: 8,
            markersAlignment: Alignment.bottomCenter,
            weekendTextStyle: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left_rounded,
              color: Colors.blue[700],
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_rounded,
              color: Colors.blue[700],
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
            weekendStyle: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedDay != null
              ? _formatDateHeader(_selectedDay!)
              : 'Select a day',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedDay != null ? _getScheduleSubtitle() : '',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (isSameDay(date, now)) {
      return 'Today';
    } else if (isSameDay(date, now.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else if (isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return 'Schedule • ${date.day}/${date.month}/${date.year}';
  }

  String _getScheduleSubtitle() {
    if (_selectedDayBookings.isEmpty) {
      return "You're all clear today 🎉";
    }
    return '${_selectedDayBookings.length} appointment${_selectedDayBookings.length > 1 ? 's' : ''}';
  }

  Widget _buildAppointmentsList() {
    if (_selectedDay == null) {
      return _buildEmptyState();
    }

    if (_selectedDayBookings.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: List.generate(
        _selectedDayBookings.length,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAppointmentCard(_selectedDayBookings[index]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 48,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "You're all clear! 🎉",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No appointments scheduled for this day',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/create-booking'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Appointment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BookingModel booking) {
    final statusColor = _getStatusColor(booking.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Status Indicator
          Container(
            width: 6,
            height: 120,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatTime(booking.bookingDate),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    booking.serviceName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.providerName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[600]!],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () => Navigator.pushNamed(context, '/create-booking'),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }
}
