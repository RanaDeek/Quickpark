import 'package:drawer/Views/home_page.dart';
import 'package:drawer/main.dart';
import 'package:flutter/material.dart';
import 'DestinationPage.dart';
import 'TimerPage.dart';
import 'app_drawer.dart';
import 'helpCenter_page.dart';

class FindparkingPage extends StatelessWidget {


  const FindparkingPage({super.key}
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4F8FB), Color(0xFFCCD4DC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            "Find Parking Slot",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF101D33),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MyHomePage(initialIndex: 4)), // or appropriate index
            );

          },
          backgroundColor: Color(0xFF2C3E50),
          child: const Icon(Icons.help, color: Colors.white),
        ),
        body: DestinationPage(),
      ),
    );
  }
}
