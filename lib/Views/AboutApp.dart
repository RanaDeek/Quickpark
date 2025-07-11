import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                spreadRadius: 2,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_parking, size: 48, color: Color(0xFF101D33)),
              const SizedBox(height: 16),
              Text(
                'QuickPark',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF101D33),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your smart parking companion. Find, reserve, and pay for spots in real time.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                  "QuickPark is a smart solution to a real urban problem—finding available parking. "
                      "Designed as part of our graduation project at Birzeit University, this app helps users "
                      "find and reserve parking spots in real time using GPS and IoT integration.\n\n"
                      "With features like destination-based spot search, 15-minute "
                      "reservation windows, mobile notifications, and in-app payments, QuickPark reduces traffic, "
                      "fuel consumption, and time wasted.\n\n",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Chip(
                label: Text('Made for Palestine'),
                avatar: Icon(Icons.location_on, color: Colors.redAccent),
                backgroundColor: Colors.red[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

