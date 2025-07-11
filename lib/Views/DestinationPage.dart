import 'dart:convert';

import 'package:flutter/material.dart';

import 'StreetViewPage.dart';

class DestinationPage extends StatefulWidget {
  DestinationPage({super.key});

  @override
  State<DestinationPage> createState() => _DestinationPageState();
}

class _DestinationPageState extends State<DestinationPage> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  final TextEditingController _destinationController = TextEditingController();

  NavigatorState? _navigator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.of(context);
  }

  void _handleReservation(BuildContext context, String destination) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UParkingStreetPage(destination: destination)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تحديد الوجهة'),
          backgroundColor: const Color(0xFF101D33),
          centerTitle: true,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                const Icon(
                  Icons.local_parking,
                  size: 70,
                  color: Color(0xFF101D33),
                ),
                const SizedBox(height: 20),
                const Text(
                  "اكتشف المواقف المتاحة بسهولة مع Quick Park.",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF101D33),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  "نساعدك في العثور على موقف مخصص لسيارتك بسهولة ويسر.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF101D33),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: "أدخل وجهتك",
                    prefixIcon: const Icon(Icons.location_on, color: Color(0xFF101D33)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    final destination = _destinationController.text.trim();
                    if (destination.isEmpty) {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(content: Text("يرجى إدخال الوجهة")),
                      );
                      return;
                    }
                    _handleReservation(context, destination);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 135),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                  ),
                  child: const Text(
                    "اختر موقفًا متاحًا",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  "هل تحتاج إلى مساعدة؟ تفضل بزيارة مركز المساعدة للحصول على الدعم.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF101D33),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
