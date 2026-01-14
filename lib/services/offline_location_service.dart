import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineLocationService {
  static const String _keyLastLat = 'last_latitude';
  static const String _keyLastLng = 'last_longitude';
  static const String _keyLastAltitude = 'last_altitude';
  static const String _keyLastAccuracy = 'last_accuracy';
  static const String _keyLastTimestamp = 'last_timestamp';

  /// Get location: returns cached immediately if available, updates in background
  static Future<Position?> getCurrentPosition({
    bool forceRefresh = false,
  }) async {
    // Check if we have cached data
    final hasCached = await hasCachedLocation();

    if (hasCached && !forceRefresh) {
      // Return cached immediately for instant load
      final cachedPosition = await _getCachedLocation();

      // Update in background silently (don't await)
      _updateLocationInBackground();

      return cachedPosition;
    }

    // First time or force refresh: wait for fresh location
    return await _fetchAndCacheLocation();
  }

  /// Fetch fresh location and cache it
  static Future<Position?> _fetchAndCacheLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Cache the location for offline use
      await _cacheLocation(position);
      return position;
    } catch (e) {
      print('Failed to get online location: $e');
      // If fetch fails, return cached if available
      return await _getCachedLocation();
    }
  }

  /// Update location in background (fire and forget)
  static void _updateLocationInBackground() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await _cacheLocation(position);
      print('Background location update successful');
    } catch (e) {
      print('Background location update failed: $e');
      // Silently fail - user is already using cached location
    }
  }

  /// Get last known position (cached)
  static Future<Position?> getLastKnownPosition() async {
    try {
      // First try Geolocator's last known position
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        await _cacheLocation(position);
        return position;
      }
    } catch (e) {
      print('Failed to get last known position: $e');
    }

    // Fallback to cached location
    return await _getCachedLocation();
  }

  /// Cache location data
  static Future<void> _cacheLocation(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyLastLat, position.latitude);
      await prefs.setDouble(_keyLastLng, position.longitude);
      await prefs.setDouble(_keyLastAltitude, position.altitude);
      await prefs.setDouble(_keyLastAccuracy, position.accuracy);
      await prefs.setInt(
        _keyLastTimestamp,
        position.timestamp.millisecondsSinceEpoch,
      );
      print('Location cached: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Failed to cache location: $e');
    }
  }

  /// Retrieve cached location
  static Future<Position?> _getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lat = prefs.getDouble(_keyLastLat);
      final lng = prefs.getDouble(_keyLastLng);

      if (lat == null || lng == null) {
        return null;
      }

      final altitude = prefs.getDouble(_keyLastAltitude) ?? 0.0;
      final accuracy = prefs.getDouble(_keyLastAccuracy) ?? 0.0;
      final timestampMs =
          prefs.getInt(_keyLastTimestamp) ??
          DateTime.now().millisecondsSinceEpoch;

      return Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
        accuracy: accuracy,
        altitude: altitude,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    } catch (e) {
      print('Failed to get cached location: $e');
      return null;
    }
  }

  /// Check if we have cached location
  static Future<bool> hasCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyLastLat) && prefs.containsKey(_keyLastLng);
    } catch (e) {
      return false;
    }
  }

  /// Clear cached location
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastLat);
      await prefs.remove(_keyLastLng);
      await prefs.remove(_keyLastAltitude);
      await prefs.remove(_keyLastAccuracy);
      await prefs.remove(_keyLastTimestamp);
    } catch (e) {
      print('Failed to clear location cache: $e');
    }
  }

  /// Get cache age in hours
  static Future<int?> getCacheAgeInHours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampMs = prefs.getInt(_keyLastTimestamp);

      if (timestampMs == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);

      return difference.inHours;
    } catch (e) {
      return null;
    }
  }
}
