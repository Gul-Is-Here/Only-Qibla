import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

class QiblaMapView extends StatefulWidget {
  final QiblahDirection qiblahDirection;
  final Position? currentPosition;

  const QiblaMapView({
    super.key,
    required this.qiblahDirection,
    this.currentPosition,
  });

  @override
  State<QiblaMapView> createState() => _QiblaMapViewState();
}

class _QiblaMapViewState extends State<QiblaMapView> {
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.satellite;
  BitmapDescriptor? _kaabaIcon;
  BitmapDescriptor? _userIcon;

  // Kaaba coordinates
  static const kaabaLat = 21.4225;
  static const kaabaLng = 39.8262;
  static const kaabaLocation = LatLng(kaabaLat, kaabaLng);

  LatLng get userLocation {
    if (widget.currentPosition != null) {
      return LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );
    }
    // Default to a location if GPS not available
    return const LatLng(24.7136, 46.6753); // Riyadh as fallback
  }

  @override
  void initState() {
    super.initState();
    _createCustomMarkers();
  }

  Future<void> _createCustomMarkers() async {
    // Create Kaaba marker icon
    _kaabaIcon = await _createKaabaMarker();
    // Create User marker icon
    _userIcon = await _createUserMarker();
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _createKaabaMarker() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const size = Size(80, 80);

    // White circle background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      bgPaint,
    );

    // Green border
    final borderPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 2,
      borderPaint,
    );

    // Dark inner circle for Kaaba
    final innerPaint = Paint()..color = const Color(0xFF2D2D2D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 50,
          height: 50,
        ),
        const Radius.circular(8),
      ),
      innerPaint,
    );

    // Draw Kaaba structure (simplified)
    final kaabaPaint = Paint()..color = const Color(0xFFD4AF37); // Gold
    // Top band
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - 20, size.height / 2 - 15, 40, 8),
      kaabaPaint,
    );
    // Bottom decorations
    for (int i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width / 2 - 22 + (i * 10),
          size.height / 2 + 5,
          6,
          12,
        ),
        kaabaPaint,
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(uint8List);
  }

  Future<BitmapDescriptor> _createUserMarker() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const size = Size(60, 60);

    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 0.3);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      glowPaint,
    );

    // White background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 8,
      bgPaint,
    );

    // Green inner circle
    final innerPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 15,
      innerPaint,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(uint8List);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // Fit both user and Kaaba on screen with proper bounds
  void _fitBothLocations() {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(userLocation.latitude, kaabaLat),
        math.min(userLocation.longitude, kaabaLng),
      ),
      northeast: LatLng(
        math.max(userLocation.latitude, kaabaLat),
        math.max(userLocation.longitude, kaabaLng),
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80), // 80 pixels padding
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-screen Google Map - World view showing both locations
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              (userLocation.latitude + kaabaLat) / 2,
              (userLocation.longitude + kaabaLng) / 2,
            ),
            zoom: 2, // Start zoomed out, then fit bounds
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            // Fit both locations after map is ready
            Future.delayed(const Duration(milliseconds: 500), () {
              _fitBothLocations();
            });
          },
          mapType: _currentMapType,
          markers: _buildMarkers(),
          polylines: _buildDashedQiblaLine(),
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: false,
          minMaxZoomPreference: const MinMaxZoomPreference(1, 20),
        ),

        // Right side buttons (Layers, My Location, Mosques)
        Positioned(top: 60, right: 16, child: _buildRightButtons()),

        // "Qibla direction is found!" success message
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(child: _buildSuccessMessage()),
        ),

        // Mini world map inset in bottom left
        Positioned(bottom: 100, left: 16, child: _buildMiniWorldMap()),
      ],
    );
  }

  // Right side control buttons
  Widget _buildRightButtons() {
    return Column(
      children: [
        // Layer toggle button (Satellite/Normal)
        _buildControlButton(
          icon: _currentMapType == MapType.satellite
              ? Icons.map_outlined
              : Icons.satellite_alt,
          onTap: () {
            setState(() {
              _currentMapType = _currentMapType == MapType.satellite
                  ? MapType.normal
                  : MapType.satellite;
            });
          },
        ),
        const SizedBox(height: 12),
        // Fit both locations on screen
        _buildControlButton(icon: Icons.zoom_out_map, onTap: _fitBothLocations),
        const SizedBox(height: 12),
        // My location button
        _buildControlButton(
          icon: Icons.my_location,
          onTap: () {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(userLocation, 12),
            );
          },
        ),
        const SizedBox(height: 12),
        // Mosque button
        _buildControlButton(
          icon: Icons.mosque,
          onTap: () {
            // Handled by parent screen
          },
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.black87, size: 24),
        ),
      ),
    );
  }

  // Success message banner
  Widget _buildSuccessMessage() {
    final distance = _calculateDistance();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${distance.toStringAsFixed(0)} km to Qibla',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF4CAF50), size: 20),
          ),
        ],
      ),
    );
  }

  // Mini world map showing global view
  Widget _buildMiniWorldMap() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          size: const Size(90, 90),
          painter: MiniWorldMapPainter(
            userLocation: userLocation,
            kaabaLocation: kaabaLocation,
          ),
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    return {
      // User location marker
      Marker(
        markerId: const MarkerId('user'),
        position: userLocation,
        icon:
            _userIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
      // Kaaba marker
      Marker(
        markerId: const MarkerId('kaaba'),
        position: kaabaLocation,
        icon:
            _kaabaIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(
          title: '🕋 Kaaba',
          snippet: 'Makkah, Saudi Arabia',
        ),
      ),
    };
  }

  // Generate dashed curved line (geodesic) from user to Kaaba
  Set<Polyline> _buildDashedQiblaLine() {
    final points = _generateGeodesicCurve(userLocation, kaabaLocation, 100);

    // Create dashed effect by making multiple short polylines
    Set<Polyline> polylines = {};

    // Main dashed line segments
    for (int i = 0; i < points.length - 1; i += 4) {
      final endIndex = (i + 2).clamp(0, points.length - 1);
      polylines.add(
        Polyline(
          polylineId: PolylineId('dash_$i'),
          points: points.sublist(i, endIndex + 1),
          color: const Color(0xFF4CAF50),
          width: 4,
          geodesic: true,
        ),
      );
    }

    return polylines;
  }

  /// Generate intermediate points along a great circle arc (geodesic curve)
  List<LatLng> _generateGeodesicCurve(LatLng start, LatLng end, int numPoints) {
    List<LatLng> points = [];

    final lat1 = start.latitude * math.pi / 180;
    final lng1 = start.longitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final lng2 = end.longitude * math.pi / 180;

    final dLng = lng2 - lng1;
    final cosLat1 = math.cos(lat1);
    final cosLat2 = math.cos(lat2);
    final sinLat1 = math.sin(lat1);
    final sinLat2 = math.sin(lat2);

    final centralAngle = math.acos(
      (sinLat1 * sinLat2 + cosLat1 * cosLat2 * math.cos(dLng)).clamp(-1.0, 1.0),
    );

    if (centralAngle == 0) return [start, end];

    for (int i = 0; i <= numPoints; i++) {
      final fraction = i / numPoints;

      final a =
          math.sin((1 - fraction) * centralAngle) / math.sin(centralAngle);
      final b = math.sin(fraction * centralAngle) / math.sin(centralAngle);

      final x = a * cosLat1 * math.cos(lng1) + b * cosLat2 * math.cos(lng2);
      final y = a * cosLat1 * math.sin(lng1) + b * cosLat2 * math.sin(lng2);
      final z = a * sinLat1 + b * sinLat2;

      final lat = math.atan2(z, math.sqrt(x * x + y * y));
      final lng = math.atan2(y, x);

      points.add(LatLng(lat * 180 / math.pi, lng * 180 / math.pi));
    }

    return points;
  }

  double _calculateDistance() {
    return Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          kaabaLat,
          kaabaLng,
        ) /
        1000;
  }
}

// Custom painter for mini world map
class MiniWorldMapPainter extends CustomPainter {
  final LatLng userLocation;
  final LatLng kaabaLocation;

  MiniWorldMapPainter({
    required this.userLocation,
    required this.kaabaLocation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw ocean background
    final oceanPaint = Paint()..color = const Color(0xFF1E4D6B);
    canvas.drawCircle(center, radius, oceanPaint);

    // Draw simplified continents
    final landPaint = Paint()..color = const Color(0xFF4A7C59);
    _drawSimplifiedContinents(canvas, size, landPaint);

    // Convert lat/lng to x/y on mini map
    Offset latLngToOffset(LatLng pos) {
      final x = center.dx + (pos.longitude / 180) * radius * 0.85;
      final y = center.dy - (pos.latitude / 90) * radius * 0.85;
      return Offset(x.clamp(5, size.width - 5), y.clamp(5, size.height - 5));
    }

    final userPos = latLngToOffset(userLocation);
    final kaabaPos = latLngToOffset(kaabaLocation);

    // Draw dashed curved line
    final linePaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(userPos.dx, userPos.dy);
    final midX = (userPos.dx + kaabaPos.dx) / 2;
    final midY = math.min(userPos.dy, kaabaPos.dy) - 10;
    path.quadraticBezierTo(midX, midY, kaabaPos.dx, kaabaPos.dy);

    // Draw dashed line
    final dashPath = _createDashedPath(path, 4, 3);
    canvas.drawPath(dashPath, linePaint);

    // Draw Kaaba marker
    final kaabaPaint = Paint()..color = const Color(0xFF2D2D2D);
    canvas.drawCircle(kaabaPos, 5, kaabaPaint);
    final kaabaBorderPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(kaabaPos, 5, kaabaBorderPaint);

    // Draw user marker
    final userPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawCircle(userPos, 4, userPaint);
    final userBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(userPos, 4, userBorderPaint);
  }

  Path _createDashedPath(Path source, double dashLength, double gapLength) {
    final Path dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        dashedPath.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += dashLength + gapLength;
      }
    }
    return dashedPath;
  }

  void _drawSimplifiedContinents(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Europe & Africa
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.1, center.dy),
        width: radius * 0.35,
        height: radius * 0.8,
      ),
      paint,
    );

    // Asia
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.45, center.dy - radius * 0.15),
        width: radius * 0.5,
        height: radius * 0.45,
      ),
      paint,
    );

    // Americas
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.55, center.dy),
        width: radius * 0.25,
        height: radius * 0.75,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
