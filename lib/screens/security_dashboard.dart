import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';

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

  static const platform = MethodChannel('kiosk_mode');

  @override
  void initState() {
    super.initState();

    print("🔥 GUARD UID: ${FirebaseAuth.instance.currentUser?.uid}");

    enableKioskMode();
    setOnline();
    startLocationUpdates();
    listenForAlerts();
  }

  /// 🚨 ALERT LISTENER
  void listenForAlerts() {
    FirebaseFirestore.instance
        .collection('alerts')
        .snapshots()
        .listen((snapshot) async {

      for (var doc in snapshot.docs) {
        final data = doc.data();

        print("🔥 ALERT: $data");

        if (data['status'] == 'pending') {

          print("🚨 VIBRATING NOW");

          try {
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(duration: 2000);
            }
          } catch (e) {
            print("Vibration error: $e");
          }

          await doc.reference.update({'status': 'received'});

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("🚨 Emergency Alert!")),
            );
          }
        }
      }
    });
  }

  Future<void> enableKioskMode() async {
    try {
      await platform.invokeMethod('startKiosk');
    } catch (e) {
      print("Error enabling kiosk: $e");
    }
  }

  Future<void> disableKioskMode() async {
    try {
      await platform.invokeMethod('stopKiosk');
    } catch (e) {
      print("Error disabling kiosk: $e");
    }
  }

  Future<void> setOnline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': true,
      });
    }
  }

  Future<void> setOffline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': false,
      });
    }
  }

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

  @override
  void dispose() {
    setOffline();
    super.dispose();
  }

  Future<void> logout() async {
    await disableKioskMode();
    await setOffline();
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Guard Dashboard"),
          centerTitle: true,
          backgroundColor: Colors.blue,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: logout,
            )
          ],
        ),
        body: Center(
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

                    Text(
                      currentPosition != null
                          ? "Lat: ${currentPosition!.latitude}, Lng: ${currentPosition!.longitude}"
                          : "Location not available",
                    ),

                    const SizedBox(height: 20),

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
    );
  }
}