import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ ADD THIS
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
  Position? currentPosition;
  bool isLoading = true;
  String statusText = "Initializing...";

  static const platform = MethodChannel('kiosk_mode'); // ✅ ADD THIS

  @override
  void initState() {
    super.initState();
    enableKioskMode(); // 🔥 START KIOSK
    setOnline();
    startLocationUpdates();
  }

  /// 🔒 Enable kiosk mode
  Future<void> enableKioskMode() async {
    try {
      await platform.invokeMethod('startKiosk');
    } catch (e) {
      print("Error enabling kiosk: $e");
    }
  }

  /// 🔓 Disable kiosk mode
  Future<void> disableKioskMode() async {
    try {
      await platform.invokeMethod('stopKiosk');
    } catch (e) {
      print("Error disabling kiosk: $e");
    }
  }

  /// ✅ Set user online
  Future<void> setOnline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': true,
      });
    }
  }

  /// ✅ Set user offline
  Future<void> setOffline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': false,
      });
    }
  }

  /// 📍 Start live location updates
  Future<void> startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        isLoading = false;
        statusText = "Enable GPS to continue";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        isLoading = false;
        statusText = "Permission permanently denied";
      });
      return;
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    positionStream!.listen((Position position) async {
      final user = FirebaseAuth.instance.currentUser;

      setState(() {
        currentPosition = position;
        isLoading = false;
        statusText = "Tracking Active";
      });

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'currentLocation': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'lastUpdated': FieldValue.serverTimestamp(),
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
    await disableKioskMode(); // 🔥 EXIT KIOSK
    await setOffline();
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  /// 🎨 UI
  @override
  Widget build(BuildContext context) {
    return WillPopScope( // 🔥 BLOCK BACK BUTTON
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Guard Dashboard"),
          centerTitle: true,
          backgroundColor: Colors.blue,
          automaticallyImplyLeading: false, // 🔥 REMOVE BACK ARROW
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: logout,
            )
          ],
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(20),
            child: isLoading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security, size: 70, color: Colors.blue),
                      const SizedBox(height: 15),

                      const Text(
                        "Welcome Guard 🛡️",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 20),

                      /// 📍 LOCATION CARD
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                "Live Location",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),

                              Text(
                                currentPosition != null
                                    ? "Latitude: ${currentPosition!.latitude}"
                                    : "Latitude: --",
                              ),
                              const SizedBox(height: 5),
                              Text(
                                currentPosition != null
                                    ? "Longitude: ${currentPosition!.longitude}"
                                    : "Longitude: --",
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// 🟢 STATUS
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusText == "Tracking Active"
                              ? Colors.green
                              : Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}