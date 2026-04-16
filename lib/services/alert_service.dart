import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AlertService {
  static final _db = FirebaseFirestore.instance;

  /// 📏 Distance calculation (Haversine formula)
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);

  /// 🚨 Send alerts
  static Future<void> sendAlerts({
    required double eventLat,
    required double eventLon,
    required String threatLevel,
  }) async {
    final usersSnapshot = await _db.collection('users').get();

    double minDistance = double.infinity;
    String? nearestGuardId;

    List<Map<String, dynamic>> guards = [];

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();

      if (data['isOnline'] == true && data['currentLocation'] != null) {
        final lat = data['currentLocation']['latitude'];
        final lon = data['currentLocation']['longitude'];

        final distance = calculateDistance(eventLat, eventLon, lat, lon);

        guards.add({
          'id': doc.id,
          'distance': distance,
        });

        if (distance < minDistance) {
          minDistance = distance;
          nearestGuardId = doc.id;
        }
      }
    }

    /// 🔔 Send alerts
    for (var guard in guards) {
      final isNearest = guard['id'] == nearestGuardId;

      await _db.collection('alerts').add({
        'targetGuardId': guard['id'],
        'type': isNearest ? 'priority' : 'normal',
        'status': 'pending',
        'threatLevel': threatLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }
}