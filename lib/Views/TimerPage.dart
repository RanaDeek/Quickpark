import 'dart:async';
import 'dart:convert';
import 'package:drawer/Views/home_page.dart';
import 'package:drawer/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TimerPage extends StatefulWidget {
  final int minutes;
  final int slotNumber;

  TimerPage({required this.minutes, required this.slotNumber});

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late int _totalSeconds;

  String get timeString {
    Duration duration = _controller.duration! * _controller.value;
    return '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(duration.inSeconds.remainder(60)).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.minutes * 60;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    )..reverse(from: 1.0);

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.dismissed) {
        await _cancelReservation();

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("انتهت المدة"),
            content: Text("لقد انتهت مدة الـ ${widget.minutes} دقيقة. تم إلغاء الحجز."),
            actions: [
              TextButton(
                onPressed: () =>Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MyHomePage(initialIndex: 0)))
                ,
                child: Text("موافق"),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cancelReservation() async {
    final url = Uri.parse('https://quickpark.onrender.com/api/slots/${widget.slotNumber}/handle_reservation');

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        // Reservation cancelled successfully
      } else {
        final error = jsonDecode(response.body)['error'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ: $error")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل الاتصال بالخادم")),
      );
    }
  }

  Future<void> _occupySlot() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('username'); // retrieve from prefs

    if (userName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("اسم المستخدم غير موجود. الرجاء تسجيل الدخول.")),
      );
      return;
    }

    final url = Uri.parse('https://quickpark.onrender.com/api/slots/${widget.slotNumber}/occupy');

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'userName': userName}),
      );

      if (response.statusCode == 200) {
        // Success
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 24,
            title: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text("نجاح", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.green[700])),
              ],
            ),
            content: Text("تم تأكيد الحجز واحتلال الموقف بنجاح!", style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MyHomePage(initialIndex: 0)));
                },
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFFFF6F00),
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text("حسنا", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        );
      } else {
        final error = jsonDecode(response.body)['error'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ: $error")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل الاتصال بالخادم")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quick Park", style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF101D33), Color(0xFF2C3E50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Color(0xFF101D33),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: _controller.value,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF101D33)),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeString,
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text("تبقى لديك وقت للوصول", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: 40),
          GestureDetector(
            onTap: _occupySlot,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 40),
              decoration: BoxDecoration(
                color: Color(0xFF101D33),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "لقد وصلت - افتح البوابة",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
