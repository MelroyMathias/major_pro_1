import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserList extends StatelessWidget {
  const UserList({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 700;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['role'] == 'security';
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final doc = users[index];
            final data = doc.data() as Map<String, dynamic>;

            final name = data['name'] ?? 'No Name';
            final email = data['email'] ?? 'No Email';
            final floor = data['floor'] ?? '-';
            final camera = data['cameraLocation'] ?? '-';
            final isOnline = data['isOnline'] ?? false;

            final location = data['currentLocation'] ?? {};
            final lat = location['latitude'] ?? '-';
            final lng = location['longitude'] ?? '-';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 6,
                    color: Colors.black12,
                  )
                ],
              ),

              child: isDesktop
                  ? _buildDesktopLayout(name, email, floor, camera, lat, lng, isOnline)
                  : _buildMobileLayout(name, email, floor, camera, lat, lng, isOnline),
            );
          },
        );
      },
    );
  }

  /// 🔹 Desktop Layout
  Widget _buildDesktopLayout(
      String name,
      String email,
      String floor,
      String camera,
      dynamic lat,
      dynamic lng,
      bool isOnline) {
    return Row(
      children: [
        _avatar(),

        const SizedBox(width: 12),

        /// Name + Email
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),

        /// Floor
        Expanded(child: _infoItem("Floor", floor)),

        /// Camera
        Expanded(child: _infoItem("Camera", camera)),

        /// Location
        Expanded(child: _infoItem("Location", "$lat, $lng")),

        /// Status
        _statusDot(isOnline),
      ],
    );
  }

  /// 🔹 Mobile Layout
  Widget _buildMobileLayout(
      String name,
      String email,
      String floor,
      String camera,
      dynamic lat,
      dynamic lng,
      bool isOnline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _avatar(),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(email,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

            _statusDot(isOnline),
          ],
        ),

        const SizedBox(height: 8),

        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _chip("Floor: $floor"),
            _chip("Camera: $camera"),
            _chip("Lat: $lat"),
            _chip("Lng: $lng"),
          ],
        ),
      ],
    );
  }

  /// 🔹 Avatar
  Widget _avatar() {
    return const CircleAvatar(
      radius: 18,
      backgroundColor: Colors.blue,
      child: Icon(Icons.person, color: Colors.white, size: 18),
    );
  }

  /// 🔹 Info Item (Desktop)
  Widget _infoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  /// 🔹 Status Dot
  Widget _statusDot(bool isOnline) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isOnline ? "Online" : "Offline",
          style: TextStyle(
            fontSize: 12,
            color: isOnline ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  /// 🔹 Mobile Chips
  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}