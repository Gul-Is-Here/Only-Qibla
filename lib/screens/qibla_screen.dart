import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../widgets/qibla_compass.dart';
import '../widgets/qibla_map_view.dart';
import '../widgets/location_error_widget.dart';
import '../widgets/compass_calibration_widget.dart';
import '../services/offline_location_service.dart';
import '../services/connectivity_service.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  final _locationStreamController = FlutterQiblah.androidDeviceSensorSupport();
  int _currentViewIndex = 0; // 0 = Compass, 1 = Map
  bool _showCalibration = false;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isOfflineMode = false;
  Timer? _backgroundUpdateTimer;
  bool _isUpdatingInBackground = false;

  // Kaaba coordinates
  static const kaabaLat = 21.4225;
  static const kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startBackgroundUpdates();
  }

  @override
  void dispose() {
    _backgroundUpdateTimer?.cancel();
    super.dispose();
  }

  /// Start periodic background updates (every 5 minutes)
  void _startBackgroundUpdates() {
    _backgroundUpdateTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _updateLocationSilently(),
    );
  }

  /// Update location silently in background
  Future<void> _updateLocationSilently() async {
    if (_isUpdatingInBackground) return; // Prevent concurrent updates

    setState(() => _isUpdatingInBackground = true);

    try {
      // Check internet connectivity first
      final hasInternet = await ConnectivityService.quickConnectivityCheck();

      if (hasInternet) {
        // Force refresh to get new location
        final position = await OfflineLocationService.getCurrentPosition(
          forceRefresh: true,
        );

        if (position != null && mounted) {
          setState(() {
            _currentPosition = position;
            _isOfflineMode = false;
          });

          print('Background location update successful');
        }
      }
    } catch (e) {
      print('Silent background update failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingInBackground = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Smart location fetch: returns cached instantly if available,
      // updates in background when internet is available
      Position? position = await OfflineLocationService.getCurrentPosition();

      if (position == null) {
        setState(() => _isLoadingLocation = false);
        _showErrorSnackBar(
          'No location available. Please enable GPS and grant permissions.',
        );
        return;
      }

      // Check if using cached location
      final hasCached = await OfflineLocationService.hasCachedLocation();
      final cacheAge = await OfflineLocationService.getCacheAgeInHours();

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
        _isOfflineMode = hasCached && (cacheAge ?? 0) > 0;
      });

      // Show subtle success message
      if (mounted) {
        final locationText = _isOfflineMode && cacheAge != null && cacheAge > 0
            ? 'Location loaded (cached ${cacheAge}h ago, updating...)'
            : 'Location acquired successfully';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _isOfflineMode ? Icons.cloud_queue : Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(locationText)),
              ],
            ),
            backgroundColor: _isOfflineMode
                ? Colors.orange.shade700
                : const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showErrorSnackBar('Error getting location. Please try again.');
    }
  }

  /// Force refresh location (manual user action)
  Future<void> _forceRefreshLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Force fresh GPS location
      Position? position = await OfflineLocationService.getCurrentPosition(
        forceRefresh: true,
      );

      if (position == null) {
        setState(() => _isLoadingLocation = false);
        _showErrorSnackBar(
          'Unable to get fresh location. Please check GPS and internet.',
        );
        return;
      }

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
        _isOfflineMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Location refreshed: ${position.latitude.toStringAsFixed(4)}°, ${position.longitude.toStringAsFixed(4)}°',
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showErrorSnackBar('Error refreshing location. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () => Geolocator.openLocationSettings(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _currentViewIndex == 1
            ? null // No gradient for map view (full screen map)
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D1B0F),
                    Color(0xFF1A3A1C),
                    Color(0xFF0D1B0F),
                  ],
                ),
              ),
        child: SafeArea(
          child: Column(
            children: [
              if (_currentViewIndex != 1) _buildAppBar(),
              Expanded(
                child: FutureBuilder(
                  future: _locationStreamController,
                  builder: (context, AsyncSnapshot<bool?> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoading('Initializing sensors...');
                    }
                    if (snapshot.hasError || snapshot.data == false) {
                      return LocationErrorWidget(
                        error: "Device sensors not supported",
                        onRetry: () => setState(() {}),
                      );
                    }
                    return _buildQiblaContent();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: 'Map',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: 'Compass',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.mosque_outlined,
                activeIcon: Icons.mosque,
                label: 'Mosques',
                index: 2,
                onTap: _findNearbyMosques,
              ),
              _buildNavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                index: 3,
                onTap: _showSettingsDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    final isActive = _currentViewIndex == index && onTap == null;
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _currentViewIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? const Color(0xFF4CAF50) : Colors.grey,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF4CAF50) : Colors.grey,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A3A1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingsItem(
              icon: Icons.share,
              title: 'Share Qibla Direction',
              onTap: () {
                Navigator.pop(context);
                _shareQiblaDirection();
              },
            ),
            _buildSettingsItem(
              icon: Icons.explore,
              title: 'Calibrate Compass',
              onTap: () {
                Navigator.pop(context);
                setState(() => _showCalibration = !_showCalibration);
              },
            ),
            _buildSettingsItem(
              icon: Icons.info_outline,
              title: 'About Qibla',
              onTap: () {
                Navigator.pop(context);
                _showInfoDialog();
              },
            ),
            _buildSettingsItem(
              icon: Icons.my_location,
              title: 'Refresh Location',
              onTap: () {
                Navigator.pop(context);
                _getCurrentLocation();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4CAF50)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu button with more options
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white70),
            color: const Color(0xFF1A3A1C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareQiblaDirection();
                  break;
                case 'mosques':
                  _findNearbyMosques();
                  break;
                case 'info':
                  _showInfoDialog();
                  break;
                case 'calibrate':
                  setState(() => _showCalibration = !_showCalibration);
                  break;
              }
            },
            itemBuilder: (context) => [
              _buildMenuItem(Icons.share, 'Share Qibla', 'share'),
              _buildMenuItem(Icons.mosque, 'Nearby Mosques', 'mosques'),
              _buildMenuItem(Icons.explore, 'Calibrate Compass', 'calibrate'),
              _buildMenuItem(Icons.info_outline, 'About Qibla', 'info'),
            ],
          ),

          // Title with logo and offline indicator
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('🕋', style: TextStyle(fontSize: 20));
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Only Qibla',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_isUpdatingInBackground)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green.shade400,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (_isOfflineMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, size: 12, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Refresh location button
          IconButton(
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4CAF50),
                    ),
                  )
                : const Icon(Icons.my_location, color: Colors.white70),
            onPressed: _isLoadingLocation ? null : _forceRefreshLocation,
            tooltip: 'Refresh location',
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    IconData icon,
    String text,
    String value,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildLoading(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF4CAF50)),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaContent() {
    return Column(
      children: [
        // Calibration helper (optional) - only for compass view
        if (_showCalibration && _currentViewIndex == 0)
          const CompassCalibrationWidget(),

        // Main content
        Expanded(
          child: StreamBuilder<QiblahDirection>(
            stream: FlutterQiblah.qiblahStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoading('Getting Qibla direction...');
              }
              if (snapshot.hasError) {
                return LocationErrorWidget(
                  error: snapshot.error.toString(),
                  onRetry: () => setState(() {}),
                );
              }
              if (!snapshot.hasData) {
                return LocationErrorWidget(
                  error: "Unable to get Qibla direction",
                  onRetry: () => setState(() {}),
                );
              }

              final qiblahDirection = snapshot.data!;

              // Map view - full screen
              if (_currentViewIndex == 1) {
                return QiblaMapView(
                  key: const ValueKey('map'),
                  qiblahDirection: qiblahDirection,
                  currentPosition: _currentPosition,
                );
              }

              // Compass view with bottom info
              return Column(
                children: [
                  Expanded(
                    child: QiblaCompass(
                      key: const ValueKey('compass'),
                      qiblahDirection: qiblahDirection,
                    ),
                  ),
                  _buildBottomInfo(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInfo() {
    final distance = _calculateDistance();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.location_on,
                label: 'Kaaba',
                value: 'Makkah',
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildInfoItem(
                icon: Icons.straighten,
                label: 'Distance',
                value: _currentPosition != null
                    ? '${distance.toStringAsFixed(0)} km'
                    : '...',
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildInfoItem(
                icon: Icons.gps_fixed,
                label: 'Accuracy',
                value: _currentPosition != null
                    ? '${_currentPosition!.accuracy.toStringAsFixed(0)}m'
                    : '...',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: _shareQiblaDirection,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.mosque,
                  label: 'Mosques',
                  onTap: _findNearbyMosques,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.refresh,
                  label: 'Refresh',
                  onTap: _getCurrentLocation,
                  isLoading: _isLoadingLocation,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4CAF50),
                    ),
                  )
                : Icon(icon, color: const Color(0xFF4CAF50), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4CAF50), size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  double _calculateDistance() {
    if (_currentPosition == null) return 0;

    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          kaabaLat,
          kaabaLng,
        ) /
        1000; // Convert to km
  }

  // Share Qibla direction
  void _shareQiblaDirection() async {
    final distance = _calculateDistance();
    final lat = _currentPosition?.latitude.toStringAsFixed(4) ?? 'N/A';
    final lng = _currentPosition?.longitude.toStringAsFixed(4) ?? 'N/A';

    final shareText =
        '''
🕋 Qibla Direction - Only Qibla App

📍 My Location: $lat°, $lng°
📏 Distance to Kaaba: ${distance.toStringAsFixed(0)} km
🧭 Direction: Towards Makkah, Saudi Arabia

🕋 Kaaba Location:
Latitude: 21.4225° N
Longitude: 39.8262° E

Download Only Qibla app to find accurate Qibla direction for your prayers!

#Qibla #Islam #Prayer #Makkah
''';

    try {
      await Share.share(shareText, subject: 'Qibla Direction - Only Qibla');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Find nearby mosques using Google Maps
  void _findNearbyMosques() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Please wait for location to be detected'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;

    // Google Maps URL for nearby mosques
    final url = Uri.parse(
      'https://www.google.com/maps/search/mosque/@$lat,$lng,14z',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web URL
        final webUrl = Uri.parse(
          'https://www.google.com/maps/search/mosque/@$lat,$lng,14z',
        );
        await launchUrl(webUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A3A1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('🕋 ', style: TextStyle(fontSize: 24)),
            Text('About Qibla', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'The Qibla is the direction that Muslims face when performing their prayers (Salah). '
                'It points towards the Kaaba in the Sacred Mosque (Masjid al-Haram) in Makkah, Saudi Arabia.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 16),
              _buildInfoSection('📍 Kaaba Location:', [
                'Latitude: 21.4225° N',
                'Longitude: 39.8262° E',
              ]),
              const SizedBox(height: 12),
              _buildInfoSection('🧭 For Best Accuracy:', [
                '• Hold your device flat',
                '• Keep away from magnetic objects',
                '• Calibrate by moving in figure-8 pattern',
                '• Ensure GPS is enabled',
              ]),
              const SizedBox(height: 12),
              _buildInfoSection('✨ Features:', [
                '• Works offline (compass mode)',
                '• Real-time Qibla direction',
                '• Map view with Qibla line',
                '• Find nearby mosques',
                '• Share with friends',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4CAF50),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              item,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
