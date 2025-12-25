# Flutter Map Implementation for Client Side

## Overview
This implementation replaces Google Maps with `flutter_map` using OpenStreetMap tiles. This solution:
- ✅ **No payment required** - Uses free OSM tiles
- ✅ **No API keys needed** - No Google Maps API configuration
- ✅ **Full marker clustering** - Groups nearby providers for better UX
- ✅ **Debounced fetching** - Efficient provider loading on map movement
- ✅ **User location** - Shows user's current position
- ✅ **Search functionality** - Quick search for popular places

## What Was Implemented

### 1. Dependencies Added (pubspec.yaml)
```yaml
flutter_map: ^7.0.2              # Core map widget
latlong2: ^0.9.1                 # Latitude/longitude handling
http: ^1.2.0                     # HTTP requests (for future API calls)
flutter_map_marker_cluster: ^1.3.6  # Marker clustering
geolocator: ^13.0.1              # User location
```

### 2. New Files Created

#### **lib/models/provider_model.dart**
- `ProviderModel` class with location fields (latitude, longitude)
- Methods for parsing from Firestore and JSON
- Distance calculation helpers
- Location validation

#### **lib/controllers/provider_controller.dart**
- `getAllProviders()` - Fetch all providers with locations
- `getProvidersInBounds()` - Fetch providers in visible map area
- `getProvidersInRadius()` - Fetch providers within radius
- `searchProviders()` - Search by name or specialty
- `updateProviderLocation()` - Update provider coordinates

### 3. Updated Files

#### **lib/pages/providers_map_page.dart**
Complete rewrite with:
- **FlutterMap widget** with OSM tiles
- **Debounced map movement** - Fetches providers 500ms after user stops panning
- **Marker clustering** - Groups nearby markers with count badges
- **Search bar** - Quick navigation to popular Tunisia locations
- **User location button** - Centers map on user position
- **Provider details sheet** - Shows info when tapping markers
- **Loading indicators** - Visual feedback during data fetches
- **Provider count badge** - Shows total providers visible

#### **android/app/src/main/AndroidManifest.xml**
Added permissions:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### **ios/Runner/Info.plist**
Added location descriptions:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to show nearby providers on the map.</string>
```

## How It Works

### Map Initialization
1. Loads all providers from Firestore (only those with latitude/longitude)
2. Creates markers for each provider
3. Centers on Tunisia (Tunis) by default
4. Requests user location permission (optional)

### Debounced Provider Fetching
When user pans or zooms the map:
1. Waits 500ms after movement stops
2. Calculates current map bounds
3. Fetches providers within those bounds
4. Updates markers efficiently

### Marker Clustering
- Nearby providers automatically cluster
- Shows count in red circle
- Tap cluster to zoom in
- Individual markers appear on close zoom

### Search Functionality
Popular Tunisia locations:
- Tunis Center, La Marsa, Carthage
- Sidi Bou Said, Hammamet, Sousse
- Sfax, Ariana, Ben Arous, La Goulette

## Usage

### For Clients
1. Open app → Navigate to "Map" tab
2. See all providers with locations marked
3. Pan/zoom to explore
4. Tap marker to see provider details
5. Use search to jump to specific areas
6. Tap "My Location" to center on yourself

### For Developers

#### Add Provider Location (One-time Setup)
Providers need latitude/longitude in their Firestore document:

```dart
// In your provider registration/profile update
await FirebaseFirestore.instance
  .collection('users')
  .doc(providerId)
  .update({
    'latitude': 36.8065,   // Provider's actual location
    'longitude': 10.1815,
    'address': 'Tunis Center', // Optional
  });
```

#### Fetch Providers Programmatically
```dart
final controller = ProviderController();

// Get all providers
final all = await controller.getAllProviders();

// Get providers in bounds
final inBounds = await controller.getProvidersInBounds(
  minLat: 36.7, maxLat: 36.9,
  minLng: 10.1, maxLng: 10.3,
);

// Get providers within 5km radius
final nearby = await controller.getProvidersInRadius(
  centerLat: 36.8065,
  centerLng: 10.1815,
  radiusKm: 5,
);

// Search providers
final results = await controller.searchProviders('barber');
```

## OpenStreetMap Usage Policy

The app currently uses OSM's public tile server:
```
https://tile.openstreetmap.org/{z}/{x}/{y}.png
```

### Important Notes:
1. ✅ **Free for development/testing**
2. ⚠️ **Not for heavy production use**
3. 🔧 **Includes proper User-Agent** (required by OSM)
4. 📊 **Tile requests are debounced** to minimize load

### For Production (when traffic grows):
Consider these free/freemium options:
- **MapTiler** - 100k free requests/month
- **Thunderforest** - Free tier available
- **Stadia Maps** - Free tier for non-commercial
- **Self-host tiles** - Full control, requires server

To switch provider, just change the `urlTemplate` in [providers_map_page.dart](lib/pages/providers_map_page.dart#L480):
```dart
TileLayer(
  urlTemplate: 'https://your-tile-server/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.flutter_app.example',
)
```

## Performance Optimizations

1. **Debounced fetching** - 500ms delay prevents API spam
2. **Marker clustering** - Reduces overdraw on dense areas
3. **Bounds-based loading** - Only fetches visible providers (when implemented on backend)
4. **Small marker icons** - 40x40px to reduce draw cost
5. **Loading states** - Shows progress during fetches

## Future Enhancements

### Backend Optimization (Recommended)
Currently fetches all providers and filters client-side. For better performance:
1. Create Cloud Function endpoint:
   ```
   GET /api/providers?bbox=minLng,minLat,maxLng,maxLat
   ```
2. Add geospatial indexing (e.g., GeoFirestore, PostGIS)
3. Return only providers in requested bounds

### Geocoding
For address search (not just pre-defined places):
- Use **Nominatim** (free, low volume)
- Use **Photon** (open source)
- Use **MapTiler Geocoding** (free tier)

Add to your search:
```dart
Future<void> _searchAddress(String query) async {
  final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json';
  // Fetch and parse results
}
```

### Custom Marker Icons
Replace generic pin with custom images:
```dart
Marker(
  point: LatLng(lat, lng),
  width: 40,
  height: 40,
  child: Image.asset('assets/icons/provider_pin.png'),
)
```

## Troubleshooting

### Map doesn't show
- Check internet connection (needs to download tiles)
- Verify `INTERNET` permission in AndroidManifest.xml
- Check console for CORS errors (web only)

### No providers visible
- Ensure providers have `latitude` and `longitude` in Firestore
- Check `hasLocation()` returns true
- Verify providers collection name is 'users' with role='provider'

### Location permission denied
- User denied permission → Can still use map without location
- Re-request: Clear app data and reinstall

### Markers not clustering
- Zoom in further (clusters expand at higher zoom)
- Check `maxClusterRadius` value (currently 120)

## Testing

Run the app:
```bash
flutter run
```

Navigate to Map tab and verify:
- ✅ Map loads with Tunisia centered
- ✅ Providers appear as red pins
- ✅ Tapping marker shows details
- ✅ Search works for popular places
- ✅ Clustering groups nearby markers
- ✅ My Location button centers on user

## Summary

✅ **No Google Maps API needed**
✅ **No payment method required**
✅ **Free OpenStreetMap tiles**
✅ **Full marker clustering**
✅ **Debounced provider fetching**
✅ **User location support**
✅ **Search functionality**
✅ **Clean, modern UI**

The implementation is production-ready for small to medium traffic. Scale by moving to hosted tiles (MapTiler) or self-hosting when needed.
