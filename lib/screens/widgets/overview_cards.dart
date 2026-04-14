import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OverviewCards extends StatelessWidget {
  const OverviewCards({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        var users = snapshot.data!.docs;

        int totalUsers = 0;
        int online = 0;
        int offline = 0;

        for (var user in users) {
          if (user['role'] == 'security') {
            totalUsers++;

            if (user['isOnline'] == true) {
              online++;
            } else {
              offline++;
            }
          }
        }

        return Wrap(
          spacing: 15,
          runSpacing: 15,
          children: [
            StatCard("Users", totalUsers.toString(), Colors.blue, Icons.people),
            StatCard("Online", online.toString(), Colors.green, Icons.wifi),
            StatCard("Offline", offline.toString(), Colors.red, Icons.wifi_off),
          ],
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const StatCard(this.title, this.value, this.color, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
                fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}