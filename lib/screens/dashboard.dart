import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          final total = users.length;
          final online =
              users.where((u) => u['isOnline'] == true).length;
          final offline = total - online;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _card("Users", total, Colors.blue),
                _card("Online", online, Colors.green),
                _card("Offline", offline, Colors.red),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(String title, int value, Color color) {
    return Container(
      width: 120,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("$value",
                style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}