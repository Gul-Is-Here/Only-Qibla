import 'dart:io';
import 'dart:async';

class ConnectivityService {
  /// Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } catch (e) {
      print('Connectivity check error: $e');
      return false;
    }
  }

  /// Quick connectivity check (less reliable but faster)
  static Future<bool> quickConnectivityCheck() async {
    try {
      final result = await InternetAddress.lookup(
        '8.8.8.8',
      ).timeout(const Duration(seconds: 2));
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
