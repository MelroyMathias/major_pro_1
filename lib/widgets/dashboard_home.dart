import 'package:flutter/material.dart';
import 'package:weapon_detection_system/screens/widgets/overview_cards.dart';
import 'detection_panel.dart';


class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 📊 OVERVIEW (guards count, online/offline)
         OverviewCards(),

        const SizedBox(height: 20),

        /// 🚨 DETECTIONS TITLE
        const Text(
          "Live Detection Alerts",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        /// 🚨 DETECTION PANEL
        const Expanded(
          child: DetectionPanel(),
        ),
      ],
    );
  }
}