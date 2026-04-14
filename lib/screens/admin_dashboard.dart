import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'widgets/overview_cards.dart';
import 'widgets/add_user_form.dart';
import 'widgets/user_list.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    const OverviewCards(),
    const AddUserForm(),
    const UserList(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text("Admin Panel",style: TextStyle(color: Colors.white),),
              backgroundColor: Colors.black87,
            ),

      drawer: isDesktop ? null : _buildDrawer(),

      body: Row(
        children: [
          if (isDesktop) _buildSidebar(), // 💻 Sidebar for PC

          /// Main Content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Welcome Text
                  FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text("Loading...");
                      }

                      return Text(
                        "Welcome ${snapshot.data!['email']}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  /// Page Content
                  Expanded(
                    child: pages[selectedIndex],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Sidebar (Desktop)
  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: Colors.black87,
      child: Column(
        children: [
          const SizedBox(height: 40),

          const Text(
            "Admin Panel",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),

          const SizedBox(height: 20),

          _menuItem("Dashboard", 0, Icons.dashboard),
          _menuItem("Add User", 1, Icons.person_add),
          _menuItem("Users", 2, Icons.people),

          const Spacer(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout",
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }

  /// 🔹 Drawer (Mobile)
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.black87,
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Text(
              "Admin Panel",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),

            const SizedBox(height: 20),

            _menuItem("Dashboard", 0, Icons.dashboard, isDrawer: true),
            _menuItem("Add User", 1, Icons.person_add, isDrawer: true),
            _menuItem("Users", 2, Icons.people, isDrawer: true),

            const Spacer(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout",
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Menu Item
  Widget _menuItem(String title, int index, IconData icon,
      {bool isDrawer = false}) {
    final isSelected = selectedIndex == index;

    return ListTile(
      leading: Icon(icon,
          color: isSelected ? Colors.blue : Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.white,
          fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white,
      onTap: () {
        setState(() => selectedIndex = index);

        if (isDrawer) {
          Navigator.pop(context); // close drawer on mobile
        }
      },
    );
  }
}