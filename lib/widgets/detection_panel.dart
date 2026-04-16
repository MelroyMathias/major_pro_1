import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/alert_service.dart';

class DetectionPanel extends StatefulWidget {
  const DetectionPanel({super.key});

  @override
  State<DetectionPanel> createState() => _DetectionPanelState();
}

class _DetectionPanelState extends State<DetectionPanel> {
  String? lastProcessedId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('detections')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final detections = snapshot.data!.docs;

        if (detections.isEmpty) {
          return const Center(child: Text("No detections yet"));
        }

        /// 🔥 AUTO ALERT LOGIC
        final latestDoc = detections.first;
        final latestData = latestDoc.data();

        if (latestDoc.id != lastProcessedId &&
            latestData['alertSent'] != true) {
          
          lastProcessedId = latestDoc.id;

          /// 🚨 Send alerts to guards
          AlertService.sendAlerts(
            eventLat: 12.9716, // 🔥 TEMP (replace later with real camera location)
            eventLon: 77.5946,
            threatLevel: latestData['threatLevel'] ?? "LOW",
          );

          /// ✅ Mark as processed
          FirebaseFirestore.instance
              .collection('detections')
              .doc(latestDoc.id)
              .update({'alertSent': true});
        }

        return ListView.builder(
          itemCount: detections.length,
          itemBuilder: (context, index) {
            final data = detections[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              elevation: 4,
              child: ListTile(
                leading: data['imageUrl'] != null
                    ? Image.network(
                        data['imageUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image),

                title: Text(
                  "${data['weapon']} detected",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Threat: ${data['threatLevel']}"),
                    Text("Area: ${data['area']}"),
                  ],
                ),

                trailing: _buildThreatBadge(data['threatLevel']),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThreatBadge(String level) {
    Color color;

    switch (level) {
      case "HIGH":
        color = Colors.red;
        break;
      case "MEDIUM":
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        level,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}