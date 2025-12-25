import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../controllers/notification_controller.dart';
import 'provider_details_page.dart';
import 'create_booking_page.dart';
import 'category_providers_page.dart';
import 'notifications_page.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  final AuthController _authController = AuthController();
  final BookingController _bookingController = BookingController();
  final NotificationController _notificationController = NotificationController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    // Update booking statuses on dashboard load
    _bookingController.updateBookingStatusesBasedOnTime();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      final lowerQuery = query.toLowerCase();
      final results = <Map<String, dynamic>>[];

      // Search providers by name
      final providersSnapshot = await _db
          .collection('providers')
          .get();

      for (var doc in providersSnapshot.docs) {
        final data = doc.data();
        final fullName = (data['full_name'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final specialty = (data['specialty'] ?? '').toString().toLowerCase();

        if (fullName.contains(lowerQuery) ||
            email.contains(lowerQuery) ||
            specialty.contains(lowerQuery)) {
          results.add({
            'type': 'provider',
            'id': doc.id,
            'title': data['full_name'] ?? 'Provider',
            'subtitle': data['specialty'] ?? data['email'] ?? '',
            'data': data,
          });
        }
      }

      // Search services by name and category
      final servicesSnapshot = await _db
          .collection('services')
          .where('is_available', isEqualTo: true)
          .get();

      for (var doc in servicesSnapshot.docs) {
        final data = doc.data();
        final serviceName = (data['service_name'] ?? '').toString().toLowerCase();
        final category = (data['category'] ?? '').toString().toLowerCase();
        final description = (data['description'] ?? '').toString().toLowerCase();

        if (serviceName.contains(lowerQuery) ||
            category.contains(lowerQuery) ||
            description.contains(lowerQuery)) {
          // Get provider info for this service
          final providerId = data['provider_id'];
          final providerDoc = await _db.collection('users').doc(providerId).get();
          final providerData = providerDoc.data() ?? {};

          results.add({
            'type': 'service',
            'id': doc.id,
            'providerId': providerId,
            'title': data['service_name'] ?? 'Service',
            'subtitle': '${data['provider_name'] ?? 'Provider'} • ${data['price']} TND',
            'category': data['category'] ?? '',
            'data': data,
            'providerData': providerData,
          });
        }
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  void _navigateToProvider(String providerId, Map<String, dynamic> providerData) {
    setState(() {
      _showSearchResults = false;
      _searchController.clear();
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderDetailsPage(
          providerId: providerId,
          providerData: providerData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.getCurrentUser();
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _notificationController.getUserNotifications(user.uid),
            builder: (context, snapshot) {
              final unreadCount = (snapshot.data ?? [])
                  .where((n) => n['is_read'] == false)
                  .length;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authController.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  _buildSearchBar(),
                  const SizedBox(height: 16),

                  // User Profile Section - Dynamic from DB
                  _buildUserProfileSection(user.uid),
                  const SizedBox(height: 24),

                  // Stats Section - Dynamic from DB
                  _buildStatsSection(user.uid),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.add_circle_outline,
                          label: 'New Booking',
                          color: Colors.purple,
                          onTap: () =>
                              Navigator.pushNamed(context, '/create-booking'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.search,
                          label: 'Browse Services',
                          color: Colors.blue,
                          onTap: () =>
                              Navigator.pushNamed(context, '/browse-services'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.bookmark_outline,
                          label: 'My Bookings',
                          color: Colors.green,
                          onTap: () => Navigator.pushNamed(context, '/my-bookings'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(), // Empty space for symmetry
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Categories Section
                  _buildCategoriesSection(),
                  const SizedBox(height: 24),

                  // Favorite Providers - Dynamic from DB
                  _buildFavoriteProvidersSection(user.uid),
                  const SizedBox(height: 24),

                  // Upcoming Bookings - Dynamic from DB
                  _buildUpcomingBookingsSection(user.uid),
                  const SizedBox(height: 24),

                  // Available Providers - Dynamic from DB
                  _buildAvailableProvidersSection(),
                ],
              ),
            ),
          ),

          // Search Results Overlay
          if (_showSearchResults) _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          _performSearch(value);
        },
        decoration: InputDecoration(
          hintText: 'Search providers or services...',
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showSearchResults = false;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping on results
            child: Container(
              margin: const EdgeInsets.only(top: 80, left: 16, right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isSearching
                                ? 'Searching...'
                                : _searchResults.isEmpty
                                    ? 'No results found'
                                    : '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'} found',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _showSearchResults = false;
                              _searchController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    )
                  else if (_searchResults.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No providers or services found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          final isProvider = result['type'] == 'provider';
                          
                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isProvider
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isProvider ? Icons.person : Icons.cut,
                                color: isProvider ? Colors.blue : Colors.green,
                              ),
                            ),
                            title: Text(
                              result['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(result['subtitle']),
                                if (!isProvider)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      result['category'] ?? 'Service',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              if (isProvider) {
                                _navigateToProvider(
                                  result['id'],
                                  result['data'],
                                );
                              } else {
                                // Navigate to booking page with preselected service
                                _navigateToProvider(
                                  result['providerId'],
                                  result['providerData'],
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dynamic User Profile from Firestore
  Widget _buildUserProfileSection(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('clients').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final userName = data['full_name'] ?? 'Client';
        final email = data['email'] ?? '';
        final profileImage = data['profileImage'] ?? '';

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
                  child: profileImage.isEmpty
                      ? Text(
                          (userName.isNotEmpty && userName.length > 0) ? userName[0].toUpperCase() : 'C',
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dynamic Stats from Firestore
  Widget _buildStatsSection(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('bookings')
          .where('client_id', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        int totalBookings = 0;
        int pendingBookings = 0;
        int completedBookings = 0;
        double totalSpent = 0;

        if (snapshot.hasData) {
          final bookings = snapshot.data!.docs;
          totalBookings = bookings.length;

          for (var doc in bookings) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] == 'pending') pendingBookings++;
            if (data['status'] == 'completed') {
              completedBookings++;
              totalSpent += (data['price'] ?? 0).toDouble();
            }
          }
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_today,
                    label: 'Total Bookings',
                    value: totalBookings.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.pending_actions,
                    label: 'Pending',
                    value: pendingBookings.toString(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    label: 'Completed',
                    value: completedBookings.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.attach_money,
                    label: 'Total Spent',
                    value: '${totalSpent.toStringAsFixed(0)} TND',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Dynamic Upcoming Bookings from Firestore
  Widget _buildUpcomingBookingsSection(String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Bookings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/my-bookings'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('bookings')
              .where('client_id', isEqualTo: uid)
              .where('status', whereIn: ['pending', 'confirmed'])
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No upcoming bookings',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final data =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                final bookingDate =
                    (data['booking_date'] as Timestamp).toDate();

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: const Icon(Icons.content_cut, color: Colors.blue),
                    ),
                    title: Text(data['service_name'] ?? 'Service'),
                    subtitle: Text(
                      '${data['provider_name']} • ${bookingDate.day}/${bookingDate.month}/${bookingDate.year}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: data['status'] == 'confirmed'
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        data['status']?.toUpperCase() ?? 'PENDING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: data['status'] == 'confirmed'
                              ? Colors.green[800]
                              : Colors.orange[800],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Dynamic Available Providers from Firestore
  Widget _buildCategoriesSection() {
    // Define available service categories
    final categories = [
      {'name': 'Haircut', 'icon': Icons.content_cut, 'color': Colors.purple},
      {'name': 'Makeup', 'icon': Icons.face, 'color': Colors.pink},
      {'name': 'Massage', 'icon': Icons.spa, 'color': Colors.teal},
      {'name': 'Nails', 'icon': Icons.brush, 'color': Colors.red},
      {'name': 'Facial', 'icon': Icons.face_retouching_natural, 'color': Colors.orange},
      {'name': 'Waxing', 'icon': Icons.health_and_safety, 'color': Colors.amber},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse by Category',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryProvidersPage(
                      category: category['name'] as String,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (category['color'] as Color).withOpacity(0.7),
                      (category['color'] as Color),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (category['color'] as Color).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFavoriteProvidersSection(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('clients').doc(uid).snapshots(),
      builder: (context, clientSnapshot) {
        if (!clientSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final clientData = clientSnapshot.data!.data() as Map<String, dynamic>?;
        final List<dynamic> favoriteIds = clientData?['favorite_providers'] ?? [];

        if (favoriteIds.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Favorite Providers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: favoriteIds.length,
                itemBuilder: (context, index) {
                  final providerId = favoriteIds[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future: _db.collection('providers').doc(providerId).get(),
                    builder: (context, providerSnapshot) {
                      if (!providerSnapshot.hasData) {
                        return const SizedBox(
                          width: 100,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final data = providerSnapshot.data!.data() as Map<String, dynamic>?;
                      if (data == null) return const SizedBox.shrink();

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProviderDetailsPage(
                                providerId: providerId,
                                providerData: data,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundColor: Colors.red[100],
                                    child: Text(
                                      _getInitial(data['full_name'] ?? 'P'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    data['full_name'] ?? 'Provider',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.star,
                                          size: 14, color: Colors.amber),
                                      Text(
                                        ' ${(data['rating'] ?? 0.0).toStringAsFixed(1)}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    _toggleFavorite(providerId);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableProvidersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Providers',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection('providers').orderBy('rating', descending: true).limit(3).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No providers available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final provider = snapshot.data!.docs[index];
                  final data = provider.data() as Map<String, dynamic>;
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProviderDetailsPage(
                            providerId: provider.id,
                            providerData: data,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.green[100],
                                child: Text(
                                  _getInitial(data['full_name'] ?? 'P'),
                                  style: const TextStyle(
                                      fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['full_name'] ?? 'Provider',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star,
                                      size: 14, color: Colors.amber),
                                  Text(
                                    ' ${(data['rating'] ?? 0.0).toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: FutureBuilder<bool>(
                          future: _isFavorite(provider.id),
                          builder: (context, snapshot) {
                            final isFav = snapshot.data ?? false;
                            return GestureDetector(
                              onTap: () {
                                _toggleFavorite(provider.id);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.grey,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitial(String name) {
    if (name.isEmpty) return 'P';
    return name[0].toUpperCase();
  }
}
