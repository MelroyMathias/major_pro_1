import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  Stream<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    setOnline();
    startLocationUpdates();
  }

  /// ✅ Set user online
  Future<void> setOnline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isOnline': true,
      });
    }
  }

  /// ✅ Set user offline
  Future<void> setOffline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isOnline': false,
      });
    }
  }

  /// 📍 Start live location updates
  Future<void> startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return;

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    positionStream!.listen((Position position) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'currentLocation': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
        });
      }
    });
  }

  /// 🔴 When screen closes → set offline
  @override
  void dispose() {
    setOffline();
    super.dispose();
  }

  /// 🚪 Logout
  Future<void> logout() async {
    await setOffline();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Security Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          )
        ],
      ),

      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 60, color: Colors.blue),
              SizedBox(height: 10),
              Text(
                "Welcome Security Guard 🛡️",
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 10),
              Text(
                "Location tracking is active",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}