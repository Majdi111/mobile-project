import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../controllers/provider_controller.dart';
import '../models/provider_model.dart';
import 'provider_details_page.dart';

class ProvidersMapPage extends StatefulWidget {
  const ProvidersMapPage({super.key});

  @override
  State<ProvidersMapPage> createState() => _ProvidersMapPageState();
}

class _ProvidersMapPageState extends State<ProvidersMapPage> {
  final ProviderController _providerController = ProviderController();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  List<ProviderModel> _providers = [];
  List<Marker> _markers = [];
  Timer? _debounceTimer;
  bool _isLoading = false;
  LatLng? _userLocation;
  bool _showNearbyOnly = false;
  static const double _radiusKm = 5.0;
  
  // Default location (Tunisia, Tunis center)
  static const LatLng _defaultLocation = LatLng(36.8065, 10.1815);
  
  // Popular places in Tunisia for quick search
  final Map<String, LatLng> _popularPlaces = {
    'Tunis Center': const LatLng(36.8065, 10.1815),
    'La Marsa': const LatLng(36.8510, 10.1633),
    'Carthage': const LatLng(36.8333, 10.1667),
    'Sidi Bou Said': const LatLng(36.8625, 10.1956),
    'La Goulette': const LatLng(36.8188, 10.3051),
    'Ariana': const LatLng(36.8625, 10.1956),
    'Ben Arous': const LatLng(36.7538, 10.2300),
    'Hammamet': const LatLng(36.4000, 10.6167),
    'Sousse': const LatLng(35.8256, 10.6369),
    'Sfax': const LatLng(34.7406, 10.7603),
  };

  List<String> _searchResults = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _getUserLocation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Get user's current location
  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Silently fail - user location is optional
    }
  }

  // Load providers from Firestore
  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final providers = await _providerController.getAllProviders();
      _updateProviders(providers);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading providers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load providers in current map bounds (debounced)
  void _loadProvidersInBounds() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchProvidersInCurrentBounds();
    });
  }

  Future<void> _fetchProvidersInCurrentBounds() async {
    final bounds = _mapController.camera.visibleBounds;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final providers = await _providerController.getProvidersInBounds(
        minLat: bounds.south,
        maxLat: bounds.north,
        minLng: bounds.west,
        maxLng: bounds.east,
      );
      
      _updateProviders(providers);
    } catch (e) {
      // Silently fail for bounds updates
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateProviders(List<ProviderModel> providers) {
    List<ProviderModel> filteredProviders = providers;
    
    // Filter by distance if enabled and user location is available
    if (_showNearbyOnly && _userLocation != null) {
      filteredProviders = providers.where((provider) {
        if (provider.latitude == null || provider.longitude == null) return false;
        final distance = _calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          provider.latitude!,
          provider.longitude!,
        );
        return distance <= _radiusKm;
      }).toList();
    }
    
    setState(() {
      _providers = filteredProviders;
      _markers = filteredProviders.map((provider) {
        return Marker(
          point: LatLng(provider.latitude!, provider.longitude!),
          width: 40,
          height: 40,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToProviderDetails(provider),
              borderRadius: BorderRadius.circular(20),
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          ),
        );
      }).toList();
    });
  }
  
  // Calculate distance between two coordinates in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, LatLng(lat1, lon1), LatLng(lat2, lon2));
  }
  
  // Navigate to provider details page
  void _navigateToProviderDetails(ProviderModel provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderDetailsPage(
          providerId: provider.id,
          providerData: {
            'full_name': provider.fullName,
            'email': provider.email,
            'phone_number': provider.phoneNumber,
            'address': provider.address,
            'specialty': provider.specialty,
            'latitude': provider.latitude,
            'longitude': provider.longitude,
            'is_available': provider.isAvailable,
            if (provider.startingHour != null) 'starting_hour': provider.startingHour,
            if (provider.closingHour != null) 'closing_hour': provider.closingHour,
          },
        ),
      ),
    );
  }
  
  void _toggleNearbyFilter() {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available. Please enable location services.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _showNearbyOnly = !_showNearbyOnly;
    });
    
    // Reload providers with new filter
    _loadProviders();
  }

  void _showProvidersList() {
    if (_providers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_showNearbyOnly 
            ? 'No providers found within 5km' 
            : 'No providers available'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _showNearbyOnly ? 'Nearby Providers' : 'All Providers',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_providers.length} provider${_providers.length != 1 ? 's' : ''} found${_showNearbyOnly ? ' within 5km' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Provider List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _providers.length,
                  separatorBuilder: (context, index) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final provider = _providers[index];
                    double? distance;
                    
                    // Calculate distance if user location is available
                    if (_userLocation != null && provider.latitude != null && provider.longitude != null) {
                      distance = _calculateDistance(
                        _userLocation!.latitude,
                        _userLocation!.longitude,
                        provider.latitude!,
                        provider.longitude!,
                      );
                    }
                    
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToProviderDetails(provider);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.red[100],
                              child: Text(
                                provider.fullName.isNotEmpty
                                    ? provider.fullName[0].toUpperCase()
                                    : 'P',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.fullName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (provider.specialty != null)
                                    Text(
                                      provider.specialty!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  if (distance != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.place, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${distance.toStringAsFixed(2)} km away',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _searchPlace(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    final results = _popularPlaces.keys
        .where((place) => place.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      _searchResults = results;
      _showSearchResults = results.isNotEmpty;
    });
  }

  void _navigateToPlace(String placeName) {
    final location = _popularPlaces[placeName];
    if (location != null) {
      _mapController.move(location, 14);

      setState(() {
        _searchController.text = placeName;
        _showSearchResults = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _showSearchResults = false;
    });
    
    // Return to default location
    _mapController.move(_defaultLocation, 12);
  }

  void _centerOnUserLocation() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // FlutterMap with OSM tiles
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultLocation,
              initialZoom: 12,
              minZoom: 5,
              maxZoom: 18,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  // Debounced loading of providers in new bounds
                  _loadProvidersInBounds();
                }
              },
              onTap: (_, __) {
                setState(() {
                  _showSearchResults = false;
                });
              },
            ),
            children: [
              // OSM Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.flutter_app.example',
                maxZoom: 19,
              ),
              
              // Marker Cluster Layer
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 120,
                  size: const Size(40, 40),
                  markers: _markers,
                  builder: (context, markers) {
                    return Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // User location marker (if available)
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.3),
                          border: Border.all(color: Colors.blue, width: 3),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Loading indicator
          if (_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          
          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _searchPlace,
                      decoration: InputDecoration(
                        hintText: 'Search for a place...',
                        prefixIcon: const Icon(Icons.search, color: Colors.blue),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: _clearSearch,
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
                    
                    // Search Results
                    if (_showSearchResults && _searchResults.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final place = _searchResults[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on, color: Colors.blue),
                              title: Text(place),
                              onTap: () => _navigateToPlace(place),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Quick Access Buttons
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'my_location',
                  mini: true,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                  onPressed: _centerOnUserLocation,
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'refresh',
                  mini: true,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.refresh, color: Colors.blue),
                  onPressed: _loadProviders,
                ),
              ],
            ),
          ),
          
          // Provider count badge and filter toggle
          Positioned(
            bottom: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter toggle button
                GestureDetector(
                  onTap: _toggleNearbyFilter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _showNearbyOnly ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _showNearbyOnly ? Colors.blue : Colors.grey,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showNearbyOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
                          color: _showNearbyOnly ? Colors.white : Colors.grey[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showNearbyOnly ? 'Within 5km' : 'Show All',
                          style: TextStyle(
                            color: _showNearbyOnly ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Provider count badge - clickable
                GestureDetector(
                  onTap: _showProvidersList,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_providers.length} Providers',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
