import 'package:flutter/material.dart';
import 'Views/chatbot_page.dart';
import 'Views/home_page.dart';
import 'Views/findParking_page.dart';
import 'Views/PaymentPage.dart';
import 'Views/parkingHistory_page.dart';
import 'Views/profile_page.dart';
import 'Views/helpCenter_page.dart';
import 'Views/AboutApp.dart';
import 'Views/app_drawer.dart';
import 'Views/auth.dart';
import 'Views/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Park',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final int initialIndex; // 🔹 Added support for custom starting tab
  const MyHomePage({super.key, this.initialIndex = 0});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late int _selectedIndex;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomePage(),
     PaymentPage(),
    chatbot_page(), // ✅ Fix here
    const ProfilePage(),
     HelpCenterApp(),
    const AboutAppPage(),
    const Center(child: Text('ℹ️ About App')),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // 🔹 Start with given index
  }

  void _onItemTapped(int index) async {
    if (index == 6) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Quick Park",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF101D33),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: AppDrawer(
        onItemSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
      ),
      body: _widgetOptions[_selectedIndex],
    );
  }
}
