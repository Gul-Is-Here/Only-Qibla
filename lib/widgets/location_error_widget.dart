import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const LocationErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with animation
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.location_off,
                size: 50,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),

            // Error title
            const Text(
              'Location Required',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Error description
            Text(
              _getErrorMessage(error),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            Column(
              children: [
                // Retry button
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),

                // Open settings button
                TextButton.icon(
                  onPressed: () => _openSettings(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.settings, size: 20),
                  label: const Text('Open Settings'),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Help section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF4CAF50).withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Why we need location?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'To calculate the accurate Qibla direction from your current position to the Kaaba in Makkah, we need access to your location.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(String error) {
    if (error.toLowerCase().contains('permission')) {
      return 'Location permission is required to find Qibla direction. Please grant location access to continue.';
    } else if (error.toLowerCase().contains('service')) {
      return 'Location services are disabled. Please enable GPS/Location in your device settings.';
    } else if (error.toLowerCase().contains('sensor')) {
      return 'Your device may not have the required compass sensor. Please try on another device.';
    }
    return 'Unable to get location. Please check your settings and try again.\n\nError: $error';
  }

  Future<void> _openSettings(BuildContext context) async {
    final shouldOpenAppSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A3A1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Open Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Would you like to open app settings or device location settings?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Device Settings',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'App Settings',
              style: TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );

    if (shouldOpenAppSettings == true) {
      await openAppSettings();
    } else if (shouldOpenAppSettings == false) {
      await Geolocator.openLocationSettings();
    }
  }
}
